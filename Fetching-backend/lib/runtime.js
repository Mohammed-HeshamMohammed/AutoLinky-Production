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
  DATABASE_SCHEMA_NOT_READY:'Database schema differs from this release; verify the database target, bootstrap and reviewed Data migrations before startup.',
  SCHEMA_BOOTSTRAP_CONFIG:'Check PG_DATABASE_URL, the private PG_MIGRATOR_URL for that same database, AUTO_SCHEMA_MIGRATIONS and DATABASE_RUNTIME_PASSWORDS_JSON.',
  SCHEMA_INIT_NOT_EMPTY:'The target has unmanaged tables. Automatic initialization will not overwrite them; review its existing schema first.',
  ENOENT:'A required runtime file or directory is missing from the deployed image.',
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
  '3F000':'A required PostgreSQL schema is missing; check the database target, bootstrap and Data migrations.',
  '42501':'The database role lacks required permissions.',
  '42P01':'A required database table is missing; check Data migrations.',
  '42883':'A required database function is missing; check Data migrations.',
  '53300':'PostgreSQL has no available connections.',
  '57P03':'PostgreSQL is not ready to accept connections.',
};
function startupCause(error){
  const pending=[error],seen=new Set();
  for(let i=0;i<pending.length&&i<16;i++){
    const current=pending[i];
    if(!current||typeof current!=='object'||seen.has(current))continue;
    seen.add(current);
    if(typeof current.code==='string'&&Object.hasOwn(startupMessages,current.code))return current;
    // These exact messages come from the pinned PostgreSQL driver, which omits a timeout code.
    if(['Connection terminated due to connection timeout','timeout exceeded when trying to connect','timeout expired'].includes(current.message))return {code:'ETIMEDOUT'};
    if(current.cause)pending.push(current.cause);
    if(Array.isArray(current.errors))pending.push(...current.errors.slice(0,4));
  }
  return error;
}
export function startupDiagnostic(error){
  const source=startupCause(error);
  const code=typeof source?.code==='string'&&Object.hasOwn(startupMessages,source.code)?source.code:undefined;
  const type=['Error','TypeError','RangeError','AggregateError','FastifyError'].includes(error?.name)?error.name:'Error';
  const fields={type,...(code?{code}:{}),detail:startupMessages[code]||'Startup failed; check the service runtime settings and required dependencies.'};
  if(code==='DATA_SERVICE_NOT_READY'){
    fields.dependency='data';fields.setting='DATA_SERVICE_URL';
    fields.reason=['invalid_url','dns','connection_refused','timeout','tls','network','http_status'].includes(source.reason)?source.reason:'unavailable';
    if(Number.isInteger(source.upstreamStatus)&&source.upstreamStatus>=100&&source.upstreamStatus<=599)fields.upstream_status=source.upstreamStatus;
    const causes=['ENOTFOUND','EAI_AGAIN','ECONNREFUSED','ECONNRESET','ETIMEDOUT','UND_ERR_CONNECT_TIMEOUT','ERR_TLS_CERT_ALTNAME_INVALID','CERT_HAS_EXPIRED','DEPTH_ZERO_SELF_SIGNED_CERT','SELF_SIGNED_CERT_IN_CHAIN','UNABLE_TO_VERIFY_LEAF_SIGNATURE'];
    if(causes.includes(source.causeCode))fields.cause_code=source.causeCode;
  }
  if(code==='DATABASE_SCHEMA_NOT_READY'){
    fields.dependency='database';fields.setting='PG_DATABASE_URL';
    fields.reason=['missing_state','catalog_drift','migration_count','migration_mismatch'].includes(source.reason)?source.reason:'unavailable';
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
