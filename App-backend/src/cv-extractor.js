import { createHash } from 'node:crypto';
import { HttpError,unavailable } from '../../backend-v2/shared/http/errors.js';
export async function extractCV(bytes,config,{fetcher=fetch}={}){
  if(!bytes.length)throw new HttpError(400,'cv_empty');
  if(bytes.length>config.cvMaxBytes)throw new HttpError(413,'cv_too_large');
  if(!bytes.subarray(0,5).equals(Buffer.from('%PDF-')) && !bytes.subarray(0,4).equals(Buffer.from([80,75,3,4])))throw new HttpError(415,'cv_bad_type');
  if(!config.cvExtractorUrl || config.cvExtractorKey.length<32)throw unavailable();
  let response;
  try{response=await fetcher(new URL('/extract',config.cvExtractorUrl),{method:'POST',redirect:'error',headers:{'X-Extractor-Key':config.cvExtractorKey,'Content-Type':'application/octet-stream'},body:bytes,signal:AbortSignal.timeout(15000)});}
  catch{throw unavailable();}
  const chunks=[];let size=0;
  for await(const chunk of response.body){size+=chunk.length;if(size>300000){await response.body.cancel().catch(()=>{});throw unavailable();}chunks.push(chunk);}
  let data;try{data=JSON.parse(Buffer.concat(chunks).toString('utf8'));}catch{throw unavailable();}
  if(!response.ok){if([400,413,415,422].includes(response.status)&&/^cv_/.test(data.detail))throw new HttpError(response.status,data.detail);throw unavailable();}
  if(!['pdf','docx'].includes(data.file_type)||typeof data.text!=='string'||data.text.length>40000||data.size!==bytes.length||data.sha256!==createHash('sha256').update(bytes).digest('hex')||!Array.isArray(data.links)||data.links.length>20)throw unavailable();
  return data;
}
