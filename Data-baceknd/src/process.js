import { createHash } from 'node:crypto';
import { transaction } from '../../backend-v2/shared/db/client.js';
const digest=value=>createHash('sha256').update(JSON.stringify(value)).digest('hex');
const text=(value,max)=>typeof value==='string'?value.normalize('NFKC').replace(/\p{C}/gu,' ').trim().slice(0,max):null;

export function normalizeRecord(raw){
  if(!raw||typeof raw!=='object'||Array.isArray(raw))return null;
  const title=text(raw.title,500);if(!title)return null;
  let url=null;
  try{const parsed=new URL(raw.url);if(['https:','http:'].includes(parsed.protocol)&&!parsed.username&&!parsed.password)url=parsed.href.slice(0,2000);}catch{}
  const externalId=['string','number'].includes(typeof raw.id)?text(String(raw.id),200):null;
  const value={external_id:externalId||null,title,url,company:text(raw.company,300),location:text(raw.location,500),description:text(raw.description,30000)};
  return {key:value.external_id||url||digest(value),value};
}

export async function processBatch(db){
  return transaction(db,async c=>{
    const batch=(await c.query("SELECT id,provider,payload FROM public.ingestion_batches WHERE status='pending' ORDER BY created_at,id FOR UPDATE SKIP LOCKED LIMIT 1")).rows[0];
    if(!batch)return {processed:false};
    let accepted=0,skipped=0;
    for(const raw of batch.payload){
      const record=normalizeRecord(raw);if(!record){skipped++;continue;}
      await c.query(`INSERT INTO public.provider_records(provider,record_key,content,content_hash,batch_id) VALUES($1,$2,$3,$4,$5)
        ON CONFLICT(provider,record_key) DO UPDATE SET content=EXCLUDED.content,content_hash=EXCLUDED.content_hash,batch_id=EXCLUDED.batch_id,updated_at=now()
        WHERE provider_records.content_hash<>EXCLUDED.content_hash`,[batch.provider,record.key,record.value,digest(record.value),batch.id]);
      accepted++;
    }
    await c.query("UPDATE public.ingestion_batches SET status='processed',processed_at=now(),accepted=$2,skipped=$3 WHERE id=$1",[batch.id,accepted,skipped]);
    return {processed:true,batch_id:batch.id,accepted,skipped};
  });
}
