import { HttpError } from './http/errors.js';
export function apiClient(url,key,{fetcher=fetch}={}){
  const origin=new URL(url);
  if(!['http:','https:'].includes(origin.protocol)||origin.username||origin.password||origin.pathname!=='/'||origin.search||origin.hash)throw Error('Private API URL must be an HTTP origin');
  if(typeof key!=='string'||key.length<32)throw Error('A private API key of at least 32 characters is required');
  return async(path,body)=>{
    let response;
    try{response=await fetcher(origin.origin+path,{method:'POST',redirect:'error',headers:{'content-type':'application/json','x-service-key':key},body:JSON.stringify(body),signal:AbortSignal.timeout(10000)});}
    catch{throw new HttpError(503,'Private service unavailable');}
    const reader=response.body?.getReader(),chunks=[];let size=0;
    try{if(reader)for(;;){const {done,value}=await reader.read();if(done)break;size+=value.length;if(size>8*1024*1024)throw Error('Private response exceeds limit');chunks.push(value);}}
    catch{throw new HttpError(503,'Private service unavailable');}finally{await reader?.cancel().catch(()=>{});}
    let value;try{value=JSON.parse(Buffer.concat(chunks).toString('utf8'));}catch{throw new HttpError(503,'Invalid private response');}
    if(!response.ok)throw new HttpError([404,409,422].includes(response.status)?response.status:503,value?.detail||'Private service unavailable');
    return value;
  };
}
export async function schemaReadiness(url){
  try{const origin=new URL(url);if(!['http:','https:'].includes(origin.protocol)||origin.username||origin.password||origin.pathname!=='/'||origin.search||origin.hash)throw Error();
    const response=await fetch(origin.origin+'/health/ready',{signal:AbortSignal.timeout(3000),redirect:'error'});await response.arrayBuffer();if(!response.ok)throw Error();
  }catch{throw Error('Data service schema readiness unavailable');}
}
