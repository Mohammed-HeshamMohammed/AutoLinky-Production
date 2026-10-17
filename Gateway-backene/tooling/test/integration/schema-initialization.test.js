import {before,after,test} from 'node:test';
import assert from 'node:assert/strict';
import pg from 'pg';
import {testDatabase} from '../helpers/database.js';
import {initializeDatabase} from '../../../../Data-baceknd/database/initialize.js';
import {checkMigrations,migrationFiles,migrate} from '../../../../Data-baceknd/database/migrate.js';

let cluster,runtimeDb;
const name='autolinky_startup_fixture';
const env=()=>({NODE_ENV:'production',AUTO_SCHEMA_MIGRATIONS:'true',PG_DATABASE_URL:`postgresql://autolinky_data:${cluster.password}@127.0.0.1:${cluster.port}/${name}`,PG_MIGRATOR_URL:`postgresql://postgres:${cluster.password}@127.0.0.1:${cluster.port}/${name}`,DATABASE_RUNTIME_PASSWORDS_JSON:JSON.stringify(Object.fromEntries(['autolinky_auth','autolinky_app','autolinky_messaging'].map(role=>[role,cluster.password])))});
before(async()=>{
  cluster=await testDatabase();await cluster.db.query('CREATE DATABASE '+name);
  runtimeDb=new pg.Pool({connectionString:env().PG_DATABASE_URL,max:2,connectionTimeoutMillis:5000});
});
after(async()=>{await runtimeDb?.end();await cluster?.close();});

test('two replicas initialize the same empty existing database and make the runtime role ready',async()=>{
  await Promise.all([initializeDatabase(env(),{runtimeDb}),initializeDatabase(env(),{runtimeDb})]);
  await checkMigrations(runtimeDb);
  const expected=(await migrationFiles()).length;
  const status=(await runtimeDb.query('SELECT migrations FROM migrator.runtime_schema_status()')).rows[0];assert.equal(status.migrations.length,expected);
  assert.equal((await runtimeDb.query('SELECT count(*)::integer count FROM public.app_users')).rows[0].count,0);
  await assert.rejects(runtimeDb.query('SELECT totp_secret FROM public.admin_accounts'),{code:'42501'});
  await assert.rejects(runtimeDb.query('SELECT bytes FROM public.user_cv_files'),{code:'42501'});
});

test('an unchanged restart performs no setup work and retains user records',async()=>{
  const admin=new pg.Client({connectionString:env().PG_MIGRATOR_URL});await admin.connect();
  try{await admin.query("INSERT INTO public.app_users(email,firebase_uid) VALUES('startup-fixture@example.invalid','startup-fixture')");}finally{await admin.end();}
  await initializeDatabase(env(),{runtimeDb,clientFactory:()=>assert.fail('Ready schema opened a privileged connection')});
  assert.equal((await runtimeDb.query("SELECT count(id)::integer count FROM public.app_users WHERE email='startup-fixture@example.invalid'")).rows[0].count,1);
});

test('automatic upgrades apply a pending known migration and preserve existing users',async()=>{
  const admin=new pg.Client({connectionString:env().PG_MIGRATOR_URL});await admin.connect();
  try{await admin.query("DELETE FROM migrator.schema_migrations WHERE name='0014_shared_console_connection.sql'");}finally{await admin.end();}
  await initializeDatabase(env(),{runtimeDb});await checkMigrations(runtimeDb);
  assert.equal((await runtimeDb.query("SELECT count(id)::integer count FROM public.app_users WHERE email='startup-fixture@example.invalid'")).rows[0].count,1);
});

test('unreviewed catalog changes are reported without resetting the database',async()=>{
  const admin=new pg.Client({connectionString:env().PG_MIGRATOR_URL});await admin.connect();
  try{
    await admin.query('CREATE TABLE public.startup_drift_fixture(id integer)');
    await assert.rejects(initializeDatabase(env(),{runtimeDb}),error=>error.code==='DATABASE_SCHEMA_NOT_READY'&&error.reason==='catalog_drift');
    assert.equal((await admin.query("SELECT count(*)::integer count FROM public.app_users WHERE email='startup-fixture@example.invalid'")).rows[0].count,1);
  }finally{await admin.query('DROP TABLE public.startup_drift_fixture');await admin.end();}
});

test('a failed automatic upgrade rolls back its DDL and ledger before a later retry',async()=>{
  const admin=new pg.Client({connectionString:env().PG_MIGRATOR_URL});await admin.connect();
  const failure=new Error('injected startup upgrade failure');
  try{
    await admin.query("DELETE FROM migrator.schema_migrations WHERE name='0014_shared_console_connection.sql'");
    await admin.query('SET ROLE autolinky_migrator');
    await assert.rejects(migrate({query:async(sql,values)=>{
      const result=await admin.query(sql,values);
      if(sql.startsWith('INSERT INTO migrator.schema_migrations')){await admin.query('CREATE TABLE public.rollback_fixture(id integer)');throw failure;}
      return result;
    }},{production:true,automatic:true}),error=>error===failure);
    assert.equal((await admin.query("SELECT to_regclass('public.rollback_fixture') missing")).rows[0].missing,null);
    assert.equal((await admin.query("SELECT count(*)::integer count FROM migrator.schema_migrations WHERE name='0014_shared_console_connection.sql'")).rows[0].count,0);
    await admin.query('RESET ROLE');
  }finally{await admin.end();}
  await initializeDatabase(env(),{runtimeDb});await checkMigrations(runtimeDb);
});

test('an unmanaged database retains its existing tables and records',async()=>{
  await cluster.db.query('CREATE DATABASE autolinky_unmanaged_fixture');
  const options={...env(),PG_DATABASE_URL:env().PG_DATABASE_URL.replace(name,'autolinky_unmanaged_fixture'),PG_MIGRATOR_URL:env().PG_MIGRATOR_URL.replace(name,'autolinky_unmanaged_fixture')};
  const admin=new pg.Client({connectionString:options.PG_MIGRATOR_URL});await admin.connect();
  try{
    await admin.query('CREATE TABLE public.existing_fixture(value text)');await admin.query("INSERT INTO public.existing_fixture VALUES('preserve this record')");
    await assert.rejects(initializeDatabase(options),error=>error.code==='SCHEMA_INIT_NOT_EMPTY');
    assert.equal((await admin.query('SELECT value FROM public.existing_fixture')).rows[0].value,'preserve this record');
  }finally{await admin.end();}
});
