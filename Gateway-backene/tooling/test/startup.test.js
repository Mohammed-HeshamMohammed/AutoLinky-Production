import { test } from 'node:test';
import assert from 'node:assert/strict';
import { backendFolders } from '../support/layout.js';
import { checkMigrations,migrationFiles } from '../../../Data-baceknd/database/migrate.js';

const runtimes=await Promise.all(Object.values(backendFolders).map(async folder=>({folder,...await import(`../../../${folder}/lib/runtime.js`)})));
const clients=await Promise.all(['Auth-backend','App-backend','Notify-backend','Fetching-backend'].map(async folder=>({folder,...await import(`../../../${folder}/lib/api.js`)})));
const secret='private-fixture-secret-never-log';

test('readiness rejects invalid service origins without making a request or retaining credentials',async()=>{
  for(const {schemaReadiness} of clients)for(const url of [undefined,'not a URL',`https://user:${secret}@data.invalid`,`https://data.invalid/?key=${secret}`,'https://data.invalid/path','file:///private.json']){
    await assert.rejects(schemaReadiness(url,{fetcher:()=>{assert.fail('Invalid URL was fetched');}}),error=>{
      assert.equal(error.code,'DATA_SERVICE_NOT_READY');assert.equal(error.reason,'invalid_url');
      assert(!JSON.stringify(error).includes(secret));assert(!error.message.includes(secret));return true;
    });
  }
});

test('readiness preserves safe DNS, connection, timeout and TLS reasons without retrying',async()=>{
  const coded=code=>Object.assign(new Error(secret),{code});
  const cases=[
    [new TypeError(secret,{cause:coded('ENOTFOUND')}),'dns','ENOTFOUND'],
    [new TypeError(secret,{cause:coded('EAI_AGAIN')}),'dns','EAI_AGAIN'],
    [new TypeError(secret,{cause:new AggregateError([coded('ECONNREFUSED')],secret)}),'connection_refused','ECONNREFUSED'],
    [new DOMException(secret,'TimeoutError'),'timeout',undefined],
    [new TypeError(secret,{cause:coded('UND_ERR_CONNECT_TIMEOUT')}),'timeout','UND_ERR_CONNECT_TIMEOUT'],
    [new TypeError(secret,{cause:coded('CERT_HAS_EXPIRED')}),'tls','CERT_HAS_EXPIRED'],
    [new TypeError(secret,{cause:coded('ERR_TLS_CERT_ALTNAME_INVALID')}),'tls','ERR_TLS_CERT_ALTNAME_INVALID'],
    [new TypeError(secret,{cause:coded(secret)}),'network',undefined],
  ];
  for(const {schemaReadiness} of clients)for(const [cause,reason,code] of cases){
    let calls=0;
    await assert.rejects(schemaReadiness('https://data.fixture.invalid',{fetcher:async()=>{calls++;throw cause;}}),error=>{
      assert.equal(error.code,'DATA_SERVICE_NOT_READY');assert.equal(error.reason,reason);assert.equal(error.causeCode,code);
      assert(!JSON.stringify(error).includes(secret));assert(!error.message.includes(secret));return true;
    });
    assert.equal(calls,1);
  }
});

test('readiness reports upstream status while discarding response bodies',async()=>{
  for(const {schemaReadiness} of clients)for(const status of [401,502,503]){
    const response=new Response(secret,{status});
    await assert.rejects(schemaReadiness('https://data.fixture.invalid',{fetcher:async()=>response}),error=>{
      assert.equal(error.reason,'http_status');assert.equal(error.upstreamStatus,status);
      assert(!JSON.stringify(error).includes(secret));return true;
    });
    assert.equal(response.bodyUsed,true);
  }
});

test('ready dependencies retain the existing health URL and redirect policy',async()=>{
  for(const {schemaReadiness} of clients){
    let calls=0;
    await schemaReadiness('https://data.fixture.invalid',{fetcher:async(url,options)=>{
      calls++;assert.equal(url,'https://data.fixture.invalid/health/ready');assert.equal(options.redirect,'error');
      assert(options.signal instanceof AbortSignal);assert.equal(options.headers,undefined);return Response.json({status:'ok'});
    }});
    assert.equal(calls,1);
  }
});

test('all owned startup loggers allowlist diagnostics and exclude messages, URLs and credentials',()=>{
  for(const {startupDiagnostic} of runtimes){
    const error=Object.assign(new Error(`postgresql://user:${secret}@db.invalid/db`),{code:'DATA_SERVICE_NOT_READY',reason:'http_status',upstreamStatus:502,causeCode:'ENOTFOUND',body:secret,url:secret});
    const fields=startupDiagnostic(error);
    assert.deepEqual(fields,{type:'Error',code:'DATA_SERVICE_NOT_READY',detail:fields.detail,dependency:'data',setting:'DATA_SERVICE_URL',reason:'http_status',upstream_status:502,cause_code:'ENOTFOUND'});
    assert(fields.detail.includes('DATA_SERVICE_URL'));assert(!JSON.stringify(fields).includes(secret));
    const unknown=startupDiagnostic({name:secret,code:secret,message:secret,stack:secret,cause:{code:secret}});
    assert.equal(unknown.type,'Error');assert(!JSON.stringify(unknown).includes(secret));
    const injected=startupDiagnostic({...error,reason:secret,upstreamStatus:secret,causeCode:secret});
    assert.equal(injected.reason,'unavailable');assert(!JSON.stringify(injected).includes(secret));
    assert(startupDiagnostic({code:'28P01',message:secret}).detail.includes('PostgreSQL authentication failed'));
  }
});

test('startup failure closes the app, exits unsuccessfully and logs only safe dependency diagnostics',async()=>{
  const originalExitCode=process.exitCode;
  for(const {serve} of runtimes){
    const originalSignals=Object.fromEntries(['SIGINT','SIGTERM'].map(signal=>[signal,new Set(process.listeners(signal))]));
    const error=Object.assign(new Error(secret),{code:'DATA_SERVICE_NOT_READY',reason:'dns',causeCode:'ENOTFOUND'});
    const logs=[];let closed=0;
    try{
      await serve({listen:async()=>{throw error;},close:async()=>{closed++;},log:{error:(fields,message)=>logs.push({fields,message})}},{host:'127.0.0.1',port:0});
      assert.equal(closed,1);assert.equal(process.exitCode,1);assert.equal(logs.length,1);
      assert.equal(logs[0].fields.reason,'dns');assert.equal(logs[0].fields.cause_code,'ENOTFOUND');
      assert.equal(logs[0].message,'Service startup failed');assert(!JSON.stringify(logs).includes(secret));
    }finally{
      for(const [signal,listeners] of Object.entries(originalSignals))for(const listener of process.listeners(signal))if(!listeners.has(listener))process.removeListener(signal,listener);
      process.exitCode=originalExitCode;
    }
  }
});

test('startup diagnostics recognize missing schemas, driver timeouts and nested connection errors safely',()=>{
  const coded=code=>Object.assign(new Error(secret),{code});
  const cyclic=new Error(secret);cyclic.cause=cyclic;
  const cases=[
    [coded('3F000'),'3F000'],
    [coded('ENOENT'),'ENOENT'],
    [new Error('Connection terminated due to connection timeout',{cause:coded('ECONNRESET')}),'ETIMEDOUT'],
    [new Error('timeout exceeded when trying to connect'),'ETIMEDOUT'],
    [new Error(secret,{cause:new AggregateError([coded('ECONNREFUSED')],secret)}),'ECONNREFUSED'],
    [cyclic,undefined],
    [coded(secret),undefined],
  ];
  for(const {startupDiagnostic} of runtimes)for(const [error,code] of cases){
    const fields=startupDiagnostic(error);
    assert.equal(fields.code,code);assert(!JSON.stringify(fields).includes(secret));
    if(code==='3F000')assert(fields.detail.includes('schema'));
  }
});

test('Data schema readiness identifies mismatches without exposing catalog values or changing the database',async()=>{
  const migrations=(await migrationFiles()).map(({name,checksum})=>({name,checksum}));
  const ready={actual:'fixture-fingerprint',expected:'fixture-fingerprint',migrations};
  const cases=[
    [[], 'missing_state'],
    [[{...ready,actual:secret}], 'catalog_drift'],
    [[{...ready,migrations:null}], 'migration_count'],
    [[{...ready,migrations:migrations.slice(1)}], 'migration_count'],
    [[{...ready,migrations:migrations.map((row,i)=>i?row:{...row,checksum:secret})}], 'migration_mismatch'],
  ];
  for(const [rows,reason] of cases){
    let queries=0;
    await assert.rejects(checkMigrations({query:async sql=>{queries++;assert.equal(sql,'SELECT * FROM migrator.runtime_schema_status()');return {rows};}}),error=>{
      assert.equal(error.code,'DATABASE_SCHEMA_NOT_READY');assert.equal(error.reason,reason);
      assert(!JSON.stringify(error).includes(secret));assert(!error.message.includes(secret));
      for(const {startupDiagnostic} of runtimes){
        const fields=startupDiagnostic(error);
        assert.equal(fields.code,'DATABASE_SCHEMA_NOT_READY');assert.equal(fields.dependency,'database');
        assert.equal(fields.setting,'PG_DATABASE_URL');assert.equal(fields.reason,reason);
        assert(!JSON.stringify(fields).includes(secret));
      }
      return true;
    });
    assert.equal(queries,1);
  }
  await checkMigrations({query:async()=>({rows:[ready]})});
  const failure=Object.assign(new Error(secret),{code:'28P01'});
  await assert.rejects(checkMigrations({query:async()=>{throw failure;}}),error=>error===failure);
  for(const {startupDiagnostic} of runtimes){
    const fields=startupDiagnostic({code:'DATABASE_SCHEMA_NOT_READY',reason:secret,message:secret});
    assert.equal(fields.reason,'unavailable');assert(!JSON.stringify(fields).includes(secret));
  }
});
