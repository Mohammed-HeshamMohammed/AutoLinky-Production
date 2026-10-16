import { createHash } from 'node:crypto';
export const ingestionPath='/internal/v1/ingestion';
export function registerIngestion(app,db){
  app.post(ingestionPath,{schema:{body:{type:'object',additionalProperties:false,required:['provider','items'],properties:{provider:{type:'string',pattern:'^[a-z0-9_-]{1,80}$'},items:{type:'array',maxItems:500,items:{}}}}}},async(request,reply)=>{
    const {provider,items}=request.body,payload=JSON.stringify(items),hash=createHash('sha256').update(payload).digest('hex');
    const {rows}=await db.query(`INSERT INTO public.ingestion_batches(provider,payload_hash,payload) VALUES($1,$2,$3::jsonb)
      ON CONFLICT(provider,payload_hash) DO UPDATE SET provider=EXCLUDED.provider RETURNING id,status,created_at`,[provider,hash,payload]);
    return reply.code(202).send(rows[0]);
  });
}
