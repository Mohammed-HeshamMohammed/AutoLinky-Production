import pg from 'pg';
import { readFile } from 'node:fs/promises';
import { checkMigrations,migrate } from './migrate.js';

const runtimeRoles=['autolinky_auth','autolinky_app','autolinky_messaging','autolinky_data'];
const invalid=()=>Object.assign(new Error('Check private schema setup configuration'),{code:'SCHEMA_BOOTSTRAP_CONFIG'});
function target(value){
  let url;try{url=new URL(value);}catch{throw invalid();}
  if(!['postgres:','postgresql:'].includes(url.protocol)||!url.hostname||!url.pathname||url.pathname==='/')throw invalid();
  return url;
}
export function initializationConfig(env){
  if(env.AUTO_SCHEMA_MIGRATIONS!==undefined&&!['true','false'].includes(env.AUTO_SCHEMA_MIGRATIONS))throw invalid();
  const enabled=env.AUTO_SCHEMA_MIGRATIONS!=='false';
  if(!enabled)return {enabled};
  const runtime=target(env.PG_DATABASE_URL),setup=target(env.PG_MIGRATOR_URL||env.PG_DATABASE_URL);
  if(runtime.hostname!==setup.hostname||(runtime.port||'5432')!==(setup.port||'5432')||runtime.pathname!==setup.pathname)throw invalid();
  let passwords;try{passwords=JSON.parse(env.DATABASE_RUNTIME_PASSWORDS_JSON||'{}');}catch{throw invalid();}
  if(!passwords||typeof passwords!=='object'||Array.isArray(passwords))throw invalid();
  for(const [role,password] of Object.entries(passwords))if(!runtimeRoles.includes(role)||typeof password!=='string'||!password.length)throw invalid();
  let runtimeUser,runtimePassword;try{runtimeUser=decodeURIComponent(runtime.username);runtimePassword=decodeURIComponent(runtime.password);}catch{throw invalid();}
  if(runtimeRoles.includes(runtimeUser)){
    const role=runtimeUser,password=runtimePassword;
    if(!password||passwords[role]!==undefined&&passwords[role]!==password)throw invalid();
    passwords[role]=password;
  }
  return {enabled,setupURL:setup.href,passwords,production:env.NODE_ENV==='production'};
}

export async function initializeDatabase(env,{runtimeDb,clientFactory=options=>new pg.Client(options)}={}){
  const config=initializationConfig(env);
  if(!config.enabled)return;
  // Current databases require no setup credential or DDL on restart.
  if(runtimeDb){try{await checkMigrations(runtimeDb);return;}catch{}}
  const client=clientFactory({connectionString:config.setupURL,connectionTimeoutMillis:5000,statement_timeout:60000,application_name:'autolinky-schema-setup'});
  let locked=false;
  try{
    await client.connect();
    await client.query('SELECT pg_advisory_lock(812761502)');locked=true;
    // Another replica may have finished while this one waited for the lock.
    try{await checkMigrations(client);return;}catch{}
    const managed=(await client.query("SELECT to_regclass('migrator.schema_migrations') IS NOT NULL AS managed")).rows[0].managed;
    if(!managed){
      const objects=await client.query("SELECT count(*)::integer count FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname='public' AND c.relkind IN ('r','p','v','m','S','f')");
      if(objects.rows[0].count)throw Object.assign(new Error('The database contains unmanaged application objects'),{code:'SCHEMA_INIT_NOT_EMPTY'});
      await client.query('BEGIN');
      try{
        await client.query(await readFile(new URL('./bootstrap.sql',import.meta.url),'utf8'));
        for(const [role,password] of Object.entries(config.passwords)){
          const {rows}=await client.query("SELECT format('ALTER ROLE %I LOGIN PASSWORD %L',$1::text,$2::text) sql",[role,password]);
          await client.query(rows[0].sql);
        }
        await client.query('COMMIT');
      }catch(error){await client.query('ROLLBACK');throw error;}
    }
    await client.query('SET ROLE autolinky_migrator');
    try{await migrate({query:(...args)=>client.query(...args)},{production:config.production,automatic:true});await checkMigrations(client);}
    finally{await client.query('RESET ROLE');}
  }finally{
    if(locked)await client.query('SELECT pg_advisory_unlock(812761502)').catch(()=>{});
    await client.end().catch(()=>{});
  }
}
