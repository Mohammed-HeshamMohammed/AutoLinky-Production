import EmbeddedPostgres from 'embedded-postgres';
import pg from 'pg';
import { readFile,writeFile,open,unlink } from 'node:fs/promises';
import { spawn } from 'node:child_process';
import { parseEnv } from 'node:util';
import { resolve } from 'node:path';
import net from 'node:net';
import http from 'node:http';
import { timingSafeEqual } from 'node:crypto';
import { setTimeout as sleep } from 'node:timers/promises';
import { migrate } from '../../../../Data-baceknd/database/migrate.js';
import { setup,backend,production,runtime,controlFile,exists,databaseUrl } from './config.js';
import { backendFolders } from '../../support/layout.js';

const settings=await setup(),children=[],logs=[];
let stopping=false,clusterStarted=false,controlOwned=false,control,clientServer;
const cluster=new EmbeddedPostgres({databaseDir:settings.databaseDir,user:'postgres',password:settings.passwords.postgres,
  port:settings.ports.database,persistent:true,onLog:()=>{},onError:()=>{},
  postgresFlags:['-h','127.0.0.1'],initdbFlags:['--encoding=UTF8','--locale=C','--auth-host=scram-sha-256','--auth-local=scram-sha-256']});

async function stop(error) {
  if(stopping)return;stopping=true;
  if(error){console.error(error.message);process.exitCode=1;}
  if(control?.listening)control.close();
  if(clientServer?.listening){clientServer.close();clientServer.closeAllConnections();}
  await Promise.all(children.map(child=>new Promise(done=>{
    if(child.exitCode!==null||child.signalCode!==null){done();return;}
    const timer=setTimeout(()=>{child.kill('SIGKILL');done();},5000);
    child.once('exit',()=>{clearTimeout(timer);done();});child.kill('SIGTERM');
  })));
  if(clusterStarted)await cluster.stop().catch(()=>{process.exitCode=1;});
  for(const log of logs)await log.close().catch(()=>{});
  if(controlOwned)await unlink(controlFile).catch(()=>{});
  console.log('Isolated environment stopped. The local database and configuration are retained.');
}
for(const signal of ['SIGINT','SIGTERM'])process.once(signal,()=>{void stop();});
async function free(port) {
  const check=net.createServer();
  await new Promise((done,reject)=>{check.once('error',()=>reject(Error(`Local port ${port} is occupied; no existing process was stopped`)));check.listen(port,'127.0.0.1',done);});
  await new Promise(done=>check.close(done));
}
async function child(name,command,args,cwd,env) {
  if(stopping)throw Error('Environment startup was cancelled');
  const log=await open(resolve(runtime,`${name}.log`),'a');logs.push(log);
  const safe=Object.fromEntries(Object.entries(process.env).filter(([key])=>['PATH','SYSTEMROOT','WINDIR','COMSPEC','TEMP','TMP','USERPROFILE','APPDATA','LOCALAPPDATA','PROGRAMDATA','HOME'].includes(key.toUpperCase())));
  const childEnv={...safe,...env};delete childEnv.FIREBASE_AUTH_EMULATOR_HOST;
  const processChild=spawn(command,args,{cwd,env:childEnv,windowsHide:true,stdio:['ignore',log.fd,log.fd]});
  children.push(processChild);
  processChild.once('error',error=>{void stop(Error(`${name} could not start (${error.code||error.name}); see its environment log`));});
  processChild.once('exit',()=>{if(!stopping)void stop(Error(`${name} stopped; see ${resolve(runtime,name+'.log')}`));});
  await new Promise((done,reject)=>{processChild.once('spawn',done);processChild.once('error',reject);});
}
async function healthy(url) {
  const deadline=Date.now()+30000;
  while(Date.now()<deadline&&!stopping){
    try{const response=await fetch(url,{signal:AbortSignal.timeout(1500)});await response.arrayBuffer();if(response.ok)return;}
    catch{}await sleep(250);
  }
  throw Error(`Environment endpoint did not become ready: ${url}`);
}

try {
  for(const port of Object.values(settings.ports))await free(port);
  if(!await exists(resolve(settings.databaseDir,'PG_VERSION')))await cluster.initialise();
  await cluster.start();clusterStarted=true;
  const admin=new pg.Client({host:'127.0.0.1',port:settings.ports.database,user:'postgres',password:settings.passwords.postgres,database:'postgres'});
  await admin.connect();
  try{if(!(await admin.query("SELECT 1 FROM pg_database WHERE datname='autolinky_dev'")).rowCount)await admin.query('CREATE DATABASE autolinky_dev');}
  finally{await admin.end();}
  const bootstrap=new pg.Client({host:'127.0.0.1',port:settings.ports.database,user:'postgres',password:settings.passwords.postgres,database:'autolinky_dev'});
  await bootstrap.connect();
  try {
    // These objects belong exclusively to this task's local cluster.
    await bootstrap.query(await readFile(resolve(production,'Data-baceknd/database/bootstrap.sql'),'utf8'));
    for(const role of ['autolinky_migrator','autolinky_api','autolinky_ops','autolinky_auth','autolinky_app','autolinky_messaging','autolinky_fetching','autolinky_data']) {
      const {rows}=await bootstrap.query("SELECT format('ALTER ROLE %I LOGIN PASSWORD %L',$1::text,$2::text) AS sql",[role,settings.passwords[role]]);
      await bootstrap.query(rows[0].sql);
    }
  } finally{await bootstrap.end();}
  const migrator=new pg.Pool({host:'127.0.0.1',port:settings.ports.database,user:'autolinky_migrator',password:settings.passwords.autolinky_migrator,database:'autolinky_dev',max:1});
  try{await migrate(migrator);}finally{await migrator.end();}
  const websiteEnv=parseEnv(await readFile(resolve(runtime,'website.env'),'utf8'));
  for(const name of ['data','auth','app','messaging','fetching','gateway']){
    const values=parseEnv(await readFile(resolve(runtime,`${name}.env`),'utf8'));
    if(!['gateway','fetching'].includes(name)&&values.PG_DATABASE_URL!==databaseUrl(settings,'autolinky_'+name))throw Error(`The ${name} profile must use its isolated role/database`);
    // Do not leak an inherited superuser URL, Firebase credential, mail key or
    // provider token into another service's process.
    const entry=['gateway','messaging','data'].includes(name)?[resolve(backend,'scripts/environment/service.js'),name]:['index.js'];
    await child(name,process.execPath,entry,resolve(production,backendFolders[name]),{...values,NODE_ENV:'development',HOST:'127.0.0.1',SENDER_ENABLED:'false',COLLECTOR_ENABLED:'false',DATA_PROCESSING_ENABLED:'false',DATA_MAINTENANCE_ENABLED:'false'});
    if(name==='data')await healthy(`http://127.0.0.1:${settings.ports.data}/health/ready`);
  }
  await child('extractor',process.env.AUTOLINKY_PYTHON||'python',['-B',resolve(production,'App-backend/extractor/app.py')],resolve(production,'App-backend'),
    {HOST:'127.0.0.1',PORT:String(settings.ports.extractor),CV_EXTRACTOR_KEY:settings.extractorKey,PYTHONPATH:resolve(backend,'.runtime/python-deps')});
  await child('website',process.execPath,['scripts/dev-server.mjs'],resolve(production,'frontend'),{...websiteEnv,HOST:'127.0.0.1',PORT:String(settings.ports.website)});
  clientServer=http.createServer((request,response)=>{
    const url=new URL(request.url,'http://local.client');
    response.writeHead(302,{Location:`http://localhost:${settings.ports.website}/login/${url.search}`,'Cache-Control':'no-store'}).end();
  });
  await new Promise((done,reject)=>{clientServer.once('error',reject);clientServer.listen(settings.ports.client,'127.0.0.1',done);});
  control=http.createServer((request,response)=>{
    const actual=Buffer.from(request.headers['x-environment-key']||''),expected=Buffer.from(settings.controlKey);
    if(request.method!=='POST'||request.url!=='/stop'||actual.length!==expected.length||!timingSafeEqual(actual,expected)){response.writeHead(404).end();return;}
    response.writeHead(202).end();void stop();
  });
  await new Promise((done,reject)=>{control.once('error',reject);control.listen(0,'127.0.0.1',done);});
  if(await exists(controlFile)){
    const previous=JSON.parse(await readFile(controlFile,'utf8'));
    let stale=false;
    try{await fetch(`http://127.0.0.1:${previous.port}/health`,{signal:AbortSignal.timeout(1000)});}catch(error){stale=error.cause?.code==='ECONNREFUSED';}
    if(!stale)throw Error('An existing environment control endpoint must be stopped before starting');
    await unlink(controlFile);
  }
  await writeFile(controlFile,JSON.stringify({pid:process.pid,port:control.address().port})+'\n',{mode:0o600,flag:'wx'});controlOwned=true;
  await Promise.all([healthy(`http://127.0.0.1:${settings.ports.api}/health/ready`),healthy(`http://127.0.0.1:${settings.ports.extractor}/health`),
    healthy(`http://127.0.0.1:${settings.ports.website}/`),healthy(`http://127.0.0.1:${settings.ports.client}/`),
    ...['auth','app','messaging','fetching','data'].map(name=>healthy(`http://127.0.0.1:${settings.ports[name]}/health/ready`))]);
  console.log(`Environment ready. Client http://localhost:${settings.ports.client} | Website http://localhost:${settings.ports.website} | API http://localhost:${settings.ports.api}/health/ready`);
  console.log('Fresh local database only. Sender and collector are disabled. Stop with npm run env:stop.');
} catch(error){await stop(error);process.exit(1);}
