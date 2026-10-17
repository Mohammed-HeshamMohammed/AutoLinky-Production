import {test} from 'node:test';
import assert from 'node:assert/strict';
import {buildData} from '../../../Data-baceknd/app.js';
import {migrationFiles} from '../../../Data-baceknd/database/migrate.js';
import {initializationConfig,initializeDatabase} from '../../../Data-baceknd/database/initialize.js';
import {HttpError} from '../../../Data-baceknd/lib/http/errors.js';

const key='data-configuration-fixture-'.repeat(3),secret='private-configuration-fixture-never-log';
test('Data console uses its PG_DATABASE_URL pool, ignores a stale console URL and closes the shared pool once',async()=>{
  const migrations=(await migrationFiles()).map(({name,checksum})=>({name,checksum}));
  let closed=0;const queries=[];
  const db={query:async sql=>{queries.push(sql);return {rows:sql.includes('runtime_schema_status')?[{actual:'ready',expected:'ready',migrations}]:[{id:'1',action:'fixture'}]};},end:async()=>{closed++;}};
  const app=buildData({env:{SERVICE_KEY:key,DATA_IDENTITY_KEY:key,DATA_INGESTION_KEY:key,PG_DATABASE_URL:'postgresql://autolinky_data:fixture@user-db.invalid/postgres',CONSOLE_DATABASE_URL:`postgresql://user:${secret}@wrong-console.invalid/wrong`},db,adminProvider:{authenticate:async request=>{if(!request.headers['x-admin-session'])throw new HttpError(401,'invalid_login');return {id:'fixture',role:'owner'};}}});
  try{
    const denied=await app.inject({url:'/admin/api/audit',headers:{'x-service-key':key}});assert.equal(denied.statusCode,401);
    const audit=await app.inject({url:'/admin/api/audit',headers:{'x-service-key':key,'x-admin-session':'fixture'}});assert.equal(audit.statusCode,200,audit.body);
    assert.equal(audit.json().items[0].action,'fixture');assert(queries.some(sql=>sql.includes('FROM public.admin_log')));
    assert(!JSON.stringify(audit.json()).includes(secret));
  }finally{await app.close();}
  assert.equal(closed,1);
});

test('automatic initialization validates private configuration without retaining raw invalid values',async()=>{
  const base={PG_DATABASE_URL:'postgresql://autolinky_data:private@user-db.invalid/postgres'};
  assert.equal(initializationConfig({...base}).passwords.autolinky_data,'private');
  const cases=[{PG_DATABASE_URL:secret},{...base,PG_MIGRATOR_URL:`postgresql://postgres:${secret}@other-db.invalid/postgres`},{...base,AUTO_SCHEMA_MIGRATIONS:secret},{...base,DATABASE_RUNTIME_PASSWORDS_JSON:secret},{...base,DATABASE_RUNTIME_PASSWORDS_JSON:JSON.stringify({postgres:secret})}];
  for(const env of cases)assert.throws(()=>initializationConfig(env),error=>{assert.equal(error.code,'SCHEMA_BOOTSTRAP_CONFIG');assert(!error.message.includes(secret));assert(!JSON.stringify(error).includes(secret));return true;});
  await initializeDatabase({AUTO_SCHEMA_MIGRATIONS:'false'},{clientFactory:()=>assert.fail('Disabled initialization connected to PostgreSQL')});
});
