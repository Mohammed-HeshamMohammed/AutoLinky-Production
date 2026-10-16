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
function readinessFailure(reason,cause){
  const codes=['ENOTFOUND','EAI_AGAIN','ECONNREFUSED','ECONNRESET','ETIMEDOUT','UND_ERR_CONNECT_TIMEOUT','ERR_TLS_CERT_ALTNAME_INVALID','CERT_HAS_EXPIRED','DEPTH_ZERO_SELF_SIGNED_CERT','SELF_SIGNED_CERT_IN_CHAIN','UNABLE_TO_VERIFY_LEAF_SIGNATURE'];
  const candidates=[cause,cause?.cause,...(Array.isArray(cause?.cause?.errors)?cause.cause.errors.slice(0,4):[])];
  const causeCode=candidates.find(error=>codes.includes(error?.code))?.code;
  if(reason==='network'&&['ENOTFOUND','EAI_AGAIN'].includes(causeCode))reason='dns';
  if(reason==='network'&&causeCode==='ECONNREFUSED')reason='connection_refused';
  if(reason==='network'&&['ETIMEDOUT','UND_ERR_CONNECT_TIMEOUT'].includes(causeCode))reason='timeout';
  if(reason==='network'&&causeCode&&/CERT|SELF_SIGNED|LEAF_SIGNATURE/.test(causeCode))reason='tls';
  return Object.assign(new Error('Data service schema readiness unavailable'),{code:'DATA_SERVICE_NOT_READY',reason,...(causeCode?{causeCode}:{})});
}
export async function schemaReadiness(url,{fetcher=fetch}={}){
  let origin;
  try{
    origin=new URL(url);
    if(!['http:','https:'].includes(origin.protocol)||origin.username||origin.password||origin.pathname!=='/'||origin.search||origin.hash)throw Error();
  }catch{throw readinessFailure('invalid_url');}
  let response;
  try{response=await fetcher(origin.origin+'/health/ready',{signal:AbortSignal.timeout(3000),redirect:'error'});}
  catch(error){throw readinessFailure(['TimeoutError','AbortError'].includes(error?.name)?'timeout':'network',error);}
  // Only the status is needed. Never retain or log a dependency response body.
  try{await response.body?.cancel();}catch{}
  if(!response.ok)throw Object.assign(readinessFailure('http_status'),{upstreamStatus:response.status});
}
