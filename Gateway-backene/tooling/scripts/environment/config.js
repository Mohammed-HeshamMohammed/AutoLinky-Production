import { mkdir,readFile,writeFile,access } from 'node:fs/promises';
import { randomBytes } from 'node:crypto';
import { fileURLToPath } from 'node:url';
import { resolve,sep } from 'node:path';
import { parseEnv } from 'node:util';
export const backend=fileURLToPath(new URL('../../',import.meta.url));
export const production=resolve(backend,'../..');
export const runtime=resolve(backend,'.runtime/environment');
export const settingsFile=resolve(runtime,'settings.json');
export const controlFile=resolve(runtime,'control.json');
export const ports={database:56432,api:4100,auth:4101,app:4102,messaging:4103,fetching:4104,data:4105,extractor:4001,website:8080,client:8081};
export async function exists(path){try{await access(path);return true;}catch{return false;}}
export async function readSettings(){
  const settings=JSON.parse(await readFile(settingsFile,'utf8'));
  const target=resolve(settings.databaseDir);
  if(target!==resolve(runtime,'postgres') || !target.startsWith(resolve(backend)+sep) || settings.host!=='127.0.0.1')throw Error('Local environment configuration is outside its isolated workspace');
  return settings;
}
const envFile=values=>Object.entries(values).map(([key,value])=>`${key}=${JSON.stringify(String(value))}`).join('\n')+'\n';
export function databaseUrl(settings,role){return `postgresql://${role}:${settings.passwords[role]}@127.0.0.1:${settings.ports.database}/autolinky_dev`;}
export async function setup(){
  await mkdir(runtime,{recursive:true});
  let settings;
  if(await exists(settingsFile))settings=await readSettings();
  else {
    settings={version:1,host:'127.0.0.1',ports,databaseDir:resolve(runtime,'postgres'),
      passwords:Object.fromEntries(['postgres','autolinky_migrator','autolinky_api','autolinky_ops'].map(role=>[role,randomBytes(24).toString('hex')])),
      statsKey:randomBytes(32).toString('hex'),statsSalt:randomBytes(32).toString('hex'),extractorKey:randomBytes(32).toString('hex'),
      mailKey:randomBytes(32).toString('base64url')+'=',controlKey:randomBytes(32).toString('hex')};
    await writeFile(settingsFile,JSON.stringify(settings,null,2)+'\n',{flag:'wx',mode:0o600});
  }
  // Upgrade the local profile without rotating any existing credentials.
  settings.version=2;settings.ports={...ports,...settings.ports};settings.serviceKeys||={};
  for(const name of ['auth','app','messaging','fetching','data']){
    settings.passwords['autolinky_'+name]||=randomBytes(24).toString('hex');
    settings.serviceKeys[name]||=randomBytes(32).toString('hex');
  }
  for(const name of ['appRead','notifyRead','ingestion','identityData'])settings.serviceKeys[name]||=randomBytes(32).toString('hex');
  await writeFile(settingsFile,JSON.stringify(settings,null,2)+'\n',{mode:0o600});
  const backendEnv={NODE_ENV:'development',HOST:settings.host,PORT:settings.ports.api,PG_DATABASE_URL:databaseUrl(settings,'autolinky_api'),
    PG_MIGRATOR_URL:databaseUrl(settings,'autolinky_migrator'),PG_OPS_URL:databaseUrl(settings,'autolinky_ops'),FIREBASE_PROJECT_ID:'auto-linky',
    GOOGLE_APPLICATION_CREDENTIALS:'',CORS_ALLOWED_ORIGINS:[`http://localhost:${settings.ports.website}`,`http://127.0.0.1:${settings.ports.website}`,`http://localhost:${settings.ports.client}`,`http://127.0.0.1:${settings.ports.client}`,'http://localhost:5173'].join(','),
    INTERNAL_DOWNLOADS_KEY:settings.statsKey,CV_EXTRACTOR_URL:`http://127.0.0.1:${settings.ports.extractor}`,CV_EXTRACTOR_KEY:settings.extractorKey,
    MAIL_SECRET_KEY:settings.mailKey,SENDER_ENABLED:'false',COLLECTOR_ENABLED:'false'};
  const websiteEnv={NODE_ENV:'development',HOST:settings.host,PORT:settings.ports.website,
    VITE_SITE_URL:`http://localhost:${settings.ports.website}`,VITE_WHATSAPP_NUMBER:'201060933358',RELEASES_REPO:'AMamdouh3/Autolinky-releases',
    API_BASE_URL:`http://127.0.0.1:${settings.ports.api}`,STATS_KEY:settings.statsKey,STATS_SALT:settings.statsSalt};
  for(const [name,values] of [['backend.env',backendEnv],['website.env',websiteEnv]]) {
    const file=resolve(runtime,name);if(!await exists(file))await writeFile(file,envFile(values),{flag:'wx',mode:0o600});
  }
  const previous=parseEnv(await readFile(resolve(runtime,'backend.env'),'utf8'));
  const select=names=>Object.fromEntries(names.filter(name=>previous[name]!==undefined).map(name=>[name,previous[name]]));
  const common={NODE_ENV:'development',HOST:settings.host,DATA_SERVICE_URL:`http://127.0.0.1:${settings.ports.data}`,CORS_ALLOWED_ORIGINS:previous.CORS_ALLOWED_ORIGINS||backendEnv.CORS_ALLOWED_ORIGINS,...select(['RATE_LIMIT_PER_MINUTE','PG_POOL_MAX','PG_STATEMENT_TIMEOUT_MS'])};
  const auth={...common,PORT:settings.ports.auth,PG_DATABASE_URL:databaseUrl(settings,'autolinky_auth'),SERVICE_KEY:settings.serviceKeys.auth,
    DATA_IDENTITY_KEY:settings.serviceKeys.identityData,
    FIREBASE_PROJECT_ID:previous.FIREBASE_PROJECT_ID||'auto-linky',GOOGLE_APPLICATION_CREDENTIALS:previous.GOOGLE_APPLICATION_CREDENTIALS||''};
  const authClient={AUTH_SERVICE_URL:`http://127.0.0.1:${settings.ports.auth}`,AUTH_SERVICE_KEY:settings.serviceKeys.auth};
  const gateway={...common,PORT:settings.ports.api,...authClient,...select(Object.keys(previous).filter(name=>name.startsWith('SERVICE_NOTICE'))),
    APP_SERVICE_URL:`http://127.0.0.1:${settings.ports.app}`,APP_SERVICE_KEY:settings.serviceKeys.app,
    MESSAGING_SERVICE_URL:`http://127.0.0.1:${settings.ports.messaging}`,MESSAGING_SERVICE_KEY:settings.serviceKeys.messaging};
  const app={...common,...authClient,PORT:settings.ports.app,PG_DATABASE_URL:databaseUrl(settings,'autolinky_app'),SERVICE_KEY:settings.serviceKeys.app,APP_READ_KEY:settings.serviceKeys.appRead,
    NOTIFY_SERVICE_URL:`http://127.0.0.1:${settings.ports.messaging}`,NOTIFY_READ_KEY:settings.serviceKeys.notifyRead,
    INTERNAL_DOWNLOADS_KEY:settings.statsKey,CV_EXTRACTOR_URL:backendEnv.CV_EXTRACTOR_URL,CV_EXTRACTOR_KEY:settings.extractorKey,
    AI_API_KEY:previous.AI_API_KEY||'',AI_BASE_URL:previous.AI_BASE_URL||'https://openrouter.ai/api/v1',...select(['CV_AI_MODEL'])};
  const messaging={...common,...authClient,PORT:settings.ports.messaging,PG_DATABASE_URL:databaseUrl(settings,'autolinky_messaging'),SERVICE_KEY:settings.serviceKeys.messaging,NOTIFY_READ_KEY:settings.serviceKeys.notifyRead,
    APP_SERVICE_URL:`http://127.0.0.1:${settings.ports.app}`,APP_READ_KEY:settings.serviceKeys.appRead,
    MAIL_SECRET_KEY:previous.MAIL_SECRET_KEY||settings.mailKey,SENDER_ENABLED:'false',AI_API_KEY:previous.AI_API_KEY||'',AI_BASE_URL:previous.AI_BASE_URL||'https://openrouter.ai/api/v1',...select(['LETTER_AI_MODEL','FREE_EMAILS','EMAIL_DAILY_LIMIT','AUTO_APPLY_HOURS','SENDER_TIMEZONE','UPGRADE_URL','UPGRADE_MESSAGE'])};
  for(const [name,values] of Object.entries({gateway,auth,app,messaging,
    fetching:{...common,PORT:settings.ports.fetching,SERVICE_KEY:settings.serviceKeys.fetching,DATA_INGESTION_KEY:settings.serviceKeys.ingestion,COLLECTOR_ENABLED:'false',FETCH_PROVIDERS_JSON:'{}'},
    data:{...common,PORT:settings.ports.data,PG_DATABASE_URL:databaseUrl(settings,'autolinky_data'),SERVICE_KEY:settings.serviceKeys.data,DATA_IDENTITY_KEY:settings.serviceKeys.identityData,DATA_INGESTION_KEY:settings.serviceKeys.ingestion,DATA_PROCESSING_ENABLED:'false',DATA_MAINTENANCE_ENABLED:'false'}})){
    const target=resolve(runtime,`${name}.env`);
    const saved=await exists(target)?parseEnv(await readFile(target,'utf8')):{};
    if(name==='fetching')delete saved.PG_DATABASE_URL;
    await writeFile(target,envFile({SERVICE_NAME:name,...values,...saved}),{mode:0o600});
  }
  const clientEnv=resolve(runtime,'flutter-web.json');
  if(!await exists(clientEnv)) {
    const webFile=resolve(production,'mobile apps/shared/env/web.json');
    const web=JSON.parse(await readFile(await exists(webFile)?webFile:resolve(production,'mobile apps/shared/firebase-project.json'),'utf8'));
    web.API_BASE_URL=`http://localhost:${settings.ports.api}`;
    // Local HTTP development can exercise Google/UI now. Native email links
    // remain off until an approved HTTPS continuation domain is configured.
    web.EMAIL_SIGN_IN='false';web.APPLE_SIGN_IN='false';
    await writeFile(clientEnv,JSON.stringify(web,null,2)+'\n',{flag:'wx',mode:0o600});
  }
  return settings;
}
