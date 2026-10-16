import { before,after,test } from 'node:test';
import assert from 'node:assert/strict';
import pg from 'pg';
import { randomUUID,createHash } from 'node:crypto';
import { testDatabase } from '../helpers/database.js';
import { buildApp } from '../helpers/application.js';
import { loadConfig } from '../../shared/config.js';

let cluster,app,db,pool;
const tokens={a:{uid:'opaque-A',email:'a@example.com',email_verified:true},b:{uid:'opaque-B',email:'b@example.com',email_verified:true}};
const identity={verify:async token=>{if(!tokens[token])throw Object.assign(Error(),{code:'auth/invalid-id-token'});return tokens[token];},deleteUser:async()=>{}};
const request=(url,options={})=>app.inject({url,headers:{authorization:'Bearer a',...options.headers},...options});
before(async()=>{
  cluster=await testDatabase();db=cluster.db;
  await db.query(`ALTER ROLE autolinky_api LOGIN PASSWORD '${cluster.password}'`);
  pool=new pg.Pool({host:'127.0.0.1',port:cluster.port,user:'autolinky_api',password:cluster.password,database:'postgres',max:4});
  app=buildApp({db:pool,identity,extractor:async bytes=>({file_type:'pdf',size:bytes.length,pages:1,text:'Developer\nJavaScript\n'+'Experience building web applications. '.repeat(10),sha256:createHash('sha256').update(bytes).digest('hex'),links:[]}),config:loadConfig({INTERNAL_DOWNLOADS_KEY:'x'.repeat(40),CORS_ALLOWED_ORIGINS:'https://app.example.com'})});
  await app.ready();
  await db.query("INSERT INTO job_fields(slug,name_en,name_ar) VALUES('software','Software','برمجة') ON CONFLICT DO NOTHING");
  await db.query("INSERT INTO job_roles(slug,field,name_en,name_ar) VALUES('developer','software','Developer','مطور')");
  await db.query("INSERT INTO skills(slug,name,skill_group) VALUES('javascript','JavaScript','technology') ON CONFLICT(slug) DO UPDATE SET skill_group='technology'");
});
after(async()=>{await app?.close();await cluster?.close();});

test('public health, readiness and consistent authorization errors',async()=>{
  assert.deepEqual((await app.inject('/health')).json(),{status:'ok',version:'0.5.10',notice:null});
  assert.equal((await app.inject('/health/ready')).statusCode,200);
  const missing=await app.inject('/v1/me');assert.equal(missing.statusCode,401);assert.equal(missing.headers['www-authenticate'],'Bearer');
  const bad=await request('/v1/me',{headers:{authorization:'Bearer invalid'}});assert.equal(bad.statusCode,401);
  const me=(await request('/v1/me')).json();assert.equal(me.email,'a@example.com');assert.match(me.user_id,/^[a-f0-9-]{36}$/);assert.notEqual(me.user_id,tokens.a.uid);
});
test('profile partial updates preserve fields and isolate the two users',async()=>{
  let response=await request('/v1/profile',{method:'PUT',payload:{target_roles:['developer'],skills:['javascript'],countries:['Egypt'],search_titles:['Network Engineer','network engineer']}});
  assert.equal(response.statusCode,200,response.body);assert.deepEqual(response.json().countries,['EG']);assert.deepEqual(response.json().languages,['en','ar']);assert.equal(response.json().search_titles.length,1);
  response=await request('/v1/profile',{method:'PUT',payload:{headline:'Engineer'}});assert.equal(response.json().skills[0],'javascript');
  response=await request('/v1/profile',{method:'PUT',payload:{skills:['unknown_skill']}});assert.equal(response.statusCode,422);assert.deepEqual(response.json().detail,{code:'unknown_values',unknown:{skills:['unknown_skill']}});
  assert.equal((await request('/v1/profile',{headers:{authorization:'Bearer b'}})).statusCode,404);
  assert.equal((await request('/v1/profile',{method:'PUT',payload:{user_id:randomUUID()}})).statusCode,422);
  const status=await request('/v1/profile/search-status');assert.equal(status.statusCode,200,status.body);assert.equal(status.json().titles[0].title,'network engineer');
  assert.equal((await request('/v1/profile/search-now',{method:'POST'})).statusCode,200);
});
test('catalog DTO and CORS use exact allowed origins',async()=>{
  assert.equal((await request('/v1/taxonomy')).json().skills.find(s=>s.slug==='javascript').group,'technology');
  assert.equal((await app.inject({url:'/health',headers:{origin:'https://app.example.com'}})).headers['access-control-allow-origin'],'https://app.example.com');
  assert.equal((await app.inject({url:'/health',headers:{origin:'https://evil.example.com'}})).statusCode,403);
  const preflight=await app.inject({method:'OPTIONS',url:'/v1/me',headers:{origin:'https://app.example.com','access-control-request-method':'GET','access-control-request-headers':'authorization,x-autolinky-client-version,x-request-id'}});
  assert.equal(preflight.statusCode,204);
  assert.match(preflight.headers['access-control-allow-headers'],/X-Autolinky-Client-Version/i);
  const response=await app.inject({url:'/health',headers:{origin:'https://app.example.com'}});
  assert.match(response.headers['access-control-expose-headers'],/Retry-After/i);
  assert.match(response.headers['access-control-expose-headers'],/X-Request-ID/i);
});
test('feed cursors retain PostgreSQL microseconds and private application overlays stay per user',async()=>{
  const id=randomUUID();
  await db.query(`INSERT INTO opportunities(id,source,source_ref,title,field,work_mode,level,employment_type,enrich_version,posted_at) VALUES($1,'linkedin_job','fixture','JavaScript Developer','software','remote','mid','full_time','fixture',date_trunc('second',now())+interval '0.123456 seconds')`,[id]);
  const a=(await request('/v1/me')).json().user_id;
  await db.query("INSERT INTO applications(user_id,opportunity_id,method,status,job) VALUES($1,$2,'email','sending','{}')",[a,id]);
  const feed=await request('/v1/jobs?limit=1');assert.equal(feed.statusCode,200,feed.body);assert.equal(feed.json().items[0].application.status,'queued');
  const cursor=feed.json().next_cursor;assert.match(JSON.parse(Buffer.from(cursor,'base64url').toString()).t,/123456/);
  assert.equal((await request(`/v1/jobs?limit=1&cursor=${cursor}`)).json().items.length,0);
  const other=await request('/v1/jobs',{headers:{authorization:'Bearer b'}});assert.equal(other.json().items[0].application,null);
  const matches=await request('/v1/jobs/matched');assert.equal(matches.statusCode,200,matches.body);
  assert.equal((await request('/v1/jobs?cursor=bad')).statusCode,400);
  assert.equal((await request('/v1/jobs?field=bad%27')).statusCode,422);
  assert.equal((await request('/v1/jobs/matched/new?since=bad')).statusCode,422);
});
test('internal download DTO matches the legacy website stats and rejects untrusted callers',async()=>{
  const payload={kind:'in_app_prompt',device:'android',in_app:'linkedin',source:null,tag:'v1',version:'1.0',visitor:'hash',is_bot:false,country:'EG',referrer:null,user_agent:'LinkedInApp'};
  const url='/internal/v1/downloads';
  assert.equal((await app.inject({url,method:'POST',payload})).statusCode,401);
  const reply=await app.inject({url,method:'POST',payload,headers:{'x-internal-key':'x'.repeat(40)}});assert.equal(reply.statusCode,204,reply.body);
});
test('CV bytes, metadata and profile are atomic; deletion preserves profile and hides private data',async()=>{
  const payload=Buffer.from('%PDF-fixture'),headers={authorization:'Bearer a','content-type':'application/pdf'};
  const response=await request('/v1/cv?name=..%2FResume.pdf',{method:'POST',payload,headers});
  assert.equal(response.statusCode,200,response.body);assert.equal(response.json().cv.file_name,'Resume.pdf');assert.equal(response.json().cv.analysis,'partial');assert.equal(response.json().profile.skills[0],'javascript');
  const id=(await request('/v1/me')).json().user_id;
  const stored=(await db.query('SELECT c.sha256,f.bytes,f.sha256 file_hash FROM user_cvs c JOIN user_cv_files f USING(user_id) WHERE user_id=$1',[id])).rows[0];
  assert.deepEqual(stored.bytes,payload);assert.equal(stored.sha256,stored.file_hash);
  const metadata=await request('/v1/cv');assert.equal(metadata.json().text,undefined);assert.equal(metadata.json().bytes,undefined);
  assert.equal((await request('/v1/cv',{headers:{authorization:'Bearer b'}})).statusCode,404);
  assert.equal((await request('/v1/cv/reanalyze',{method:'POST'})).statusCode,503);
  assert.equal((await request('/v1/cv',{method:'DELETE'})).statusCode,204);
  assert.equal((await db.query('SELECT FROM user_cv_files WHERE user_id=$1',[id])).rowCount,0);
  assert.equal((await request('/v1/profile')).statusCode,200);
});
test('deleted Firebase identity cannot be recreated with a still-valid cached token',async()=>{
  const header={authorization:'Bearer b'};
  const id=(await request('/v1/me',{headers:header})).json().user_id;
  assert.equal((await request('/v1/me',{method:'DELETE',headers:header})).statusCode,204);
  assert.equal((await request('/v1/me',{headers:header})).statusCode,401);
  assert.equal((await db.query('SELECT FROM app_users WHERE id=$1',[id])).rowCount,0);
});
