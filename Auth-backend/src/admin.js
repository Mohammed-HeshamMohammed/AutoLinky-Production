import { randomUUID,randomBytes } from 'node:crypto';
import { transaction } from '../lib/db/client.js';
import { HttpError } from '../lib/http/errors.js';
import { durableLimit } from '../lib/http/rate-limit.js';
import { base32,encryptionKey,encryptTotp,decryptTotp,totpStep,signedToken,readToken,tokenHash } from './admin-crypto.js';
export const adminSessionPath='/internal/v1/admin/session';
const fail=()=>new HttpError(401,'invalid_login');
const denied=()=>new HttpError(403,'admin_required');
const body=properties=>({body:{type:'object',additionalProperties:false,required:Object.keys(properties),properties}});
const code={type:'string',pattern:'^[0-9]{6}$'},rank={viewer:0,operator:1,owner:2};
const accountSQL=`SELECT a.*,u.email FROM public.admin_accounts a JOIN public.app_users u ON u.id=a.user_id
 WHERE a.user_id=$1 AND u.status='active'`;
export function createAdminAuthentication({db,auth,secret,totpKey,now=Date.now}){
  if(typeof secret!=='string'||secret.length<32)throw Error('ADMIN_SESSION_SECRET must have at least 32 characters');
  const key=encryptionKey(totpKey),issue=(purpose,payload,seconds)=>signedToken(secret,{purpose,...payload,exp:Math.floor(now()/1000)+seconds});
  async function limits(request){await durableLimit(db,'admin:login:all',200,3600);await durableLimit(db,'admin:login:ip:'+tokenHash(request.ip||'local'),10,900);}
  async function bad(id){if(id)await db.query("UPDATE public.admin_accounts SET failed_logins=CASE WHEN failed_window_at<$2::timestamptz-interval '15 minutes' THEN 1 ELSE failed_logins+1 END,failed_window_at=CASE WHEN failed_window_at<$2::timestamptz-interval '15 minutes' THEN $2 ELSE failed_window_at END,locked_until=CASE WHEN failed_window_at<$2::timestamptz-interval '15 minutes' THEN NULL WHEN failed_logins+1>=5 THEN $2::timestamptz+interval '15 minutes' ELSE locked_until END WHERE id=$1 AND (locked_until IS NULL OR locked_until<=$2)",[id,new Date(now())]);throw fail();}
  function usable(account){return account?.enabled&&(!account.locked_until||new Date(account.locked_until).getTime()<=now());}
  async function user(request){
    // Even dashboard reads check Firebase revocation and disabled state.
    // Browser role flags, email matches and cached app bindings grant no access.
    const context={headers:request.headers,method:'POST'};await auth.authenticate(context);return context.user;
  }
  async function authenticate(request,{write=false,elevated=false}={}){
    const token=request.headers['x-admin-session'],claims=readToken(secret,token,'admin-session',now());if(!claims)throw fail();
    const appUser=await user(request);
    const {rows}=await db.query(`SELECT a.id,a.username,a.role,a.enabled,a.session_epoch,a.user_id,a.totp_confirmed_at,u.email
      FROM public.admin_sessions s JOIN public.admin_accounts a ON a.id=s.admin_id JOIN public.app_users u ON u.id=a.user_id
      WHERE s.id=$1 AND s.token_hash=$2 AND s.expires_at>$3 AND s.session_epoch=a.session_epoch
      AND a.user_id=$4 AND u.status='active'`,[claims.sid,tokenHash(token),new Date(now()),appUser.id]);
    const account=rows[0];if(!account?.enabled||!account.totp_confirmed_at||account.id!==claims.sub||account.user_id!==claims.user_id||account.session_epoch!==claims.epoch)throw fail();
    await durableLimit(db,'admin:session:'+account.id,write?60:300,60);
    if(write&&rank[account.role]<rank.operator)throw new HttpError(403,'Forbidden');
    const elevation=readToken(secret,request.headers['x-admin-elevation'],'admin-elevation',now()),confirmed=!!elevation&&elevation.sid===claims.sid&&elevation.sub===account.id&&elevation.user_id===account.user_id&&elevation.epoch===account.session_epoch;
    if(elevated&&!confirmed)throw new HttpError(403,'reauth_required');
    return {id:account.id,user_id:account.user_id,username:account.email||account.username,role:account.role,sid:claims.sid,epoch:account.session_epoch,elevated:confirmed};
  }
  async function login(request){
    await limits(request);const appUser=await user(request);
    return transaction(db,async connection=>{
      let account=(await connection.query(accountSQL+' FOR UPDATE OF u,a',[appUser.id])).rows[0];if(!account?.enabled)throw denied();if(!usable(account))throw fail();
      let enrollment;
      if(!account.totp_confirmed_at){
        if(!account.totp_secret||new Date(account.totp_pending_until||0).getTime()<=now()){
          const encrypted=encryptTotp(base32(randomBytes(20)),key);
          account={...account,...(await connection.query('UPDATE public.admin_accounts SET totp_secret=$2,totp_pending_until=$3 WHERE id=$1 RETURNING *',[account.id,encrypted,new Date(now()+600000)])).rows[0]};
        }
        const secret=decryptTotp(account.totp_secret,key),label=appUser.email||appUser.id;
        enrollment={secret,authenticator_uri:`otpauth://totp/AutoLinky:${encodeURIComponent(label)}?secret=${secret}&issuer=AutoLinky&algorithm=SHA1&digits=6&period=30`};
      }
      return {challenge:issue('admin-challenge',{sub:account.id,user_id:appUser.id,epoch:account.session_epoch,nonce:randomBytes(16).toString('base64url')},120),...(enrollment?{enrollment}:{})};
    });
  }
  async function verify(request){
    await limits(request);const claims=readToken(secret,request.body.challenge,'admin-challenge',now());if(!claims)throw fail();
    const appUser=await user(request);if(appUser.id!==claims.user_id)throw fail();
    const result=await transaction(db,async connection=>{
      const account=(await connection.query(accountSQL+' FOR UPDATE OF u,a',[appUser.id])).rows[0];
      let step=null;try{if(usable(account)&&account.id===claims.sub&&account.session_epoch===claims.epoch&&(account.totp_confirmed_at||new Date(account.totp_pending_until).getTime()>now()))step=totpStep(decryptTotp(account.totp_secret,key),request.body.code,account.last_totp_step,now());}catch{}
      if(step===null)return null;
      const sid=randomUUID(),token=issue('admin-session',{sub:account.id,user_id:appUser.id,epoch:account.session_epoch,sid},12*3600);
      await connection.query('UPDATE public.admin_accounts SET last_totp_step=$2,failed_logins=0,locked_until=NULL,totp_confirmed_at=coalesce(totp_confirmed_at,$3),totp_pending_until=NULL WHERE id=$1',[account.id,step,new Date(now())]);
      await connection.query('DELETE FROM public.admin_sessions WHERE expires_at<$1',[new Date(now())]);
      await connection.query('INSERT INTO public.admin_sessions(id,admin_id,token_hash,session_epoch,expires_at) VALUES($1,$2,$3,$4,$5)',[sid,account.id,tokenHash(token),account.session_epoch,new Date(now()+12*3600000)]);
      const username=appUser.email||account.username;
      await connection.query("INSERT INTO public.admin_log(admin,actor_id,action,request_id) VALUES($1,$2,'admin_login',$3)",[username,account.id,request.id]);
      return {token,admin:{id:account.id,user_id:appUser.id,username,role:account.role},expires_at:new Date(now()+12*3600000)};
    });return result||bad(claims.sub);
  }
  async function reauth(request){
    const admin=await authenticate(request,{write:true});await durableLimit(db,'admin:reauth:'+admin.id,10,900);
    const result=await transaction(db,async connection=>{
      const row=(await connection.query(accountSQL+' FOR UPDATE OF u,a',[admin.user_id])).rows[0];
      let step=null;try{if(usable(row)&&row.session_epoch===admin.epoch&&row.totp_confirmed_at)step=totpStep(decryptTotp(row.totp_secret,key),request.body.code,row.last_totp_step,now());}catch{}
      if(step===null)return null;
      await connection.query('UPDATE public.admin_accounts SET last_totp_step=$2 WHERE id=$1',[admin.id,step]);
      return {token:issue('admin-elevation',{sub:admin.id,user_id:admin.user_id,sid:admin.sid,epoch:admin.epoch},300)};
    });return result||bad(admin.id);
  }
  return {authenticate,login,verify,reauth,async logout(request){const admin=await authenticate(request);await db.query('DELETE FROM public.admin_sessions WHERE id=$1',[admin.sid]);return {signed_out:true};}};
}
export function registerAdminAuthentication(app,{db,auth,secret,totpKey,now}){
  if(!secret&&!totpKey)return null;
  const admin=createAdminAuthentication({db,auth,secret,totpKey,now});
  app.post('/admin/api/login',{schema:body({})},admin.login);
  app.post('/admin/api/verify',{schema:body({challenge:{type:'string',maxLength:2048},code})},admin.verify);
  app.post('/admin/api/reauth',{schema:body({code})},admin.reauth);
  app.post('/admin/api/logout',{schema:body({})},admin.logout);
  app.get('/admin/api/session',request=>admin.authenticate(request));
  app.post(adminSessionPath,{schema:body({write:{type:'boolean'},elevated:{type:'boolean'}})},request=>admin.authenticate(request,request.body));
  return admin;
}
