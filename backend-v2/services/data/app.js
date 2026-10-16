import { loadConfig } from '../../shared/config.js';
import { createDatabase } from '../../shared/db/client.js';
import { createOperations } from '../../shared/http/operations.js';
import { HttpError } from '../../shared/http/errors.js';
import { processBatch } from './src/process.js';

export function buildData({env=process.env,db,logger=false}={}){
  const config=loadConfig(env,{identity:false});db||=createDatabase(config);
  const app=createOperations({role:'data',db,key:env.SERVICE_KEY,logger});
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
  return app;
}
