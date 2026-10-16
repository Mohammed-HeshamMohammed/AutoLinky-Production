import { before,after,test } from 'node:test';
import assert from 'node:assert/strict';
import pg from 'pg';
import { randomUUID } from 'node:crypto';
import { testDatabase } from '../helpers/database.js';
import { letterService,cleanBody } from '../../services/messaging/src/ai/cover-letters.js';
import { senderTick,inHours } from '../../services/messaging/src/auto-apply.js';
import { loadConfig } from '../../shared/config.js';
let cluster,db,id,job;
const config=loadConfig();
before(async()=>{
  cluster=await testDatabase();db=cluster.db;id=randomUUID();job={id:randomUUID(),source:'linkedin_job',source_ref:'missing-fixture',title:'Developer',company:'Example',snippet:'Developer role'};
  await db.query("INSERT INTO app_users(id,email) VALUES($1,'fixture@example.com')",[id]);
});
after(async()=>{await cluster?.close();});
test('cover letters reuse the same CV hash, collapse concurrent AI calls, redact contacts and revalidate a new CV',async()=>{
  let calls=0;const body='I developed software and worked with the tools described in my resume. '.repeat(10).trim();
  const ai={ask:async request=>{calls++;assert.equal(request.maxTokens,900);assert.equal(request.temperature,0.2);assert.ok(!request.messages[1].content.includes('private@example.com'));await new Promise(resolve=>setTimeout(resolve,10));return {data:'Dear Hiring Manager,\n\n'+body+'\n\nSincerely,\nName',tokens:100};}};
  const getLetter=letterService({db,config,ai}),cv={text:'Developer private@example.com experience',sha256:'a'.repeat(64)};
  const results=await Promise.all([getLetter(id,job,cv),getLetter(id,job,cv),getLetter(id,job,cv)]);assert.equal(calls,1);assert.equal(results[0],body);
  assert.equal(await getLetter(id,job,cv),body);assert.equal(calls,1);
  await getLetter(id,job,{...cv,sha256:'b'.repeat(64)});assert.equal(calls,2);
  assert.throws(()=>cleanBody('Dear Hiring Manager,\nUse [Company] here.\nSincerely,'));
});
test('conditional due-user claims stop two sender processes from taking one turn',async()=>{
  await db.query('INSERT INTO auto_apply(user_id,enabled,min_match) VALUES($1,true,70)',[id]);
  let sends=0;const now=new Date(Date.now()+1000),mail={send:async()=>{sends++;await new Promise(resolve=>setTimeout(resolve,30));return {status:'sent'};}};
  const args={db,config,mail,now,pickCandidates:async()=>[job]};
  const results=await Promise.all([senderTick(args),senderTick(args)]);assert.equal(sends,1);assert.equal(results.reduce((a,b)=>a+b,0),1);
  const next=(await db.query('SELECT next_send_at FROM auto_apply WHERE user_id=$1',[id])).rows[0].next_send_at;assert.ok(+next>=+now+3*60000);
  assert.equal(inHours(23,'22-6'),true);assert.equal(inHours(12,'22-6'),false);
});
test('sender observes cancellation before taking a due user and does not retry uncertain application rows',async()=>{
  await db.query('UPDATE auto_apply SET next_send_at=now() WHERE user_id=$1',[id]);
  const stop=new AbortController();stop.abort();let called=false;
  assert.equal(await senderTick({db,config,mail:{send:async()=>{called=true;}},signal:stop.signal}),0);assert.equal(called,false);
});
