import { HttpError } from '../lib/http/errors.js';
export async function fetchProvider({provider,providers,data,fetcher=fetch}){
  const source=providers[provider];
  if(!source)throw new HttpError(422,'Unknown configured provider');
  const url=new URL(source.url);
  if(url.protocol!=='https:'||url.username||url.password)throw new HttpError(503,'Provider requires a configured HTTPS URL');
  // URLs/credentials come from the private environment, never the request body.
  const response=await fetcher(url,{headers:{accept:'application/json',...(source.token?{authorization:`Bearer ${source.token}`}:{})},signal:AbortSignal.timeout(20000),redirect:'error'});
  if(!response.ok)throw new HttpError(502,'Provider request failed');
  if(!/\bapplication\/(?:[\w.+-]*\+)?json\b/i.test(response.headers.get('content-type')||''))throw new HttpError(502,'Provider did not return JSON');
  const reader=response.body.getReader(),chunks=[];let bytes=0;
  try{for(;;){const {done,value}=await reader.read();if(done)break;bytes+=value.length;if(bytes>4*1024*1024)throw new HttpError(502,'Provider response too large');chunks.push(value);}}
  finally{await reader.cancel().catch(()=>{});}
  let payload;
  try{payload=JSON.parse(Buffer.concat(chunks).toString('utf8'));}catch{throw new HttpError(502,'Invalid provider JSON');}
  const items=Array.isArray(payload)?payload:payload?.items;
  if(!Array.isArray(items)||items.length>500)throw new HttpError(502,'Provider must return at most 500 records');
  return data.stage(provider,items);
}
