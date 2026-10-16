import { before,after,test } from 'node:test';
import assert from 'node:assert/strict';
import pg from 'pg';
import { randomBytes,randomUUID,createHash } from 'node:crypto';
import { testDatabase } from '../helpers/database.js';
import { buildApp } from '../../src/app.js';
import { loadConfig } from '../../src/config.js';
import { MailError } from '../../src/email/gmail.js';

let cluster,app,db,user,job,calls=0,mode='ok';
const key=randomBytes(32).toString('base64url');
const headers={authorization:'Bearer a'};
const inject=(url,options={})=>app.inject({url,headers,...options});
before(async()=>{
  cluster=await testDatabase();db=cluster.db;
  await db.query(`ALTER ROLE autolinky_api LOGIN PASSWORD '${cluster.password}'`);
  const pool=new pg.Pool({host:'127.0.0.1',port:cluster.port,user:'autolinky_api',password:cluster.password,database:'postgres'});
  app=buildApp({db:pool,identity:{verify:async()=>({uid:'mail-test',email:'test@gmail.com',email_verified:true})},config:loadConfig({MAIL_SECRET_KEY:key}),
    transport:{verify:async()=>{},send:async()=>{calls++;if(mode==='unknown')throw new MailError('busy',{uncertain:true});await new Promise(resolve=>setTimeout(resolve,20));return {messageId:'fake@test'};}}});
  await app.ready();user=(await inject('/v1/me')).json().user_id;
  const post=randomUUID();job=randomUUID();
  await db.query("INSERT INTO hiring_posts(id,post_text,fingerprint) VALUES($1,'Hiring a developer. Apply via hr@example.com','fixture')",[post]);
  await db.query("INSERT INTO post_contacts(post_id,type,value) VALUES($1,'email','hr@example.com')",[post]);
  await db.query("INSERT INTO opportunities(id,source,source_ref,title,field,work_mode,level,employment_type,enrich_version,posted_at,apply_methods) VALUES($1,'post',$2,'Developer','software','remote','mid','full_time','fixture',now(),ARRAY['email','link'])",[job,post]);
  const bytes=Buffer.from('%PDF-fixture'),sha=createHash('sha256').update(bytes).digest('hex');
  await db.query("INSERT INTO user_cvs(user_id,file_name,file_type,file_size,sha256,text,analysis) VALUES($1,'CV.pdf','pdf',$2,$3,'Developer experience','partial')",[user,bytes.length,sha]);
  await db.query('INSERT INTO user_cv_files(user_id,bytes,sha256) VALUES($1,$2,$3)',[user,bytes,sha]);
});
after(async()=>{await app?.close();await cluster?.close();});
test('mail settings return no secret and round-trip the Gmail connection and quotas',async()=>{
  assert.equal((await inject('/v1/auto-apply')).json().free_limit,20);
  let response=await inject('/v1/mail-account',{method:'PUT',payload:{address:'other@gmail.com',sender_name:'Test',app_password:'abcd efgh ijkl mnop'}});assert.equal(response.statusCode,422);
  response=await inject('/v1/mail-account',{method:'PUT',payload:{address:'test@gmail.com',sender_name:'Test',app_password:'abcd efgh ijkl mnop'}});assert.equal(response.statusCode,200,response.body);assert.equal(response.json().email.status,'ok');assert.equal(response.json().email.secret,undefined);
  response=await inject('/v1/auto-apply',{method:'PUT',payload:{enabled:true,daily_limit:10}});assert.equal(response.statusCode,200,response.body);assert.equal(response.json().enabled,true);assert.equal(response.json().problem,'sender_offline');
});
test('two concurrent sends reserve once; unknown SMTP outcomes stay counted and cannot be retried/deleted',async()=>{
  const options={method:'POST',payload:{job_id:job,method:'email'}};
  const responses=await Promise.all([inject('/v1/applications',options),inject('/v1/applications',options)]);
  for(const response of responses)assert.equal(response.statusCode,201,response.body);assert.equal(calls,1);
  assert.equal((await inject(`/v1/applications/${job}`,{method:'DELETE'})).statusCode,409);
  assert.equal((await inject('/v1/auto-apply')).json().free_used,1);
  await db.query('DELETE FROM applications WHERE user_id=$1',[user]);mode='unknown';
  const response=await inject('/v1/applications',options);assert.equal(response.json().status,'queued');
  await inject('/v1/applications',options);assert.equal(calls,2);
  assert.equal((await db.query('SELECT status FROM applications WHERE user_id=$1',[user])).rows[0].status,'sending');
  assert.equal((await inject('/v1/me',{method:'DELETE'})).statusCode,409);
});
test('device tokens store only a hash and use fresh status and dedicated auth',async()=>{
  const result=await inject('/v1/devices',{method:'POST',payload:{platform:'android'}});assert.equal(result.statusCode,201,result.body);
  const {token,device_id}=result.json();const row=(await db.query('SELECT * FROM app_devices WHERE id=$1',[device_id])).rows[0];assert.notEqual(row.token_hash,token);assert.equal(row.token_hash,createHash('sha256').update(token).digest('hex'));
  const url='/v1/device/activity?after='+encodeURIComponent(new Date().toISOString());
  const activity=await app.inject({url,headers:{authorization:`Device ${token}`}});assert.equal(activity.statusCode,200,activity.body);
  assert.equal((await app.inject({url,headers})).statusCode,401);
  await db.query("UPDATE app_users SET status='blocked' WHERE id=$1",[user]);
  assert.equal((await app.inject({url,headers:{authorization:`Device ${token}`}})).statusCode,403);
});
