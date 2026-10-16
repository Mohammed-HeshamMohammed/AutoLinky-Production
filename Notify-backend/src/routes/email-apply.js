import { HttpError } from '../../../backend-v2/shared/http/errors.js';
import { queryOf,time } from '../../../backend-v2/shared/contracts/query.js';
import { transaction } from '../../../backend-v2/shared/db/client.js';
import { billing,normalizeEmail } from '../billing.js';
import { autoState,activitySince } from '../activity.js';
import { validAddress,oneLine,cleanSignature,suggestSignature } from '../email/composition.js';
import { encryptSecret,secretAvailable } from '../email/secret.js';
import { MailError } from '../email/gmail.js';
export function registerEmailApply(app,{db,config,limiter,transport}){
  app.get('/v1/auto-apply',request=>autoState(db,request.user.id,config));
  app.put('/v1/auto-apply',{schema:{body:{type:'object',additionalProperties:false,properties:{enabled:{type:['boolean','null']},min_match:{type:['integer','null'],minimum:40,maximum:95},daily_limit:{type:['integer','null'],minimum:1,maximum:config.dailyEmails},gap_minutes:{type:['integer','null'],minimum:3,maximum:120}}}}},async request=>{
    const values=Object.fromEntries(Object.entries(request.body).filter(([,v])=>v!==null));
    await transaction(db,async c=>{
      await c.query('SELECT pg_advisory_xact_lock(hashtextextended($1,0))',[`mail:${request.user.id}`]);
      if(values.enabled){
        const account=(await c.query('SELECT status FROM public.mail_accounts WHERE user_id=$1',[request.user.id])).rows[0];if(!account)throw new HttpError(409,'email_not_connected');if(account.status==='invalid')throw new HttpError(409,'email_invalid');
        if(!(await c.query('SELECT FROM public.user_cv_files WHERE user_id=$1',[request.user.id])).rowCount)throw new HttpError(409,'cv_needed');if(!(await billing(c,request.user.id,config)).canSend)throw new HttpError(402,'free_limit');
      }
      if(Object.keys(values).length){const keys=Object.keys(values),params=Object.values(values);await c.query(`INSERT INTO public.auto_apply(user_id,${keys.join(',')}) VALUES($1,${params.map((_,i)=>'$'+(i+2)).join(',')}) ON CONFLICT(user_id) DO UPDATE SET ${keys.map(k=>`${k}=EXCLUDED.${k}`).join(',')},updated_at=now(),enabled_at=CASE WHEN NOT auto_apply.enabled AND EXCLUDED.enabled THEN now() ELSE auto_apply.enabled_at END,next_send_at=CASE WHEN NOT auto_apply.enabled AND EXCLUDED.enabled THEN now() ELSE auto_apply.next_send_at END`,[request.user.id,...params]);}
    });return autoState(db,request.user.id,config);
  });
  app.get('/v1/auto-apply/activity',request=>activitySince(db,request.user.id,time(queryOf(request).get('after'),'after'),config));
  app.put('/v1/mail-account',{schema:{body:{type:'object',additionalProperties:false,required:['address','sender_name'],properties:{address:{type:'string',maxLength:254},sender_name:{type:'string',maxLength:120},app_password:{type:['string','null'],maxLength:64},signature:{type:['string','null'],maxLength:600}}}}},async request=>{
    limiter.enforce(`mail_account:${request.user.id}`,8,3600);
    const b=request.body,address=validAddress(b.address),name=oneLine(b.sender_name,80);
    if(!address)throw new HttpError(422,'invalid_address');if(normalizeEmail(address)!==normalizeEmail(request.user.email))throw new HttpError(422,'gmail_not_account');if(!name)throw new HttpError(422,'invalid_name');
    const signature=b.signature===null||b.signature===undefined?undefined:cleanSignature(b.signature)||null;
    if(!b.app_password?.trim()){
      const result=await db.query(`UPDATE public.mail_accounts SET sender_name=$3${signature===undefined?'':',signature=$4'},updated_at=now() WHERE user_id=$1 AND address=$2`,[request.user.id,address,name,...(signature===undefined?[]:[signature])]);
      if(!result.rowCount)throw new HttpError(422,'app_password_needed');
    }else{
      const password=b.app_password.replace(/[\s-]/g,'').toLowerCase();if(!/^[a-z]{16}$/.test(password))throw new HttpError(422,'invalid_app_password');if(!secretAvailable(config.mailSecretKey))throw new HttpError(503,'mail_unavailable');
      let status='ok',checked=new Date();
      try{await transport.verify(address,password);}catch(error){if(!(error instanceof MailError))throw error;const refused={auth:'wrong_app_password',not_app_password:'not_app_password',blocked:'gmail_blocked'}[error.kind];if(refused)throw new HttpError(422,refused);status='unverified';checked=null;}
      await db.query(`INSERT INTO public.mail_accounts(user_id,address,sender_name,secret,status,checked_at,signature) VALUES($1,$2,$3,$4,$5,$6,$7)
        ON CONFLICT(user_id) DO UPDATE SET address=EXCLUDED.address,sender_name=EXCLUDED.sender_name,secret=EXCLUDED.secret,status=EXCLUDED.status,error=NULL,checked_at=EXCLUDED.checked_at${signature===undefined?'':',signature=EXCLUDED.signature'},updated_at=now()`,[request.user.id,address,name,encryptSecret(password,config.mailSecretKey),status,checked,signature??null]);
    }
    return autoState(db,request.user.id,config);
  });
  app.get('/v1/mail-account/signature',async request=>{const row=(await db.query('SELECT text,links FROM public.user_cvs WHERE user_id=$1',[request.user.id])).rows[0];return {signature:suggestSignature(row?.text,request.user.email,row?.links||[])};});
  app.delete('/v1/mail-account',async(request,reply)=>{await transaction(db,async c=>{await c.query('SELECT pg_advisory_xact_lock(hashtextextended($1,0))',[`mail:${request.user.id}`]);await c.query('DELETE FROM public.mail_accounts WHERE user_id=$1',[request.user.id]);await c.query('UPDATE public.auto_apply SET enabled=false,updated_at=now() WHERE user_id=$1',[request.user.id]);});return reply.code(204).send();});
}
