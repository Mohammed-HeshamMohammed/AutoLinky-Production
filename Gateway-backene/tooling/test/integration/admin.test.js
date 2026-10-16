import { before,after,test } from 'node:test';
import assert from 'node:assert/strict';
import pg from 'pg';
import { randomBytes,randomUUID } from 'node:crypto';
import { testDatabase } from '../helpers/database.js';
import { buildAuth } from '../../../../Auth-backend/app.js';
import { buildData } from '../../../../Data-baceknd/app.js';
import { buildGateway } from '../../../../Gateway-backene/src/app.js';
import { loadConfig } from '../../../../Auth-backend/lib/config.js';
import { remoteAdmin } from '../../../../Data-baceknd/src/console-auth.js';
import { hashPassword,base32,encryptTotp,totp,signedToken } from '../../../../Auth-backend/src/admin-crypto.js';
let cluster,auth,data,gateway,adminDb,clock=Date.now(),userId,ownerId,viewerId,ownerToken,viewerToken;
const key='backend-admin-test-key-'.repeat(3),adminKey='auth-admin-private-'.repeat(3),secret='independent-admin-session-'.repeat(3),totpKey=randomBytes(32),ownerSecret=base32(randomBytes(20)),viewerSecret=base32(randomBytes(20)),password='A secure local fixture password';
const call=(url,{token=ownerToken,...options}={})=>gateway.inject({url,...options,headers:{...(token?{authorization:'Bearer '+token}:{}),...options.headers}});
async function signIn(username,totpSecret){
  const first=await call('/admin/api/login',{token:null,method:'POST',payload:{username,password}});assert.equal(first.statusCode,200,first.body);
  const second=await call('/admin/api/verify',{token:null,method:'POST',payload:{challenge:first.json().challenge,code:totp(totpSecret,Math.floor(clock/30000))}});assert.equal(second.statusCode,200,second.body);return {token:second.json().token,challenge:first.json().challenge};
}
before(async()=>{
  cluster=await testDatabase();const pools={};for(const role of ['auth','data','console_data']){await cluster.db.query(`ALTER ROLE autolinky_${role} LOGIN PASSWORD '${cluster.password}'`);pools[role]=new pg.Pool({host:'127.0.0.1',port:cluster.port,user:'autolinky_'+role,password:cluster.password,database:'postgres',max:2});}
  adminDb=pools.console_data;
  const create=async(username,role,totpSecret)=>(await cluster.db.query('INSERT INTO public.admin_accounts(username,password_hash,totp_secret,role) VALUES($1,$2,$3,$4) RETURNING id',[username,await hashPassword(password),encryptTotp(totpSecret,totpKey),role])).rows[0].id;
  ownerId=await create('owner','owner',ownerSecret);viewerId=await create('viewer','viewer',viewerSecret);
  const config=loadConfig();
  auth=buildAuth({config,db:pools.auth,identity:{verify:async()=>({uid:'app-user',email:'person@example.com',email_verified:true})},identityData:{deleteUser:async()=>{}},schemaCheck:async()=>{},serviceKey:key,adminServiceKey:adminKey,adminOptions:{secret,totpKey:totpKey.toString('base64url'),now:()=>clock}});
  await auth.listen({host:'127.0.0.1',port:0});const authURL=`http://127.0.0.1:${auth.server.address().port}`;
  data=buildData({env:{SERVICE_KEY:key,DATA_IDENTITY_KEY:key,DATA_INGESTION_KEY:key},db:pools.data,consoleDb:adminDb,adminProvider:remoteAdmin({url:authURL,key:adminKey})});await data.listen({host:'127.0.0.1',port:0});
  const dataURL=`http://127.0.0.1:${data.server.address().port}`;
  gateway=buildGateway({targets:{auth:{url:authURL,key},data:{url:dataURL,key}}});
  userId=(await cluster.db.query("INSERT INTO public.app_users(email,firebase_uid) VALUES('person@example.com','app-user') RETURNING id")).rows[0].id;
});
after(async()=>{await gateway?.close();await data?.close();await auth?.close();await cluster?.close();});
test('a password challenge, app token and Device token cannot bypass administrator MFA',async()=>{
  const first=await call('/admin/api/login',{token:null,method:'POST',payload:{username:'owner',password}});assert.equal(first.statusCode,200,first.body);
  for(const token of [null,'firebase-app-token','Device dv1_fixture',first.json().challenge])assert.equal((await call('/admin/api/overview',{token})).statusCode,401);
  const bad=await call('/admin/api/verify',{token:null,method:'POST',payload:{challenge:first.json().challenge,code:'000000'}});assert.equal(bad.statusCode,401,bad.body);
  ownerToken=(await signIn('owner',ownerSecret)).token;viewerToken=(await signIn('viewer',viewerSecret)).token;
  const overview=await call('/admin/api/overview');assert.equal(overview.statusCode,200,overview.body);assert.equal(overview.json().users.total,1);
});
test('viewer access is read-only and data role cannot read private credentials or content',async()=>{
  const result=await call('/admin/api/users',{token:viewerToken});assert.equal(result.statusCode,200,result.body);assert.equal(result.json().items[0].email,'person@example.com');
  assert.equal((await call('/admin/api/users/'+userId,{token:viewerToken,method:'PUT',payload:{expected:'a'.repeat(64),reason:'fixture reason',patch:{status:'blocked'}}})).statusCode,403);
  for(const sql of ['SELECT password_hash FROM public.admin_accounts','SELECT secret FROM public.mail_accounts','SELECT text FROM public.user_cvs','SELECT bytes FROM public.user_cv_files','SELECT letter FROM public.applications','SELECT token_hash FROM public.app_devices'])await assert.rejects(adminDb.query(sql),{code:'42501'});
  await assert.rejects(adminDb.query('DELETE FROM public.admin_log'),{code:'42501'});
});
test('elevated changes are optimistic, audited atomically and block a cached app identity immediately',async()=>{
  const detail=await call('/admin/api/users/'+userId);assert.equal(detail.statusCode,200,detail.body);
  const payload={expected:detail.json().revision,reason:'Customer support fixture',patch:{status:'blocked',free_emails:25,daily_limit:10,plan:'pro',months:1}};
  assert.equal((await call('/admin/api/users/'+userId,{method:'PUT',payload})).statusCode,403);
  const userGet=()=>auth.inject({url:'/v1/me',headers:{'x-service-key':key,authorization:'Bearer real-app-fixture'}});assert.equal((await userGet()).statusCode,200);
  clock+=30000;
  const reauth=await call('/admin/api/reauth',{method:'POST',payload:{password,code:totp(ownerSecret,Math.floor(clock/30000))}});assert.equal(reauth.statusCode,200,reauth.body);
  const changed=await call('/admin/api/users/'+userId,{method:'PUT',headers:{'x-admin-elevation':reauth.json().token},payload});assert.equal(changed.statusCode,200,changed.body);assert.equal(changed.json().status,'blocked');
  assert.equal((await userGet()).statusCode,403);
  const duplicate=await call('/admin/api/users/'+userId,{method:'PUT',headers:{'x-admin-elevation':reauth.json().token},payload});assert.equal(duplicate.statusCode,409,duplicate.body);
  const audit=await call('/admin/api/audit');assert.equal(audit.statusCode,200,audit.body);assert(audit.json().items.some(item=>item.action==='update_user'&&item.reason==='Customer support fixture'));
  assert.equal((await cluster.db.query("SELECT count(*)::integer count FROM public.admin_log WHERE action='update_user'")).rows[0].count,1);
  const current=changed.json(),expires=current.subscription.ends_at;
  const limitOnly=await call('/admin/api/users/'+userId,{method:'PUT',headers:{'x-admin-elevation':reauth.json().token},payload:{expected:current.revision,reason:'Change limits without renewing Pro',patch:{daily_limit:12}}});
  assert.equal(limitOnly.statusCode,200,limitOnly.body);assert.equal(limitOnly.json().subscription.ends_at,expires);
});
test('session epoch, expiry, replayed authenticator steps and logout invalidate admin access',async()=>{
  await cluster.db.query('UPDATE public.admin_accounts SET session_epoch=session_epoch+1 WHERE id=$1',[viewerId]);assert.equal((await call('/admin/api/users',{token:viewerToken})).statusCode,401);
  const forged=signedToken(secret,{purpose:'admin-session',sub:ownerId,sid:randomUUID(),epoch:0,exp:Math.floor(clock/1000)+1000});assert.equal((await call('/admin/api/overview',{token:forged})).statusCode,401);
  const challenge=(await call('/admin/api/login',{token:null,method:'POST',payload:{username:'owner',password}})).json().challenge;
  const replay=await call('/admin/api/verify',{token:null,method:'POST',payload:{challenge,code:totp(ownerSecret,Math.floor(clock/30000))}});assert.equal(replay.statusCode,401);
  assert.equal((await call('/admin/api/logout',{method:'POST',payload:{}})).statusCode,200);assert.equal((await call('/admin/api/overview')).statusCode,401);
  clock+=30000;ownerToken=(await signIn('owner',ownerSecret)).token;clock+=12*3600000+30000;assert.equal((await call('/admin/api/overview')).statusCode,401);
});
