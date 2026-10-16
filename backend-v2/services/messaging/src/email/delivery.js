import { createHash } from 'node:crypto';
import { transaction } from '../../../../shared/db/client.js';
import { HttpError } from '../../../../shared/http/errors.js';
import { durableLimit } from '../../../../shared/http/rate-limit.js';
import { billing } from '../billing.js';
import { summary } from '../../../../shared/repositories/jobs.js';
import { validAddress,compose,suggestSignature } from './composition.js';
import { decryptSecret } from './secret.js';
import { MailError } from './gmail.js';
import { letterService } from '../ai/cover-letters.js';
const refusal={email_not_connected:409,email_invalid:409,cv_needed:409,no_email_contact:422,free_limit:402,daily_limit:429,gmail_limit:429,gmail_busy:503,mail_unavailable:503};
const refuse=code=>{throw new HttpError(refusal[code]||409,code);};
export async function jobRecipient(db,job){if(job.source!=='post')return null;const {rows}=await db.query("SELECT value FROM public.post_contacts WHERE post_id::text=$1 AND type='email' ORDER BY id",[job.source_ref]);return rows.map(r=>validAddress(r.value)).find(Boolean)||null;}
export function deliveryService({db,config,transport,ai}){
  const letterBody=letterService({db,config,ai});
  async function preview(user,job){
    const to=await jobRecipient(db,job);if(!to)refuse('no_email_contact');
    const account=(await db.query('SELECT address,sender_name,signature FROM public.mail_accounts WHERE user_id=$1',[user.id])).rows[0]||{address:user.email};
    const cv=(await db.query('SELECT file_name,file_type,text,links,sha256 FROM public.user_cvs WHERE user_id=$1',[user.id])).rows[0]||{};
    const profile=(await db.query('SELECT headline,years_experience,skills FROM public.user_profiles WHERE user_id=$1',[user.id])).rows[0]||{};
    const shared=(job.skills||[]).filter(s=>profile.skills?.includes(s)).slice(0,4);
    const skills=shared.length?(await db.query('SELECT slug,name FROM public.skills WHERE slug=ANY($1::text[])',[shared])).rows:[];
    const names=new Map(skills.map(s=>[s.slug,s.name]));
    const body=await letterBody(user.id,job,cv);
    return compose({job,to,account,cv,profile,body,signature:account.signature??suggestSignature(cv.text,account.address||user.email,cv.links||[]),skillNames:shared.map(s=>names.get(s)||s)});
  }
  async function send(user,job,edited=null,{auto=false}={}){
    await durableLimit(db,`email:${user.id}`,10,600);
    const letter=await preview(user,job);if(edited)letter.body=compose({job,to:letter.to,account:{address:letter.from_address,sender_name:letter.from_name},edited}).body;
    const reservation=await transaction(db,async c=>{
      await c.query('SELECT pg_advisory_xact_lock(hashtextextended($1,0))',[`mail:${user.id}`]);
      const active=(await c.query('SELECT status FROM public.app_users WHERE id=$1 FOR UPDATE',[user.id])).rows[0];if(active?.status!=='active')throw new HttpError(403,'Account blocked');
      const existing=(await c.query('SELECT * FROM public.applications WHERE user_id=$1 AND opportunity_id=$2 FOR UPDATE',[user.id,job.id])).rows[0];
      if(auto&&existing)return {existing};
      if(existing?.method==='email'&&['queued','sending','sent'].includes(existing.status))return {existing};
      const account=(await c.query('SELECT * FROM public.mail_accounts WHERE user_id=$1',[user.id])).rows[0];if(!account)refuse('email_not_connected');if(account.status==='invalid')refuse('email_invalid');
      const cv=(await c.query('SELECT c.file_name,c.file_type,c.sha256,f.bytes FROM public.user_cvs c JOIN public.user_cv_files f USING(user_id) WHERE c.user_id=$1',[user.id])).rows[0];if(!cv)refuse('cv_needed');
      if(createHash('sha256').update(cv.bytes).digest('hex')!==cv.sha256)refuse('mail_unavailable');
      const plan=await billing(c,user.id,config);if(!plan.canSend)refuse('free_limit');if(plan.daily!==null&&plan.dailyUsed>=plan.daily)refuse('daily_limit');
      const settings=(await c.query('SELECT enabled,daily_limit,paused_until,pause_reason FROM public.auto_apply WHERE user_id=$1',[user.id])).rows[0];
      if(auto&&!settings?.enabled)throw new HttpError(409,'auto_apply_disabled');
      if(auto&&plan.dailyUsed>=Math.min(settings.daily_limit,plan.daily??settings.daily_limit))refuse('daily_limit');
      if(auto&&(await c.query("SELECT FROM public.applications WHERE user_id=$1 AND recipient=$2 AND created_at>now()-interval '30 days' LIMIT 1",[user.id,letter.to])).rowCount)throw new HttpError(409,'recipient_cooldown');
      if(settings?.paused_until&&new Date(settings.paused_until)>new Date())refuse(settings.pause_reason==='gmail_limit'?'gmail_limit':'gmail_busy');
      let password;try{password=decryptSecret(account.secret,config.mailSecretKey);}catch{refuse('mail_unavailable');}
      const row=(await c.query(`INSERT INTO public.applications(user_id,opportunity_id,method,status,job,recipient,letter,auto) VALUES($1,$2,'email','sending',$3,$4,$5,$6)
        ON CONFLICT(user_id,opportunity_id) DO UPDATE SET method='email',status='sending',job=EXCLUDED.job,recipient=EXCLUDED.recipient,letter=EXCLUDED.letter,auto=EXCLUDED.auto,error=NULL,sent_at=NULL,updated_at=now() RETURNING *`,[user.id,job.id,summary(job),letter.to,letter.body,auto])).rows[0];
      return {row,cv,account,password,before:existing};
    });
    if(reservation.existing)return reservation.existing;
    const {row,cv,account,password}=reservation;
    try{
      await transport.send(account.address,password,{...letter,from_address:account.address,from_name:account.sender_name,attachment:letter.attachment||cv.file_name},cv);
      const saved=(await db.query("UPDATE public.applications SET status='sent',sent_at=now(),updated_at=now() WHERE user_id=$1 AND opportunity_id=$2 AND status='sending' RETURNING *",[user.id,job.id])).rows[0];
      await db.query("UPDATE public.mail_accounts SET status='ok',error=NULL,checked_at=now() WHERE user_id=$1",[user.id]);
      await db.query('DELETE FROM public.cover_letters WHERE user_id=$1 AND opportunity_id=$2 AND cv_sha256=$3',[user.id,job.id,cv.sha256]);return saved||row;
    }catch(error){
      // Once SMTP may have accepted, preserve the counted reservation; no automatic retry.
      if(!(error instanceof MailError)||error.uncertain)return row;
      if(['auth','not_app_password','blocked'].includes(error.kind))await db.query("UPDATE public.mail_accounts SET status='invalid',error=$2,checked_at=now() WHERE user_id=$1",[user.id,error.kind]);
      if(!['recipient','rejected'].includes(error.kind)){
        await transaction(db,async c=>{
          await c.query('SELECT pg_advisory_xact_lock(hashtextextended($1,0))',[`mail:${user.id}`]);
          const before=reservation.before;
          if(before)await c.query(`UPDATE public.applications SET method=$3,status=$4,job=$5,error=$6,auto=$7,recipient=$8,sent_at=$9,letter=$10,updated_at=$11 WHERE user_id=$1 AND opportunity_id=$2 AND status='sending'`,[user.id,job.id,before.method,before.status,before.job,before.error,before.auto,before.recipient,before.sent_at,before.letter,before.updated_at]);
          else await c.query("DELETE FROM public.applications WHERE user_id=$1 AND opportunity_id=$2 AND status='sending'",[user.id,job.id]);
          if(['busy','gmail_limit'].includes(error.kind))await c.query(`INSERT INTO public.auto_apply(user_id,paused_until,pause_reason,next_send_at) VALUES($1,now()+$2::interval,$3,now()+$2::interval)
            ON CONFLICT(user_id) DO UPDATE SET paused_until=EXCLUDED.paused_until,pause_reason=EXCLUDED.pause_reason,next_send_at=EXCLUDED.next_send_at,updated_at=now()`,[user.id,error.kind==='gmail_limit'?'24 hours':'30 minutes',error.kind==='gmail_limit'?'gmail_limit':'gmail_busy']);
        });
        refuse(['auth','not_app_password','blocked'].includes(error.kind)?'email_invalid':error.kind==='gmail_limit'?'gmail_limit':'gmail_busy');
      }
      const code=error.kind==='recipient'?'address_refused':error.kind==='rejected'?'message_refused':error.kind;
      return (await db.query("UPDATE public.applications SET status='failed',error=$3,updated_at=now() WHERE user_id=$1 AND opportunity_id=$2 AND status='sending' RETURNING *",[user.id,job.id,code])).rows[0]||row;
    }
  }
  return {preview,send};
}
