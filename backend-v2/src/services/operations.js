import Fastify,{ LogController } from 'fastify';
import { createDatabase } from '../db/client.js';
import { loadConfig } from '../config.js';
import { checkMigrations } from '../../database/migrate.js';
import { errorHandler,HttpError } from '../http/errors.js';
import { requireServiceKey } from './runtime.js';
import { fetchProvider,processBatch } from './ingestion.js';

export function buildOperations({role,env=process.env,db,fetcher=fetch,logger=false}={}){
  if(!['fetching','data'].includes(role))throw Error('Unknown operations service');
  const config=loadConfig(env,{identity:false});db||=createDatabase(config);
  const app=Fastify({logger,bodyLimit:16384,requestTimeout:30000,logController:new LogController({disableRequestLogging:true})});
  app.setErrorHandler(errorHandler);requireServiceKey(app,env.SERVICE_KEY);
  app.addHook('onReady',()=>checkMigrations(db));
  app.addHook('onClose',()=>db.end?.());
  app.get('/health',async()=>({status:'ok',service:role}));
  app.get('/health/ready',async(request,reply)=>{
    try{await checkMigrations(db);return {status:'ok',service:role};}catch{return reply.code(503).send({status:'degraded',service:role});}
  });
  if(role==='fetching'){
    const providers=JSON.parse(env.FETCH_PROVIDERS_JSON||'{}');
    if(!providers||Array.isArray(providers)||typeof providers!=='object')throw Error('Invalid provider configuration');
    for(const [name,provider] of Object.entries(providers))if(!/^[a-z0-9_-]{1,80}$/.test(name)||!provider?.url)throw Error('Invalid provider configuration');
    let active=0;
    app.post('/internal/v1/fetch',{schema:{body:{type:'object',additionalProperties:false,required:['provider'],properties:{provider:{type:'string',pattern:'^[a-z0-9_-]{1,80}$'}}}}},async(request,reply)=>{
      if(!config.collectorEnabled)throw new HttpError(409,'Collection is disabled');
      if(active>=2)throw new HttpError(429,'Provider capacity reached',{'Retry-After':'5'});
      active++;
      try{return reply.code(202).send(await fetchProvider({provider:request.body.provider,providers,db,fetcher}));}finally{active--;}
    });
  }else{
    app.get('/internal/v1/data/status',async()=>({batches:(await db.query('SELECT status,count(*)::integer AS count FROM public.ingestion_batches GROUP BY status')).rows,records:(await db.query('SELECT count(*)::integer AS count FROM public.provider_records')).rows[0].count}));
    app.post('/internal/v1/data/process',{schema:{body:{type:'object',additionalProperties:false,properties:{}}}},async()=>{
      if(env.DATA_PROCESSING_ENABLED!=='true')throw new HttpError(409,'Data processing is disabled');
      return processBatch(db);
    });
    app.post('/internal/v1/data/maintenance',{schema:{body:{type:'object',additionalProperties:false,properties:{apply:{type:'boolean',default:false}}}}},async request=>{
      const pending=(await db.query("SELECT count(*)::integer AS count FROM public.ingestion_batches WHERE status='processed' AND processed_at<now()-interval '30 days'")).rows[0].count;
      if(!request.body.apply)return {dry_run:true,expired_batches:pending};
      if(env.DATA_MAINTENANCE_ENABLED!=='true')throw new HttpError(409,'Data maintenance is disabled');
      const result=await db.query("DELETE FROM public.ingestion_batches WHERE status='processed' AND processed_at<now()-interval '30 days'");
      await db.query('ANALYZE public.ingestion_batches');await db.query('ANALYZE public.provider_records');
      return {dry_run:false,deleted_batches:result.rowCount};
    });
  }
  return app;
}
