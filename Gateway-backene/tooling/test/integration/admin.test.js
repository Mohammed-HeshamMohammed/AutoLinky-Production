import { before,after,beforeEach,test } from 'node:test';
import assert from 'node:assert/strict';
import pg from 'pg';
import { randomBytes,randomUUID } from 'node:crypto';
import { testDatabase } from '../helpers/database.js';
import { buildAuth } from '../../../../Auth-backend/app.js';
import { buildData } from '../../../../Data-baceknd/app.js';
import { buildGateway } from '../../../../Gateway-backene/src/app.js';
import { loadConfig } from '../../../../Auth-backend/lib/config.js';
import { remoteAdmin } from '../../../../Data-baceknd/src/console-auth.js';
import { base32,encryptTotp,totp,signedToken } from '../../../../Auth-backend/src/admin-crypto.js';
import { assignAdministrator } from '../../../../Auth-backend/src/admin-provision.js';
let cluster,auth,data,gateway,adminDb,authDb,clock=Date.now(),userId,ownerUserId,viewerUserId,ownerId,viewerId,ownerToken,viewerToken;
const verified=[];let revoked=false;
const key='backend-admin-test-key-'.repeat(3),adminKey='auth-admin-private-'.repeat(3),secret='independent-admin-session-'.repeat(3),totpKey=randomBytes(32),ownerSecret=base32(randomBytes(20)),viewerSecret=base32(randomBytes(20));
const call=(url,{token=ownerToken,appToken,...options}={})=>gateway.inject({url,...options,headers:{...((appToken===undefined?(token&&token===viewerToken?'viewer-app-token':'owner-app-token'):appToken)?{authorization:'Bearer '+(appToken===undefined?(token&&token===viewerToken?'viewer-app-token':'owner-app-token'):appToken)}:{}),...(token?{'x-admin-session':token}:{}),...options.headers}});
async function signIn(username,totpSecret){
  const first=await call('/admin/api/login',{token:null,appToken:username+'-app-token',method:'POST',payload:{}});assert.equal(first.statusCode,200,first.body);
  const second=await call('/admin/api/verify',{token:null,appToken:username+'-app-token',method:'POST',payload:{challenge:first.json().challenge,code:totp(totpSecret,Math.floor(clock/30000))}});assert.equal(second.statusCode,200,second.body);return {token:second.json().token,challenge:first.json().challenge};
}
before(async()=>{
  cluster=await testDatabase();const pools={};for(const role of ['auth','data','console_data']){await cluster.db.query(`ALTER ROLE autolinky_${role} LOGIN PASSWORD '${cluster.password}'`);pools[role]=new pg.Pool({host:'127.0.0.1',port:cluster.port,user:'autolinky_'+role,password:cluster.password,database:'postgres',max:2});}
  adminDb=pools.console_data;authDb=pools.auth;
  userId=(await cluster.db.query("INSERT INTO public.app_users(email,firebase_uid) VALUES('person@example.com','app-user') RETURNING id")).rows[0].id;
  const create=async(username,role,totpSecret)=>{const user=(await cluster.db.query('INSERT INTO public.app_users(email,firebase_uid) VALUES($1,$2) RETURNING id',[username+'@example.com',username+'-uid'])).rows[0].id;const admin=(await cluster.db.query('INSERT INTO public.admin_accounts(user_id,username,totp_secret,totp_confirmed_at,role) VALUES($1,$2,$3,now(),$4) RETURNING id',[user,username,encryptTotp(totpSecret,totpKey),role])).rows[0].id;return {user,admin};};
  ({user:ownerUserId,admin:ownerId}=await create('owner','owner',ownerSecret));({user:viewerUserId,admin:viewerId}=await create('viewer','viewer',viewerSecret));
  const config=loadConfig();
  auth=buildAuth({config,db:pools.auth,identity:{verify:async(token,sensitive)=>{verified.push({token,sensitive});const names={'owner-app-token':['owner-uid','owner@example.com'],'viewer-app-token':['viewer-uid','viewer@example.com'],'real-app-fixture':['app-user','person@example.com']};if(!names[token]||revoked&&token==='owner-app-token')throw Object.assign(Error('invalid'),{code:revoked?'auth/id-token-revoked':'auth/invalid-id-token'});return {uid:names[token][0],email:names[token][1],email_verified:true};}},identityData:{deleteUser:async()=>{}},schemaCheck:async()=>{},serviceKey:key,adminServiceKey:adminKey,adminOptions:{secret,totpKey:totpKey.toString('base64url'),now:()=>clock}});
  await auth.listen({host:'127.0.0.1',port:0});const authURL=`http://127.0.0.1:${auth.server.address().port}`;
  data=buildData({env:{SERVICE_KEY:key,DATA_IDENTITY_KEY:key,DATA_INGESTION_KEY:key},db:pools.data,adminProvider:remoteAdmin({url:authURL,key:adminKey})});await data.listen({host:'127.0.0.1',port:0});
  const dataURL=`http://127.0.0.1:${data.server.address().port}`;
  gateway=buildGateway({targets:{auth:{url:authURL,key},data:{url:dataURL,key}}});
});
beforeEach(async()=>{await cluster.db.query("DELETE FROM public.api_rate_limits WHERE bucket LIKE 'admin:login:%'");});
after(async()=>{await gateway?.close();await data?.close();await auth?.close();await adminDb?.end();await cluster?.close();});
test('only an assigned app user plus its verified authenticator can open administrator data',async()=>{
  const first=await call('/admin/api/login',{token:null,method:'POST',payload:{}});assert.equal(first.statusCode,200,first.body);
  assert.equal(first.json().enrollment,undefined);
  assert.equal((await call('/admin/api/login',{token:null,appToken:'real-app-fixture',method:'POST',payload:{}})).statusCode,403);
  assert.equal((await call('/admin/api/login',{token:null,appToken:null,method:'POST',payload:{}})).statusCode,401);
  assert.equal((await call('/admin/api/login',{token:null,method:'POST',payload:{username:'owner',password:'legacy-password'}})).statusCode,422);
  for(const token of [null,'firebase-app-token','Device dv1_fixture',first.json().challenge])assert.equal((await call('/admin/api/overview',{token})).statusCode,401);
  const bad=await call('/admin/api/verify',{token:null,method:'POST',payload:{challenge:first.json().challenge,code:'000000'}});assert.equal(bad.statusCode,401,bad.body);
  ownerToken=(await signIn('owner',ownerSecret)).token;viewerToken=(await signIn('viewer',viewerSecret)).token;
  for(const appToken of [null,'real-app-fixture','viewer-app-token',ownerToken])assert.equal((await call('/admin/api/overview',{appToken})).statusCode,401);
  assert.equal((await call('/admin/api/overview',{token:null})).statusCode,401);
  assert.equal((await call('/admin/api/verify',{token:null,appToken:'viewer-app-token',method:'POST',payload:{challenge:first.json().challenge,code:totp(ownerSecret,Math.floor(clock/30000))}})).statusCode,401);
  const me=await auth.inject({url:'/v1/me',headers:{'x-service-key':key,authorization:'Bearer owner-app-token'}});assert.equal(me.json().admin_role,'owner');
  const overview=await call('/admin/api/overview');assert.equal(overview.statusCode,200,overview.body);assert.equal(overview.json().users.total,3);
});
test('viewer access is read-only and data role cannot read private credentials or content',async()=>{
  const result=await call('/admin/api/users',{token:viewerToken});assert.equal(result.statusCode,200,result.body);assert.equal(result.json().items.some(item=>item.email==='person@example.com'),true);
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
  const reauth=await call('/admin/api/reauth',{method:'POST',payload:{code:totp(ownerSecret,Math.floor(clock/30000))}});assert.equal(reauth.statusCode,200,reauth.body);
  const changed=await call('/admin/api/users/'+userId,{method:'PUT',headers:{'x-admin-elevation':reauth.json().token},payload});assert.equal(changed.statusCode,200,changed.body);assert.equal(changed.json().status,'blocked');
  assert.equal((await userGet()).statusCode,403);
  const duplicate=await call('/admin/api/users/'+userId,{method:'PUT',headers:{'x-admin-elevation':reauth.json().token},payload});assert.equal(duplicate.statusCode,409,duplicate.body);
  const audit=await call('/admin/api/audit');assert.equal(audit.statusCode,200,audit.body);assert(audit.json().items.some(item=>item.action==='update_user'&&item.reason==='Customer support fixture'));
  assert.equal((await cluster.db.query("SELECT count(*)::integer count FROM public.admin_log WHERE action='update_user'")).rows[0].count,1);
  const current=changed.json(),expires=current.subscription.ends_at;
  const limitOnly=await call('/admin/api/users/'+userId,{method:'PUT',headers:{'x-admin-elevation':reauth.json().token},payload:{expected:current.revision,reason:'Change limits without renewing Pro',patch:{daily_limit:12}}});
  assert.equal(limitOnly.statusCode,200,limitOnly.body);assert.equal(limitOnly.json().subscription.ends_at,expires);
});
test('reference analytics use real Cairo days and expanded filters without granting raw download access',async()=>{
  for(const days of [14,30,90]){const response=await call('/admin/api/overview?days='+days);assert.equal(response.statusCode,200,response.body);assert.equal(response.json().series.length,days);assert.equal(response.json().users.total,3);assert.equal(response.json().downloads.total,0);}
  assert.equal((await call('/admin/api/overview?days=365')).statusCode,422);
  for(const filter of ['custom','sending'])assert.equal((await call('/admin/api/users?sort=sent_24h&filter='+filter)).statusCode,200);
  await assert.rejects(adminDb.query('SELECT visitor FROM public.app_downloads'),{code:'42501'});
});
test('reference user controls extend Pro, preserve unlimited dates and round-trip custom allowance flags',async()=>{
  clock+=30000;const elevation=(await call('/admin/api/reauth',{method:'POST',payload:{code:totp(ownerSecret,Math.floor(clock/30000))}})).json().token;
  async function patch(value){const before=(await call('/admin/api/users/'+userId)).json();return call('/admin/api/users/'+userId,{method:'PUT',headers:{'x-admin-elevation':elevation},payload:{expected:before.revision,reason:'Reference dashboard management test',patch:value}});}
  const initial=(await call('/admin/api/users/'+userId)).json(),extended=await patch({plan:'pro',months:3});assert.equal(extended.statusCode,200,extended.body);assert(new Date(extended.json().subscription.ends_at)>new Date(initial.subscription.ends_at));
  const unlimited=await patch({unlimited:true,daily_unlimited:true,limits_note:'Fixture no-cap account'});assert.equal(unlimited.statusCode,200,unlimited.body);assert.equal(unlimited.json().limits.unlimited,true);assert.equal(unlimited.json().limits.daily_unlimited,true);
  const forever=await patch({plan:'pro',forever:true});assert.equal(forever.statusCode,200,forever.body);assert.equal(forever.json().subscription.ends_at,null);
  const preserve=await patch({plan:'pro',months:1});assert.equal(preserve.json().subscription.ends_at,null);
  const until=new Date(Date.now()+40*86400000).toISOString().slice(0,10),dated=await patch({plan:'pro',until});assert.equal(dated.statusCode,200,dated.body);
  const expectedEnd=(await cluster.db.query("SELECT($1::date+1)::timestamp AT TIME ZONE 'Africa/Cairo' at",[until])).rows[0].at;assert.equal(Date.parse(dated.json().subscription.ends_at),+expectedEnd);
  await cluster.db.query("UPDATE subscriptions SET starts_at=now()+interval '1 year',ends_at=now()+interval '2 years' WHERE email='person@example.com'");
  const future=await patch({plan:'pro',months:1});assert.equal(future.statusCode,200,future.body);assert(Date.parse(future.json().subscription.ends_at)<Date.now()+35*86400000);
  const invalid=await patch({plan:'pro',until:'2027-02-31'});assert.equal(invalid.statusCode,422);
  const defaults=await patch({free_emails:null,daily_limit:null,unlimited:false,daily_unlimited:false,limits_note:null});assert.equal(defaults.statusCode,200,defaults.body);assert.equal(defaults.json().limits,null);
});
test('operational changes require elevated roles, reject stale revisions and log an atomic pause',async()=>{
  const collector=await call('/admin/api/collector');assert.equal(collector.statusCode,200,collector.body);
  assert.equal((await call('/admin/api/controls/collector',{token:viewerToken,method:'PUT',payload:{expected:collector.json().control.revision,reason:'Viewer cannot pause',paused:true}})).statusCode,403);
  clock+=30000;const elevation=(await call('/admin/api/reauth',{method:'POST',payload:{code:totp(ownerSecret,Math.floor(clock/30000))}})).json().token;
  const payload={expected:collector.json().control.revision,reason:'Pause collector fixture',paused:true},headers={'x-admin-elevation':elevation};
  const paused=await call('/admin/api/controls/collector',{method:'PUT',headers,payload});assert.equal(paused.statusCode,200,paused.body);assert.equal(paused.json().paused,true);
  assert.equal((await call('/admin/api/controls/collector',{method:'PUT',headers,payload})).statusCode,409);
  assert.equal((await data.inject({method:'POST',url:'/internal/v1/collection/control',payload:{},headers:{'x-service-key':key}})).json().paused,true);
  const sender=(await call('/admin/api/sender')).json();const stop=await call('/admin/api/controls/sender',{method:'PUT',headers,payload:{expected:sender.control.revision,reason:'Pause automatic reservations fixture',paused:true}});assert.equal(stop.statusCode,200,stop.body);assert.equal((await cluster.db.query('SELECT public.sender_reservation_allowed() allowed')).rows[0].allowed,false);
  const log=await call('/admin/api/audit');assert(log.json().items.some(item=>item.action==='collector_pause'&&item.reason==='Pause collector fixture'));
});
test('manual search titles normalize consistently and edits protect user demand',async()=>{
  clock+=30000;const elevation=(await call('/admin/api/reauth',{method:'POST',payload:{code:totp(ownerSecret,Math.floor(clock/30000))}})).json().token,headers={'x-admin-elevation':elevation};
  const add=await call('/admin/api/search-titles',{method:'POST',headers,payload:{title:'Senior UI Engineer',reason:'Add manual search fixture'}});assert.equal(add.statusCode,200,add.body);assert.equal(add.json().title,'ui engineer');
  const list=await call('/admin/api/search-titles?q=ui%20engineer&show=manual');assert.equal(list.statusCode,200,list.body);const row=list.json().items[0];assert(row.revision);assert.equal(list.json().worker_connected,false);
  const off=await call('/admin/api/search-titles/'+row.id,{method:'PUT',headers,payload:{expected:row.revision,reason:'Disable manual fixture title',action:'disable'}});assert.equal(off.statusCode,200,off.body);
  const stale=await call('/admin/api/search-titles/'+row.id,{method:'PUT',headers,payload:{expected:row.revision,reason:'Reject stale title request',action:'manual'}});assert.equal(stale.statusCode,409);
  await cluster.db.query('UPDATE public.search_titles SET users=2 WHERE id=$1',[row.id]);const demanded=(await call('/admin/api/search-titles?q=ui%20engineer')).json().items[0];
  const remove=await call('/admin/api/search-titles/'+row.id,{method:'PUT',headers,payload:{expected:demanded.revision,reason:'Cannot delete a demanded title',action:'delete'}});assert.equal(remove.statusCode,409,remove.body);
});
test('session epoch, expiry, replayed authenticator steps and logout invalidate admin access',async()=>{
  await cluster.db.query('UPDATE public.admin_accounts SET session_epoch=session_epoch+1 WHERE id=$1',[viewerId]);assert.equal((await call('/admin/api/users',{token:viewerToken})).statusCode,401);
  const forged=signedToken(secret,{purpose:'admin-session',sub:ownerId,sid:randomUUID(),epoch:0,exp:Math.floor(clock/1000)+1000});assert.equal((await call('/admin/api/overview',{token:forged})).statusCode,401);
  const challenge=(await call('/admin/api/login',{token:null,method:'POST',payload:{}})).json().challenge;
  const replay=await call('/admin/api/verify',{token:null,method:'POST',payload:{challenge,code:totp(ownerSecret,Math.floor(clock/30000))}});assert.equal(replay.statusCode,401);
  assert.equal((await call('/admin/api/logout',{method:'POST',payload:{}})).statusCode,200);assert.equal((await call('/admin/api/overview')).statusCode,401);
  clock+=30000;ownerToken=(await signIn('owner',ownerSecret)).token;clock+=12*3600000+30000;assert.equal((await call('/admin/api/overview')).statusCode,401);
});
test('assigned user enrollment is confirmed before access and a consumed setup key is never returned',async()=>{
  await cluster.db.query("UPDATE public.app_users SET status='active' WHERE id=$1",[userId]);
  await assignAdministrator(authDb,{userId,role:'operator',reason:'Explicitly assign the fixture application user'});
  assert.equal((await call('/admin/api/overview',{appToken:'real-app-fixture'})).statusCode,401);
  const start=()=>call('/admin/api/login',{token:null,appToken:'real-app-fixture',method:'POST',payload:{}});
  const pending=(await start()).json();assert.match(pending.enrollment.secret,/^[A-Z2-7]{32}$/);
  const verify=code=>call('/admin/api/verify',{token:null,appToken:'real-app-fixture',method:'POST',payload:{challenge:pending.challenge,code}});
  const result=await verify(totp(pending.enrollment.secret,Math.floor(clock/30000)));assert.equal(result.statusCode,200,result.body);
  assert.equal((await verify(totp(pending.enrollment.secret,Math.floor(clock/30000)))).statusCode,401);
  assert.equal((await start()).json().enrollment,undefined);
  const token=result.json().token;assert.equal((await call('/admin/api/overview',{token,appToken:'real-app-fixture'})).statusCode,200);
  assert.equal((await call('/admin/api/overview',{token,appToken:'owner-app-token'})).statusCode,401);
  await assignAdministrator(authDb,{userId,role:'none',reason:'Revoke fixture privilege after enrollment test'});
  assert.equal((await call('/admin/api/overview',{token,appToken:'real-app-fixture'})).statusCode,401);
  assert.equal((await start()).statusCode,403);
});
test('revocation, blocking, demotion, factor reset and deletion invalidate earlier MFA sessions',async()=>{
  clock+=30000;ownerToken=(await signIn('owner',ownerSecret)).token;
  const checksBefore=verified.length;assert.equal((await call('/admin/api/overview')).statusCode,200);
  assert(verified.slice(checksBefore).some(item=>item.token==='owner-app-token'&&item.sensitive===true));
  revoked=true;assert.equal((await call('/admin/api/overview')).statusCode,401);revoked=false;
  await cluster.db.query("UPDATE public.app_users SET status='blocked' WHERE id=$1",[ownerUserId]);assert.equal((await call('/admin/api/overview')).statusCode,403);
  await cluster.db.query("UPDATE public.app_users SET status='active' WHERE id=$1",[ownerUserId]);assert.equal((await call('/admin/api/overview')).statusCode,401);
  clock+=30000;ownerToken=(await signIn('owner',ownerSecret)).token;
  await assignAdministrator(authDb,{firebaseUid:'owner-uid',role:'viewer',reason:'Demote owner fixture to read-only admin'});assert.equal((await call('/admin/api/overview')).statusCode,401);
  clock+=30000;ownerToken=(await signIn('owner',ownerSecret)).token;
  assert.equal((await call('/admin/api/reauth',{method:'POST',payload:{code:totp(ownerSecret,Math.floor(clock/30000))}})).statusCode,403);
  await assignAdministrator(authDb,{userId:ownerUserId,role:'owner',reason:'Restore fixture role and reset authenticator',resetAuthenticator:true});assert.equal((await call('/admin/api/overview')).statusCode,401);
  const challenge=(await call('/admin/api/login',{token:null,method:'POST',payload:{}})).json();assert(challenge.enrollment);
  const row=(await cluster.db.query('SELECT totp_confirmed_at,totp_secret FROM admin_accounts WHERE id=$1',[ownerId])).rows[0];assert.equal(row.totp_confirmed_at,null);assert.notEqual(row.totp_secret,challenge.enrollment.secret);
  clock+=600001;
  assert.equal((await call('/admin/api/verify',{token:null,method:'POST',payload:{challenge:challenge.challenge,code:totp(challenge.enrollment.secret,Math.floor(clock/30000))}})).statusCode,401);
  const renewed=(await call('/admin/api/login',{token:null,method:'POST',payload:{}})).json();assert.notEqual(renewed.enrollment.secret,challenge.enrollment.secret);
  const login=await call('/admin/api/verify',{token:null,method:'POST',payload:{challenge:renewed.challenge,code:totp(renewed.enrollment.secret,Math.floor(clock/30000))}});assert.equal(login.statusCode,200,login.body);ownerToken=login.json().token;
  await cluster.db.query('DELETE FROM public.app_users WHERE id=$1',[ownerUserId]);
  assert.equal((await cluster.db.query('SELECT FROM public.admin_accounts WHERE id=$1',[ownerId])).rowCount,0);
  assert.equal((await call('/admin/api/overview')).statusCode,401);
});
test('authenticator guessing locks the assigned account, then a fresh code restores access after the lock',async()=>{
  const start=()=>call('/admin/api/login',{token:null,appToken:'viewer-app-token',method:'POST',payload:{}});
  const challenge=(await start()).json().challenge,wrong=String((Number(totp(viewerSecret,Math.floor(clock/30000)))+1)%1000000).padStart(6,'0');
  for(let attempt=0;attempt<5;attempt++)assert.equal((await call('/admin/api/verify',{token:null,appToken:'viewer-app-token',method:'POST',payload:{challenge,code:wrong}})).statusCode,401);
  assert.equal((await start()).statusCode,401);
  clock+=900001;viewerToken=(await signIn('viewer',viewerSecret)).token;
  assert.equal((await call('/admin/api/overview',{token:viewerToken})).statusCode,200);
});
test('offline assignment rejects unknown/blocked users, standalone identities and public promotion attempts',async()=>{
  await assert.rejects(assignAdministrator(authDb,{userId:randomUUID(),role:'owner',reason:'Unknown identity must not be created'}),/must sign into AutoLinky/);
  await cluster.db.query("UPDATE public.app_users SET status='blocked' WHERE id=$1",[viewerUserId]);
  await assert.rejects(assignAdministrator(authDb,{userId:viewerUserId,role:'owner',reason:'Blocked identity cannot become owner'}),/blocked user/);
  await assert.rejects(cluster.db.query("INSERT INTO public.admin_accounts(username,role) VALUES('legacy','owner')"),{code:'23514'});
  assert.equal((await call('/admin/api/users/'+viewerUserId,{token:null,method:'PUT',payload:{role:'owner'}})).statusCode,401);
  assert((await cluster.db.query("SELECT count(*)::integer n FROM admin_log WHERE action='admin_role_revoke' AND admin='offline-operator'")).rows[0].n>0);
});
