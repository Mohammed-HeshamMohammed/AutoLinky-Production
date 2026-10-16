import { randomUUID,randomBytes } from 'node:crypto';
import { transaction } from '../lib/db/client.js';
import { HttpError } from '../lib/http/errors.js';
import { durableLimit } from '../lib/http/rate-limit.js';
import { encryptionKey,decryptTotp,verifyPassword,totpStep,signedToken,readToken,tokenHash } from './admin-crypto.js';
export const adminSessionPath='/internal/v1/admin/session';
const fail=()=>new HttpError(401,'invalid_login');
const body=properties=>({body:{type:'object',additionalProperties:false,required:Object.keys(properties),properties}});
const password={type:'string',minLength:1,maxLength:128},code={type:'string',pattern:'^[0-9]{6}$'};
const bearer=request=>/^Bearer ([A-Za-z0-9_.-]+)$/.exec(request.headers.authorization||'')?.[1];
const rank={viewer:0,operator:1,owner:2};
export function createAdminAuthentication({db,secret,totpKey,now=Date.now}){
  if(typeof secret!=='string'||secret.length<32)throw Error('ADMIN_SESSION_SECRET must have at least 32 characters');
  const key=encryptionKey(totpKey),issue=(purpose,payload,seconds)=>signedToken(secret,{purpose,...payload,exp:Math.floor(now()/1000)+seconds});
  async function limits(request){await durableLimit(db,'admin:login:all',200,3600);await durableLimit(db,'admin:login:ip:'+tokenHash(request.ip||'local'),10,900);}
  async function bad(id){if(id)await db.query("UPDATE public.admin_accounts SET failed_logins=CASE WHEN failed_window_at<$2::timestamptz-interval '15 minutes' THEN 1 ELSE failed_logins+1 END,failed_window_at=CASE WHEN failed_window_at<$2::timestamptz-interval '15 minutes' THEN $2 ELSE failed_window_at END,locked_until=CASE WHEN failed_window_at<$2::timestamptz-interval '15 minutes' THEN NULL WHEN failed_logins+1>=5 THEN $2::timestamptz+interval '15 minutes' ELSE locked_until END WHERE id=$1 AND (locked_until IS NULL OR locked_until<=$2)",[id,new Date(now())]);throw fail();}
  function usable(account){return account?.enabled&&(!account.locked_until||new Date(account.locked_until).getTime()<=now());}
  async function authenticate(request,{write=false,elevated=false}={}){
    const token=bearer(request),claims=readToken(secret,token,'admin-session',now());if(!claims)throw fail();
    const {rows}=await db.query('SELECT a.id,a.username,a.role,a.enabled,a.session_epoch FROM public.admin_sessions s JOIN public.admin_accounts a ON a.id=s.admin_id WHERE s.id=$1 AND s.token_hash=$2 AND s.expires_at>$3 AND s.session_epoch=a.session_epoch',[claims.sid,tokenHash(token),new Date(now())]);
    const account=rows[0];if(!account?.enabled||account.id!==claims.sub||account.session_epoch!==claims.epoch)throw fail();
    await durableLimit(db,'admin:session:'+account.id,write?60:300,60);
    if(write&&rank[account.role]<rank.operator)throw new HttpError(403,'Forbidden');
    const elevation=readToken(secret,request.headers['x-admin-elevation'],'admin-elevation',now()),confirmed=!!elevation&&elevation.sid===claims.sid&&elevation.sub===account.id&&elevation.epoch===account.session_epoch;
    if(elevated&&!confirmed)throw new HttpError(403,'reauth_required');
    return {id:account.id,username:account.username,role:account.role,sid:claims.sid,epoch:account.session_epoch,elevated:confirmed};
  }
  async function login(request){
    await limits(request);const username=request.body.username.trim().toLowerCase();
    const {rows}=await db.query('SELECT id,username,password_hash,enabled,session_epoch,locked_until FROM public.admin_accounts WHERE username=$1',[username]);
    const account=rows[0];
    // The dummy hash keeps unknown-account password work comparable.
    const hash=account?.password_hash||'scrypt:32768:8:1:AAAAAAAAAAAAAAAAAAAAAA:AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA';
    const verified=await verifyPassword(request.body.password,hash);
    if(!usable(account)||!verified)return bad(account?.id);
    return {challenge:issue('admin-challenge',{sub:account.id,epoch:account.session_epoch,nonce:randomBytes(16).toString('base64url')},120)};
  }
  async function verify(request){
    await limits(request);const claims=readToken(secret,request.body.challenge,'admin-challenge',now());if(!claims)throw fail();
    return transaction(db,async connection=>{
      const {rows}=await connection.query('SELECT id,username,role,enabled,session_epoch,locked_until,totp_secret,last_totp_step FROM public.admin_accounts WHERE id=$1 FOR UPDATE',[claims.sub]);const account=rows[0];
      let step=null;try{if(usable(account)&&account.session_epoch===claims.epoch)step=totpStep(decryptTotp(account.totp_secret,key),request.body.code,account.last_totp_step,now());}catch{}
      if(step===null)return null;
      const sid=randomUUID(),token=issue('admin-session',{sub:account.id,epoch:account.session_epoch,sid},12*3600);
      await connection.query('UPDATE public.admin_accounts SET last_totp_step=$2,failed_logins=0,locked_until=NULL WHERE id=$1',[account.id,step]);
      await connection.query('DELETE FROM public.admin_sessions WHERE expires_at<$1',[new Date(now())]);
      await connection.query('INSERT INTO public.admin_sessions(id,admin_id,token_hash,session_epoch,expires_at) VALUES($1,$2,$3,$4,$5)',[sid,account.id,tokenHash(token),account.session_epoch,new Date(now()+12*3600000)]);
      await connection.query("INSERT INTO public.admin_log(admin,actor_id,action,request_id) VALUES($1,$2,'admin_login',$3)",[account.username,account.id,request.id]);
      return {token,admin:{id:account.id,username:account.username,role:account.role},expires_at:new Date(now()+12*3600000)};
    }).then(result=>result||bad(claims.sub));
  }
  async function reauth(request){
    const admin=await authenticate(request,{write:true});await durableLimit(db,'admin:reauth:'+admin.id,10,900);
    const result=await transaction(db,async connection=>{
      const row=(await connection.query('SELECT password_hash,totp_secret,last_totp_step,locked_until,enabled FROM public.admin_accounts WHERE id=$1 FOR UPDATE',[admin.id])).rows[0];
      let step=null;try{if(usable(row)&&await verifyPassword(request.body.password,row.password_hash))step=totpStep(decryptTotp(row.totp_secret,key),request.body.code,row.last_totp_step,now());}catch{}
      if(step===null)return null;
      await connection.query('UPDATE public.admin_accounts SET last_totp_step=$2 WHERE id=$1',[admin.id,step]);
      return {token:issue('admin-elevation',{sub:admin.id,sid:admin.sid,epoch:admin.epoch},300)};
    });return result||bad(admin.id);
  }
  return {authenticate,login,verify,reauth,async logout(request){const admin=await authenticate(request);await db.query('DELETE FROM public.admin_sessions WHERE id=$1',[admin.sid]);return {signed_out:true};}};
}
export function registerAdminAuthentication(app,{db,secret,totpKey,now}){
  if(!secret&&!totpKey)return null;
  const admin=createAdminAuthentication({db,secret,totpKey,now});
  app.post('/admin/api/login',{schema:body({username:{type:'string',minLength:1,maxLength:64},password})},async request=>{
    if(!(await db.query('SELECT id FROM public.admin_accounts WHERE enabled LIMIT 1')).rowCount)throw new HttpError(404,'admin_not_configured');return admin.login(request);
  });
  app.post('/admin/api/verify',{schema:body({challenge:{type:'string',maxLength:2048},code})},admin.verify);
  app.post('/admin/api/reauth',{schema:body({password,code})},admin.reauth);
  app.post('/admin/api/logout',{schema:body({})},admin.logout);
  app.get('/admin/api/session',request=>admin.authenticate(request));
  app.post(adminSessionPath,{schema:body({write:{type:'boolean'},elevated:{type:'boolean'}})},request=>admin.authenticate(request,request.body));
  return admin;
}
