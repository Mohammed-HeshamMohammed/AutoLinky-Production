import { readFile,writeFile } from 'node:fs/promises';
import { parseEnv } from 'node:util';
import { resolve } from 'node:path';
import pg from 'pg';
import { readSettings,runtime,production,exists,databaseUrl } from './config.js';
const settings=await readSettings();
const services=await Promise.all([
  ['api',`http://127.0.0.1:${settings.ports.api}/health/ready`],['extractor',`http://127.0.0.1:${settings.ports.extractor}/health`],
  ['website',`http://localhost:${settings.ports.website}/`],['client',`http://localhost:${settings.ports.client}/`],
  ...['auth','app','messaging','fetching','data'].map(name=>[name,`http://127.0.0.1:${settings.ports[name]}/health/ready`]),
].map(async([name,url])=>{
  try{const response=await fetch(url,{signal:AbortSignal.timeout(3000)});await response.arrayBuffer();return {name,url,status:response.ok?'ready':`HTTP ${response.status}`};}
  catch{return {name,url,status:'unreachable'};}
}));
const api=parseEnv(await readFile(resolve(runtime,'auth.env'),'utf8'));
const admin=api.GOOGLE_APPLICATION_CREDENTIALS;
let adminStatus='missing: set GOOGLE_APPLICATION_CREDENTIALS in the local auth.env';
if(admin&&await exists(admin)) {
  const credentials=JSON.parse(await readFile(admin,'utf8'));
  adminStatus=credentials.type==='service_account'&&credentials.project_id==='auto-linky'?'file configured; live access not tested':'project/type mismatch';
}
const android=JSON.parse(await readFile(resolve(production,'mobile apps/shared/env/android.json'),'utf8').catch(()=>'{}'));
const ios=JSON.parse(await readFile(resolve(production,'mobile apps/shared/env/ios.json'),'utf8').catch(()=>'{}'));
const report={checked_at:new Date().toISOString(),scope:'isolated local environment; no production import',services,
  firebase:{project:'auto-linky',admin:adminStatus,native_google_client_ids:android.GOOGLE_WEB_CLIENT_ID&&ios.GOOGLE_IOS_CLIENT_ID?'configured':'missing from supplied native files',
    localhost_authorized_domain:'must be verified in Firebase by the owner',local_email_links:'disabled until an approved HTTPS continuation URL is configured'},
  sender:'disabled',collector:'disabled'};
const db=new pg.Client({connectionString:databaseUrl(settings,'autolinky_api'),connectionTimeoutMillis:2000});
try {
  await db.connect();
  const {rows}=await db.query('SELECT (SELECT count(*)::integer FROM public.app_users) AS users,(SELECT count(*)::integer FROM public.user_cvs) AS cvs,(SELECT count(*)::integer FROM public.applications) AS applications');
  report.local_database={status:'ready',...rows[0]};
}catch{report.local_database={status:'unreachable'};}
finally{await db.end().catch(()=>{});}
await writeFile(resolve(runtime,'status.json'),JSON.stringify(report,null,2)+'\n');
console.log(JSON.stringify(report,null,2));
if(services.some(service=>service.status!=='ready')||report.local_database.status!=='ready')process.exitCode=1;
