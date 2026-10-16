import { timingSafeEqual } from 'node:crypto';
import { HttpError } from '../http/errors.js';

export function requireServiceKey(app,key){
  if(typeof key!=='string'||key.length<32)throw Error('A private SERVICE_KEY of at least 32 characters is required');
  const expected=Buffer.from(key);
  app.addHook('onRequest',async request=>{
    if(['/health','/health/ready'].includes(request.url.split('?')[0]))return;
    const actual=Buffer.from(request.headers['x-service-key']||'');
    if(actual.length!==expected.length||!timingSafeEqual(actual,expected))throw new HttpError(401,'Unauthorized service');
  });
}

export function privateOrigin(value){
  const url=new URL(value);
  if(!['http:','https:'].includes(url.protocol)||url.username||url.password||url.pathname!=='/'||url.search||url.hash)throw Error('Service URL must be an HTTP origin');
  return url.origin;
}

export function remoteAuthentication({url,key,fetcher=fetch}){
  const origin=privateOrigin(url);
  if(!key||key.length<32)throw Error('AUTH_SERVICE_KEY is required');
  return {invalidate:()=>{},async authenticate(request){
    if(!request.headers.authorization)throw new HttpError(401,'Missing Authorization header',{'WWW-Authenticate':'Bearer'});
    let response;
    try{
      response=await fetcher(origin+'/internal/v1/session',{method:'POST',headers:{'content-type':'application/json','x-service-key':key,authorization:request.headers.authorization},body:JSON.stringify({method:request.method}),signal:AbortSignal.timeout(10000),redirect:'error'});
    }catch{throw new HttpError(503,'Authentication service unavailable');}
    if(!response.ok){
      const payload=await response.json().catch(()=>null);
      const headers={};
      for(const name of ['www-authenticate','retry-after'])if(response.headers.get(name))headers[name]=response.headers.get(name);
      throw new HttpError([401,403,429].includes(response.status)?response.status:503,payload?.detail||'Authentication service unavailable',headers);
    }
    const user=await response.json();
    if(!user?.id||user.status!=='active')throw new HttpError(503,'Authentication service unavailable');
    request.user=user;
  }};
}

export async function serve(app,{host='127.0.0.1',port}){
  let stopping=false;
  for(const signal of ['SIGINT','SIGTERM'])process.once(signal,async()=>{
    if(stopping)return;stopping=true;
    const deadline=setTimeout(()=>process.exit(1),15000);deadline.unref();
    try{await app.close();clearTimeout(deadline);}catch{process.exitCode=1;}
  });
  try{await app.listen({host,port});}
  catch(error){app.log.error({code:error.code,type:error.name},'Service startup failed');await app.close();process.exitCode=1;}
}
