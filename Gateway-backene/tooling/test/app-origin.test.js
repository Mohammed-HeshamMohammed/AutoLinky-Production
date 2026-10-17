import {test} from 'node:test';
import assert from 'node:assert/strict';
import {gatewayTargets,buildGateway} from '../../src/app.js';
import {createAppClient} from '../../../Notify-backend/src/app-client.js';
import {buildData} from '../../../Data-baceknd/app.js';
import {migrationFiles} from '../../../Data-baceknd/database/migrate.js';

const origin='https://appapi.auto-linky.com',key='app-origin-private-fixture-'.repeat(3);
const env={APP_SERVICE_URL:'https://retired-app.fixture.invalid',...Object.fromEntries(['auth','messaging','data'].flatMap(name=>[[name.toUpperCase()+'_SERVICE_URL',`https://${name}.fixture.invalid`],[name.toUpperCase()+'_SERVICE_KEY',key]])),APP_SERVICE_KEY:key};

test('Gateway ignores stale App URL environments and routes CV/profile/jobs to the fixed App origin',async()=>{
  const targets=gatewayTargets(env);
  assert.equal(targets.app.url,origin);
  assert.equal(gatewayTargets({...env,APP_SERVICE_URL:undefined}).app.url,origin);
  assert.throws(()=>gatewayTargets({...env,APP_SERVICE_KEY:''}),/APP_SERVICE_KEY is required/);
  const calls=[];
  const app=buildGateway({targets,fetcher:async(url,options)=>{calls.push(url);if(!url.endsWith('/health/ready'))assert.equal(options.headers['x-service-key'],key);return Response.json({ok:true});}});
  try{
    for(const path of ['/v1/profile','/v1/cv','/v1/jobs?limit=20'])assert.equal((await app.inject(path)).statusCode,200);
    assert.deepEqual(calls,['/v1/profile','/v1/cv','/v1/jobs?limit=20'].map(path=>origin+path));
    const ready=await app.inject('/health/ready');assert.equal(ready.statusCode,200);assert.equal(ready.json().services.app,'ready');
  }finally{await app.close();}
});

test('Notify ignores a stale App URL but retains its private read key and explicit local injection',async()=>{
  const previous=process.env.APP_SERVICE_URL;process.env.APP_SERVICE_URL='https://retired-app.fixture.invalid';
  const calls=[],fetcher=async(url,options)=>{calls.push(url);assert.equal(options.headers['x-service-key'],key);return Response.json({});};
  try{
    await createAppClient({key,fetcher}).snapshot('fixture-user');
    await createAppClient({url:'http://127.0.0.1:12345',key,fetcher}).job('fixture-job');
    assert.deepEqual(calls,[origin+'/internal/v1/messaging/snapshot','http://127.0.0.1:12345/internal/v1/messaging/job']);
  }finally{if(previous===undefined)delete process.env.APP_SERVICE_URL;else process.env.APP_SERVICE_URL=previous;}
});

test('Data admin health uses the fixed App origin, preserves admin authorization and accepts explicit local injection',async t=>{
  const calls=[];t.mock.method(globalThis,'fetch',async url=>{calls.push(String(url));return Response.json({status:'ok'});});
  const migrations=(await migrationFiles()).map(({name,checksum})=>({name,checksum}));
  for(const appURL of [undefined,'http://127.0.0.1:12345']){
    const db={query:async sql=>({rows:sql.includes('runtime_schema_status')?[{actual:'ready',expected:'ready',migrations}]:[]})};
    const app=buildData({env:{SERVICE_KEY:key,DATA_IDENTITY_KEY:key,DATA_INGESTION_KEY:key,APP_SERVICE_URL:env.APP_SERVICE_URL},db,appURL,adminProvider:{authenticate:async()=>({id:'fixture',role:'owner'})}});
    try{
      assert.equal((await app.inject('/admin/api/health')).statusCode,401);
      const response=await app.inject({url:'/admin/api/health',headers:{'x-service-key':key}});
      assert.equal(response.statusCode,200,response.body);assert.equal(response.json().services.find(service=>service.name==='app').ready,true);
      assert.equal(calls.at(-1),(appURL||origin)+'/health/ready');
    }finally{await app.close();}
  }
  assert.equal(calls.length,2);
});

test('local Gateway injection retains its chosen loopback port instead of contacting production App',async()=>{
  const targets=gatewayTargets(env,{appURL:'http://127.0.0.1:12345'}),calls=[];
  const app=buildGateway({targets,fetcher:async url=>{calls.push(url);return Response.json({ok:true});}});
  try{assert.equal((await app.inject('/v1/profile')).statusCode,200);assert.deepEqual(calls,['http://127.0.0.1:12345/v1/profile']);}
  finally{await app.close();}
});
