import Fastify,{ LogController } from 'fastify';
import cors from '@fastify/cors';
import { HttpError,errorHandler } from '../lib/http/errors.js';
import { privateOrigin } from '../lib/runtime.js';

export function destination(path){
  if(/^\/admin\/api\/(login|verify|reauth|logout|session)\/?$/.test(path))return 'auth';
  if(/^\/admin\/api\/(overview|users|subscriptions|health|audit|collector|accounts|search-titles|sender|controls)(\/|$)/.test(path))return 'data';
  if(/^\/v1\/me\/?$/.test(path))return 'auth';
  if(/^\/v1\/(applications|auto-apply|mail-account|devices)(\/|$)/.test(path)||path==='/v1/device/activity')return 'messaging';
  if(/^\/v1\/(taxonomy|jobs|profile|cv)(\/|$)/.test(path)||path==='/internal/v1/downloads')return 'app';
  return null;
}

export function gatewayTargets(env=process.env){
  return Object.fromEntries(['auth','app','messaging','data'].map(name=>{
    const prefix=name.toUpperCase(),url=privateOrigin(env[`${prefix}_SERVICE_URL`]||`http://127.0.0.1:${{auth:4101,app:4102,messaging:4103,data:4105}[name]}`),key=env[`${prefix}_SERVICE_KEY`];
    if(!key||key.length<32)throw Error(`${prefix}_SERVICE_KEY is required`);
    return [name,{url,key}];
  }));
}

export function buildGateway({targets,origins=[],fetcher=fetch,logger=false,timeoutMs=90000,version='0.5.10',notice=null}={}){
  const app=Fastify({logger,bodyLimit:4*1024*1024,requestTimeout:timeoutMs+5000,connectionTimeout:10000,logController:new LogController({disableRequestLogging:true})});
  app.setErrorHandler(errorHandler);
  app.setNotFoundHandler((request,reply)=>reply.code(404).send({detail:'Not Found'}));
  app.addHook('onSend',async(request,reply)=>{reply.header('X-Content-Type-Options','nosniff');reply.header('Cache-Control','no-store');});
  app.register(cors,{origin:(origin,done)=>!origin||origins.includes(origin)?done(null,true):done(new HttpError(403,'Origin not allowed'),false),methods:['GET','POST','PUT','DELETE','OPTIONS'],allowedHeaders:['Authorization','Content-Type','X-Request-ID','X-Autolinky-Client-Version','X-Admin-Session','X-Admin-Elevation'],exposedHeaders:['Retry-After','X-Request-ID'],maxAge:600});
  app.removeAllContentTypeParsers();
  app.addContentTypeParser('*',{parseAs:'buffer'},(request,body,done)=>done(null,body));
  app.get('/health',async()=>({status:'ok',service:'gateway',version,notice}));
  app.get('/health/ready',async(request,reply)=>{
    const results=await Promise.all(Object.entries(targets).map(async([name,target])=>{
      try{const r=await fetcher(target.url+'/health/ready',{signal:AbortSignal.timeout(2000),redirect:'error'});await r.arrayBuffer();return [name,r.ok?'ready':'unavailable'];}catch{return [name,'unavailable'];}
    }));
    const ready=results.every(([,status])=>status==='ready');
    return reply.code(ready?200:503).send({status:ready?'ok':'degraded',services:Object.fromEntries(results)});
  });
  app.route({method:['GET','HEAD','POST','PUT','DELETE','PATCH'],url:'/*',handler:async(request,reply)=>{
    const path=request.url.split('?')[0];let decoded;
    try{decoded=decodeURIComponent(path);}catch{throw new HttpError(404,'Not Found');}
    // Fetch normalizes dot segments before dispatch. Reject them before choosing
    // a privileged upstream so a public route cannot become a private URL.
    if(decoded.includes('\\')||decoded.includes('\0')||decoded.split('/').some(part=>part==='.'||part==='..')||/%2f/i.test(path))throw new HttpError(404,'Not Found');
    const name=destination(path),target=targets[name];
    if(!target)throw new HttpError(404,'Not Found');
    // Preserve CV bytes and DTO/status contracts. Never forward caller-supplied
    // service credentials, identity headers, cookies or arbitrary proxy headers.
    const headers={'x-service-key':target.key};
    for(const key of ['authorization','content-type','x-request-id','x-autolinky-client-version','x-internal-key','x-admin-session','x-admin-elevation'])if(request.headers[key])headers[key]=request.headers[key];
    let upstream;
    try{
      upstream=await fetcher(target.url+request.url,{method:request.method,headers,body:['GET','HEAD'].includes(request.method)?undefined:request.body,signal:AbortSignal.timeout(timeoutMs),redirect:'error'});
    }catch{
      // A failed/slow mail response can follow SMTP acceptance. No automatic retry.
      throw new HttpError(503,'Service temporarily unavailable');
    }
    reply.code(upstream.status);
    for(const key of ['content-type','retry-after','www-authenticate','x-request-id'])if(upstream.headers.get(key))reply.header(key,upstream.headers.get(key));
    return reply.send(Buffer.from(await upstream.arrayBuffer()));
  }});
  return app;
}
