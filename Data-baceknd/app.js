import { loadConfig } from './lib/config.js';
import { createDatabase } from './lib/db/client.js';
import { createOperations } from './lib/http/operations.js';
import { HttpError } from './lib/http/errors.js';
import { processBatch } from './src/process.js';
import { registerIngestion,ingestionPath } from './src/ingestion.js';
import { registerIdentityData,identityPath } from './src/identity.js';
import { registerConsole } from './src/console.js';
import { remoteAdmin } from './src/console-auth.js';
import { initializeDatabase } from './database/initialize.js';

export function buildData({env=process.env,db,consoleDb,adminProvider,appURL='https://appapi.auto-linky.com',logger=false}={}){
  const config=loadConfig(env,{identity:false});db||=createDatabase(config);
  const app=createOperations({role:'data',db,key:env.SERVICE_KEY,routeKeys:{[ingestionPath]:env.DATA_INGESTION_KEY,[identityPath]:env.DATA_IDENTITY_KEY,'/internal/v1/collection/control':env.DATA_INGESTION_KEY},bodyLimit:4*1024*1024+16384,logger,schemaSetup:env.PG_DATABASE_URL?()=>initializeDatabase(env,{runtimeDb:db}):undefined});
  registerIngestion(app,db);
  registerIdentityData(app,db);
  if(consoleDb||adminProvider||env.AUTH_ADMIN_KEY){
    consoleDb||=db;
    const auth=adminProvider||remoteAdmin({url:env.AUTH_SERVICE_URL,key:env.AUTH_ADMIN_KEY});
    registerConsole(app,{db:consoleDb,auth,serviceURLs:{auth:env.AUTH_SERVICE_URL,app:appURL,messaging:env.MESSAGING_SERVICE_URL,fetching:env.FETCHING_SERVICE_URL,data:env.DATA_SERVICE_URL},operationServices:{fetching:env.FETCHING_SERVICE_URL,fetchingKey:env.FETCHING_ADMIN_KEY,messaging:env.MESSAGING_SERVICE_URL,messagingKey:env.NOTIFY_ADMIN_KEY}});
    if(consoleDb!==db)app.addHook('onClose',()=>consoleDb.end?.());
  }
  app.get('/internal/v1/data/status',async()=>({batches:(await db.query('SELECT status,count(*)::integer AS count FROM public.ingestion_batches GROUP BY status')).rows,records:(await db.query('SELECT count(*)::integer AS count FROM public.provider_records')).rows[0].count}));
  app.post('/internal/v1/data/process',{schema:{body:{type:'object',additionalProperties:false,properties:{}}}},async()=>{
    if(env.DATA_PROCESSING_ENABLED!=='true')throw new HttpError(409,'Data processing is disabled');
    return processBatch(db);
  });
  app.post('/internal/v1/collection/control',{schema:{body:{type:'object',additionalProperties:false,properties:{}}}},async()=>({paused:(await db.query("SELECT paused FROM public.console_service_control WHERE service='collector'")).rows[0]?.paused!==false}));
  app.post('/internal/v1/data/maintenance',{schema:{body:{type:'object',additionalProperties:false,properties:{apply:{type:'boolean',default:false}}}}},async request=>{
    const pending=(await db.query("SELECT count(*)::integer AS count FROM public.ingestion_batches WHERE status='processed' AND processed_at<now()-interval '30 days'")).rows[0].count;
    if(!request.body.apply)return {dry_run:true,expired_batches:pending};
    if(env.DATA_MAINTENANCE_ENABLED!=='true')throw new HttpError(409,'Data maintenance is disabled');
    const result=await db.query("DELETE FROM public.ingestion_batches WHERE status='processed' AND processed_at<now()-interval '30 days'");
    await db.query('ANALYZE public.ingestion_batches');await db.query('ANALYZE public.provider_records');
    return {dry_run:false,deleted_batches:result.rowCount};
  });
  return app;
}
