import { getApps,initializeApp,applicationDefault } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { MemoryCache } from '../../../shared/cache/memory.js';
import { HttpError,unavailable } from '../../../shared/http/errors.js';

export function firebaseIdentity(config) {
  let auth;
  function sdk(){
    if(!config.firebaseProjectId)throw unavailable();
    if(!auth){const name=`autolinky-${config.firebaseProjectId}`;const app=getApps().find(a=>a.name===name)||initializeApp({projectId:config.firebaseProjectId,credential:applicationDefault()},name);auth=getAuth(app);}
    return auth;
  }
  return {verify:(token,sensitive)=>sdk().verifyIdToken(token,sensitive),getUser:uid=>sdk().getUser(uid),deleteUser:uid=>sdk().deleteUser(uid)};
}
const unauthorized=(detail='Invalid or expired token')=>new HttpError(401,detail,{'WWW-Authenticate':'Bearer'});
export function authentication(db,identity,limiter,config) {
  const cache=new MemoryCache({maxEntries:10000,maxBytes:4*1024*1024});
  const invalidate=uid=>cache.delete(uid);
  async function authenticate(request) {
    const header=request.headers.authorization;
    if(!header)throw unauthorized('Missing Authorization header');
    const match=/^Bearer (.+)$/i.exec(header);
    if(!match || match[1].trim().length>8192)throw unauthorized();
    const sensitive=!['GET','HEAD','OPTIONS'].includes(request.method);
    let claims;
    try { claims=await identity.verify(match[1].trim(),sensitive); }
    catch(error){
      if(error instanceof HttpError)throw error;
      if(['auth/id-token-expired','auth/id-token-revoked','auth/argument-error','auth/invalid-id-token','auth/user-disabled','auth/user-not-found','auth/tenant-id-mismatch'].includes(error.code))throw unauthorized();
      throw unavailable();
    }
    if(!claims.uid || claims.firebase?.sign_in_provider==='anonymous')throw unauthorized();
    let user=sensitive?undefined:cache.get(claims.uid);
    if(!user){
      try {
        const {rows}=await db.query('SELECT * FROM public.bind_firebase_user($1,$2,$3)',[claims.uid,claims.email || null,claims.email_verified===true]);
        user=rows[0];
      }catch{throw unavailable();}
      if(!user)throw unauthorized();
      cache.set(claims.uid,user,60000);
    }
    if(user.status!=='active')throw new HttpError(403,'Account blocked');
    request.user={...user,user_id:user.id};
    limiter.enforce(`all:${user.id}`,config.rateLimit,60);
  }
  return {authenticate,invalidate};
}
