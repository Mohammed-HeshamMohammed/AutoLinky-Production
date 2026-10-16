import { before,after,test } from 'node:test';
import assert from 'node:assert/strict';
import pg from 'pg';
import { randomUUID,createHash } from 'node:crypto';
import { testDatabase } from '../helpers/database.js';
import { buildAuth } from '../../services/auth/app.js';
import { buildAppBackend } from '../../services/app/app.js';
import { buildMessaging } from '../../services/messaging/app.js';
import { loadConfig } from '../../shared/config.js';
import { buildGateway } from '../../services/gateway/src/app.js';
import { remoteAuthentication,requireServiceKey } from '../../shared/runtime.js';
import { buildFetching } from '../../services/fetching/app.js';
import { buildData } from '../../services/data/app.js';
import { processBatch } from '../../services/data/src/process.js';
import { MailError } from '../../services/messaging/src/email/gmail.js';

let cluster,gateway,auth,app,messaging,fetching,data,smtpCalls=0;
const pools={},key='split-service-test-'.repeat(3),identity={verify:async token=>{
  if(token!=='valid')throw Object.assign(Error(),{code:'auth/invalid-id-token'});
  return {uid:'split-user',email:'split@example.com',email_verified:true};
},deleteUser:async()=>{}};
before(async()=>{
  cluster=await testDatabase();
  for(const role of ['auth','app','messaging','fetching','data']){
    await cluster.db.query(`ALTER ROLE autolinky_${role} LOGIN PASSWORD '${cluster.password}'`);
    pools[role]=new pg.Pool({host:'127.0.0.1',port:cluster.port,user:'autolinky_'+role,password:cluster.password,database:'postgres',max:2});
  }
  const config=loadConfig({MAIL_SECRET_KEY:Buffer.alloc(32,1).toString('base64url'),INTERNAL_DOWNLOADS_KEY:key,CORS_ALLOWED_ORIGINS:'https://auto-linky.com'});
  auth=buildAuth({config,db:pools.auth,identity});requireServiceKey(auth,key);await auth.listen({host:'127.0.0.1',port:0});
  const authURL=`http://127.0.0.1:${auth.server.address().port}`;
  for(const role of ['app','messaging']){
    const server=(role==='app'?buildAppBackend:buildMessaging)({config,db:pools[role],authProvider:remoteAuthentication({url:authURL,key}),
      extractor:async bytes=>({file_type:'pdf',size:bytes.length,pages:1,text:'Developer\nJavaScript\n'+'Experience building web applications. '.repeat(10),sha256:createHash('sha256').update(bytes).digest('hex'),links:[]}),
      transport:{verify:async()=>{},send:async()=>{smtpCalls++;throw new MailError('busy',{uncertain:true});}}});
    requireServiceKey(server,key);await server.listen({host:'127.0.0.1',port:0});
    if(role==='app')app=server;else messaging=server;
  }
  gateway=buildGateway({targets:Object.fromEntries(Object.entries({auth,app,messaging}).map(([name,server])=>[name,{url:`http://127.0.0.1:${server.server.address().port}`,key}]))});
  const operationConfig={SERVICE_KEY:key,COLLECTOR_ENABLED:'true',DATA_PROCESSING_ENABLED:'true',FETCH_PROVIDERS_JSON:JSON.stringify({demo:{url:'https://provider.invalid/jobs'}})};
  fetching=buildFetching({env:operationConfig,db:pools.fetching,fetcher:async()=>Response.json([{id:'job-1',title:' Engineer ',company:'AutoLinky'},{title:''}])});
  data=buildData({env:operationConfig,db:pools.data});
  await fetching.ready();await data.ready();
});
after(async()=>{for(const server of [gateway,fetching,data,messaging,app,auth])await server?.close();await cluster?.close();});
const call=(url,options={})=>gateway.inject({url,...options,headers:{authorization:'Bearer valid',...options.headers}});
test('one public gateway preserves user flows across three independently listening services',async()=>{
  const ready=await gateway.inject('/health/ready');assert.equal(ready.statusCode,200,ready.body);
  assert.equal((await gateway.inject('/v1/me')).statusCode,401);
  const me=await call('/v1/me');assert.equal(me.statusCode,200,me.body);assert.equal(me.json().email,'split@example.com');
  let response=await call('/v1/profile',{method:'PUT',payload:{headline:'Engineer',countries:['EG']}});assert.equal(response.statusCode,200,response.body);
  response=await call('/v1/taxonomy');assert.equal(response.statusCode,200,response.body);
  response=await call('/v1/cv?name=split.pdf',{method:'POST',payload:Buffer.from('%PDF-split-fixture'),headers:{'content-type':'application/pdf'}});assert.equal(response.statusCode,200,response.body);
  response=await call('/v1/jobs/matched');assert.equal(response.statusCode,200,response.body);
  const id=randomUUID();
  await cluster.db.query("INSERT INTO opportunities(id,source,source_ref,title,field,work_mode,level,employment_type,apply_methods,enrich_version,posted_at) VALUES($1,'linkedin_job','split-fixture','Engineer','software','remote','mid','full_time',ARRAY['external'],'fixture',now())",[id]);
  response=await call('/v1/jobs');assert.equal(response.statusCode,200,response.body);
  response=await call('/v1/applications',{method:'POST',payload:{job_id:id,method:'external'}});assert.equal(response.statusCode,201,response.body);
  response=await call('/v1/applications');assert.equal(response.statusCode,200,response.body);assert.equal(response.json().items.length,1);
  response=await call('/v1/auto-apply');assert.equal(response.statusCode,200,response.body);
  response=await call('/v1/devices',{method:'POST',payload:{platform:'ios'}});assert.equal(response.statusCode,201,response.body);
  response=await call('/v1/device/activity?after='+encodeURIComponent(new Date().toISOString()),{headers:{authorization:'Device '+response.json().token}});assert.equal(response.statusCode,200,response.body);
  response=await gateway.inject({method:'POST',url:'/internal/v1/downloads',headers:{'x-internal-key':key},payload:{kind:'download'}});assert.equal(response.statusCode,204,response.body);
  assert.equal((await app.inject({url:'/v1/mail-account',headers:{'x-service-key':key}})).statusCode,404);
  assert.equal((await messaging.inject({url:'/v1/profile',headers:{'x-service-key':key}})).statusCode,404);
  assert.equal((await auth.inject('/v1/me')).statusCode,401);
});
test('private messaging owns encrypted accounts and uncertain mail remains counted across the gateway',async()=>{
  const post=randomUUID(),job=randomUUID();
  await cluster.db.query("INSERT INTO hiring_posts(id,post_text,fingerprint) VALUES($1,'Apply to hr@example.com','split-mail')",[post]);
  await cluster.db.query("INSERT INTO post_contacts(post_id,type,value) VALUES($1,'email','hr@example.com')",[post]);
  await cluster.db.query("INSERT INTO opportunities(id,source,source_ref,title,field,work_mode,level,employment_type,enrich_version,posted_at,apply_methods) VALUES($1,'post',$2,'Developer','software','remote','mid','full_time','fixture',now(),ARRAY['email'])",[job,post]);
  const account=await call('/v1/mail-account',{method:'PUT',payload:{address:'split@example.com',sender_name:'Test',app_password:'abcd efgh ijkl mnop'}});
  assert.equal(account.statusCode,200,account.body);assert.equal(account.json().email.secret,undefined);
  const options={method:'POST',payload:{job_id:job,method:'email',letter:'I am interested in this role.'}};
  const first=await call('/v1/applications',options);assert.equal(first.statusCode,201,first.body);assert.equal(first.json().status,'queued');
  assert.equal((await call('/v1/applications',options)).statusCode,201);assert.equal(smtpCalls,1);
  assert.equal((await call('/v1/me',{method:'DELETE'})).statusCode,409);
  // Test-only trusted reconciliation lets the later lifecycle test proceed.
  await cluster.db.query("UPDATE applications SET status='sent' WHERE opportunity_id=$1",[job]);
});
test('service roles cannot read unrelated secrets or perform identity lifecycle/DDL',async()=>{
  for(const role of ['auth','app','fetching','data'])await assert.rejects(pools[role].query('SELECT secret FROM public.mail_accounts'),{code:'42501'});
  for(const role of ['auth','fetching','data'])await assert.rejects(pools[role].query('SELECT bytes FROM public.user_cv_files'),{code:'42501'});
  for(const role of ['app','messaging','fetching','data'])await assert.rejects(pools[role].query('SELECT public.delete_user_data($1)',[randomUUID()]),{code:'42501'});
  for(const pool of Object.values(pools))await assert.rejects(pool.query('CREATE TABLE public.forbidden_service_ddl(id int)'),{code:'42501'});
});
test('fetching and data processes hand off durably, deduplicate and stay private',async()=>{
  assert.equal((await fetching.inject({method:'POST',url:'/internal/v1/fetch',payload:{provider:'demo'}})).statusCode,401);
  const fetch=()=>fetching.inject({method:'POST',url:'/internal/v1/fetch',headers:{'x-service-key':key},payload:{provider:'demo'}});
  const first=await fetch();assert.equal(first.statusCode,202,first.body);
  const duplicate=await fetch();assert.equal(first.json().id,duplicate.json().id);
  const result=await data.inject({method:'POST',url:'/internal/v1/data/process',headers:{'x-service-key':key},payload:{}});
  assert.equal(result.statusCode,200,result.body);assert.equal(result.json().accepted,1);assert.equal(result.json().skipped,1);
  assert.deepEqual(await processBatch(pools.data),{processed:false});
  assert.equal((await pools.data.query('SELECT * FROM public.provider_records')).rows[0].content.title,'Engineer');
  assert.equal((await gateway.inject('/internal/v1/data/status')).statusCode,404);
  const maintenance=await data.inject({method:'POST',url:'/internal/v1/data/maintenance',headers:{'x-service-key':key},payload:{}});assert.equal(maintenance.statusCode,200,maintenance.body);assert.equal(maintenance.json().dry_run,true);
  assert.equal((await data.inject({method:'POST',url:'/internal/v1/data/maintenance',headers:{'x-service-key':key},payload:{apply:true}})).statusCode,409);
});
test('account deletion stays SQL-first through the identity service',async()=>{
  const deletion=await call('/v1/me',{method:'DELETE'});assert.equal(deletion.statusCode,204,deletion.body);
  const response=await call('/v1/profile',{method:'PUT',payload:{headline:'must not return'}});
  assert.equal(response.statusCode,401,response.body);
  assert.equal((await cluster.db.query("SELECT count(*)::int AS count FROM public.app_users WHERE firebase_uid='split-user'")).rows[0].count,0);
});
