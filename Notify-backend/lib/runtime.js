import { timingSafeEqual } from 'node:crypto';
import { HttpError } from './http/errors.js';

export function requireServiceKey(app,key,routeKeys={}){
  if(typeof key!=='string'||key.length<32)throw Error('A private SERVICE_KEY of at least 32 characters is required');
  for(const value of Object.values(routeKeys))if(typeof value!=='string'||value.length<32)throw Error('A private route key is required');
  app.addHook('onRequest',async request=>{
    if(['/health','/health/ready'].includes(request.url.split('?')[0]))return;
    const expected=Buffer.from(routeKeys[request.routeOptions.url]||routeKeys[request.url.split('?')[0]]||key);
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

const startupMessages={
  DATA_SERVICE_NOT_READY:'Data readiness check failed; check DATA_SERVICE_URL and make the Data backend ready before starting this service.',
  EADDRINUSE:'The configured HOST/PORT is already in use.',
  EADDRNOTAVAIL:'HOST is not available in this container.',
  EACCES:'The process cannot bind to the configured HOST/PORT.',
  ENOTFOUND:'A required hostname could not be resolved.',
  EAI_AGAIN:'A required DNS lookup failed temporarily.',
  ECONNREFUSED:'A required service refused the connection.',
  ECONNRESET:'A required service reset the connection.',
  ETIMEDOUT:'A required service connection timed out.',
  '28P01':'PostgreSQL authentication failed; check the private database credentials.',
  '28000':'PostgreSQL rejected the configured database role.',
  '3D000':'The configured PostgreSQL database does not exist.',
  '42501':'The database role lacks required permissions.',
  '42P01':'A required database table is missing; check Data migrations.',
  '42883':'A required database function is missing; check Data migrations.',
  '53300':'PostgreSQL has no available connections.',
  '57P03':'PostgreSQL is not ready to accept connections.',
};
export function startupDiagnostic(error){
  const code=typeof error?.code==='string'&&Object.hasOwn(startupMessages,error.code)?error.code:undefined;
  const type=['Error','TypeError','RangeError','AggregateError','FastifyError'].includes(error?.name)?error.name:'Error';
  const fields={type,...(code?{code}:{}),detail:startupMessages[code]||'Startup failed; check the service runtime settings and required dependencies.'};
  if(code==='DATA_SERVICE_NOT_READY'){
    fields.dependency='data';fields.setting='DATA_SERVICE_URL';
    fields.reason=['invalid_url','dns','connection_refused','timeout','tls','network','http_status'].includes(error.reason)?error.reason:'unavailable';
    if(Number.isInteger(error.upstreamStatus)&&error.upstreamStatus>=100&&error.upstreamStatus<=599)fields.upstream_status=error.upstreamStatus;
    const causes=['ENOTFOUND','EAI_AGAIN','ECONNREFUSED','ECONNRESET','ETIMEDOUT','UND_ERR_CONNECT_TIMEOUT','ERR_TLS_CERT_ALTNAME_INVALID','CERT_HAS_EXPIRED','DEPTH_ZERO_SELF_SIGNED_CERT','SELF_SIGNED_CERT_IN_CHAIN','UNABLE_TO_VERIFY_LEAF_SIGNATURE'];
    if(causes.includes(error.causeCode))fields.cause_code=error.causeCode;
  }
  return fields;
}

export async function serve(app,{host='127.0.0.1',port}){
  let stopping=false;
  for(const signal of ['SIGINT','SIGTERM'])process.once(signal,async()=>{
    if(stopping)return;stopping=true;
    const deadline=setTimeout(()=>process.exit(1),15000);deadline.unref();
    try{await app.close();clearTimeout(deadline);}catch{process.exitCode=1;}
  });
  try{await app.listen({host,port});}
  catch(error){app.log.error(startupDiagnostic(error),'Service startup failed');await app.close();process.exitCode=1;}
}
