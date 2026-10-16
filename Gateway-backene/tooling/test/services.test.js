import { test } from 'node:test';
import assert from 'node:assert/strict';
import { buildGateway,destination } from '../../src/app.js';
import { remoteAuthentication } from '../support/runtime.js';
import { normalizeRecord } from '../../../Data-baceknd/src/process.js';
import { fetchProvider } from '../../../Fetching-backend/src/fetch.js';
import { createAppClient } from '../../../Notify-backend/src/app-client.js';
import { createIdentityDataClient } from '../../../Auth-backend/src/data-client.js';

const targets=Object.fromEntries(['auth','app','messaging','data'].map(name=>[name,{url:`http://${name}.internal`,key:name.repeat(40)}]));
test('gateway routes contracts, forwards exact CV bytes and replaces untrusted service headers',async()=>{
  const calls=[];
  const app=buildGateway({targets,origins:['https://auto-linky.com'],fetcher:async(url,options)=>{calls.push({url,...options});return new Response(JSON.stringify({ok:true}),{status:201,headers:{'content-type':'application/json','x-request-id':'owned'}});}});
  try{
    const bytes=Buffer.from([0,255,1,2,3]);
    const result=await app.inject({method:'POST',url:'/v1/cv?name=resume.pdf',payload:bytes,headers:{'content-type':'application/pdf',authorization:'Bearer user','x-service-key':'forged','x-user-id':'forged'}});
    assert.equal(result.statusCode,201);assert.equal(result.headers['x-request-id'],'owned');
    assert.equal(calls[0].url,'http://app.internal/v1/cv?name=resume.pdf');assert.deepEqual(calls[0].body,bytes);
    assert.equal(calls[0].headers['x-service-key'],targets.app.key);assert.equal(calls[0].headers['x-user-id'],undefined);
    assert.equal((await app.inject({method:'POST',url:'/internal/v1/session',payload:{method:'DELETE'}})).statusCode,404);
    const previous=calls.length;
    for(const path of ['/admin/api/users/%2e%2e/%2e%2e/%2e%2e/internal/v1/data/process','/admin/api/users/a%2f..%2f..%2finternal','/v1/jobs/%5c..%5cinternal'])assert.equal((await app.inject({method:'POST',url:path,payload:{}})).statusCode,404);
    assert.equal(calls.length,previous);
    assert.equal((await app.inject('/v1/profile?x=1')).statusCode,201);
    assert.equal((await app.inject({url:'/v1/me',headers:{origin:'https://untrusted.invalid'}})).statusCode,403);
    assert.equal((await app.inject({method:'OPTIONS',url:'/v1/me',headers:{origin:'https://auto-linky.com','access-control-request-method':'GET'}})).statusCode,204);
    const admin=await app.inject({url:'/admin/api/overview',headers:{authorization:'Bearer app-user','x-admin-session':'mfa-session','x-admin-elevation':'mfa-elevation','x-service-key':'forged'}});assert.equal(admin.statusCode,201);
    assert.equal(calls.at(-1).headers.authorization,'Bearer app-user');assert.equal(calls.at(-1).headers['x-admin-session'],'mfa-session');assert.equal(calls.at(-1).headers['x-admin-elevation'],'mfa-elevation');assert.equal(calls.at(-1).headers['x-service-key'],targets.data.key);
    for(const [path,expected] of [['/v1/me','auth'],['/v1/mail-account','messaging'],['/v1/applications/email-preview','messaging'],['/v1/device/activity','messaging'],['/v1/jobs','app'],['/internal/v1/data/process',null]])assert.equal(destination(path),expected);
  }finally{await app.close();}
});
test('a failed messaging dispatch is never automatically retried',async()=>{
  let calls=0;
  const app=buildGateway({targets,fetcher:async()=>{calls++;throw Error('connection lost after dispatch');}});
  try{assert.equal((await app.inject({method:'POST',url:'/v1/applications',payload:{job_id:'id',method:'email'}})).statusCode,503);assert.equal(calls,1);}
  finally{await app.close();}
});
test('authentication RPC carries the original mutation policy and fails closed',async()=>{
  let body;
  const auth=remoteAuthentication({url:'http://auth.internal',key:'k'.repeat(40),fetcher:async(url,options)=>{body=JSON.parse(options.body);return Response.json({id:'private-user',status:'active'});}});
  const request={method:'DELETE',headers:{authorization:'Bearer valid'}};await auth.authenticate(request);
  assert.deepEqual(body,{method:'DELETE'});assert.equal(request.user.id,'private-user');
  await assert.rejects(auth.authenticate({method:'GET',headers:{}}),{status:401});
  const broken=remoteAuthentication({url:'http://auth.internal',key:'k'.repeat(40),fetcher:async()=>{throw Error();}});
  await assert.rejects(broken.authenticate(request),{status:503});
  const limited=remoteAuthentication({url:'http://auth.internal',key:'k'.repeat(40),fetcher:async()=>Response.json({detail:'Too many requests'},{status:429,headers:{'retry-after':'30'}})});
  await assert.rejects(limited.authenticate(request),error=>error.status===429&&error.headers['retry-after']==='30');
});
test('configured fetching bounds inputs and normalization remains deterministic',async()=>{
  assert.equal(normalizeRecord({title:'  Engineer\u0000 ',id:123}).value.title,'Engineer');
  assert.deepEqual(normalizeRecord({title:'Engineer'}),normalizeRecord({title:'Engineer'}));
  assert.equal(normalizeRecord({description:'no title'}),null);
  assert.equal(normalizeRecord({title:'x',url:'javascript:alert(1)'}).value.url,null);
  const data={stage:async()=>({id:'batch',status:'pending'})};
  assert.equal((await fetchProvider({provider:'demo',providers:{demo:{url:'https://provider.invalid/jobs'}},data,fetcher:async()=>Response.json([{id:'1',title:'Engineer'}])})).id,'batch');
  await assert.rejects(fetchProvider({provider:'arbitrary-url',providers:{},data}),{status:422});
  await assert.rejects(fetchProvider({provider:'demo',providers:{demo:{url:'http://provider.invalid/jobs'}},data}),{status:503});
  await assert.rejects(fetchProvider({provider:'demo',providers:{demo:{url:'https://provider.invalid/jobs'}},data,fetcher:async()=>Response.json(Array(501).fill({title:'x'}))}),{status:502});
});
test('private domain API failures deny the operation and never automatically retry a mutation',async()=>{
  let calls=0;
  const client=createAppClient({url:'http://app.internal',key:'read-key-'.repeat(5),fetcher:async()=>{calls++;throw Error('unavailable');}});
  await assert.rejects(client.snapshot('fixture-user'),{status:503});assert.equal(calls,1);
  calls=0;
  const identity=createIdentityDataClient({url:'http://data.internal',key:'identity-'.repeat(5),fetcher:async()=>{calls++;throw Error('response lost after dispatch');}});
  await assert.rejects(identity.deleteUser('fixture-user'),{status:503});assert.equal(calls,1);
});
