import Fastify, { LogController } from 'fastify';
import cors from '@fastify/cors';
import { randomBytes,timingSafeEqual } from 'node:crypto';
import { loadConfig } from './config.js';
import { createDatabase } from './db/client.js';
import { MemoryCache } from './cache/memory.js';
import { MemoryLimiter } from './http/rate-limit.js';
import { errorHandler,HttpError,unavailable } from './http/errors.js';
import { firebaseIdentity,authentication } from './http/auth.js';
import { checkMigrations } from '../database/migrate.js';
import { registerCatalog } from './http/routes/catalog.js';
import { registerJobs } from './http/routes/jobs.js';
import { registerProfile } from './http/routes/profile.js';
import { registerCV } from './http/routes/cv.js';
import { AIClient } from './ai/client.js';
import { registerApplications } from './http/routes/applications.js';
import { registerEmailApply } from './http/routes/email-apply.js';
import { registerDevices,registerDeviceActivity } from './http/routes/devices.js';
import { gmailTransport } from './email/gmail.js';
import { deliveryService } from './email/delivery.js';

export function buildApp({config=loadConfig(),db=createDatabase(config),identity=firebaseIdentity(config),logger=false,ai=new AIClient(config),extractor,transport=gmailTransport(),mail=deliveryService({db,config,transport,ai})}={}) {
  const app=Fastify({logger,bodyLimit:config.cvMaxBytes,requestTimeout:30000,connectionTimeout:10000,
    genReqId:()=>randomBytes(8).toString('hex'),ajv:{customOptions:{coerceTypes:false,removeAdditional:false}},
    logController:new LogController({disableRequestLogging:true})});
  app.setErrorHandler(errorHandler);
  app.setNotFoundHandler((request,reply)=>reply.code(404).send({detail:'Not Found'}));
  app.addHook('onSend',async(request,reply)=>{reply.header('X-Request-ID',request.id);reply.header('X-Content-Type-Options','nosniff');reply.header('Cache-Control','no-store');});
  app.register(cors,{origin:(origin,callback)=>{
    if(!origin || config.origins.includes(origin))return callback(null,true);
    callback(new HttpError(403,'Origin not allowed'),false);
  },credentials:false,methods:['GET','POST','PUT','DELETE','OPTIONS'],
    allowedHeaders:['Authorization','Content-Type','X-Request-ID','X-Autolinky-Client-Version'],
    exposedHeaders:['Retry-After','X-Request-ID'],maxAge:600});
  const cache=new MemoryCache(),limiter=new MemoryLimiter(),auth=authentication(db,identity,limiter,config);
  const context={db,config,identity,cache,limiter,auth,ai,extractor,mail,transport};
  app.decorate('services',context);
  app.decorateRequest('user',null);
  app.addHook('onReady',async()=>{if(db.configured!==false)await checkMigrations(db);});
  app.addHook('onClose',async()=>{cache.clear();await db.end?.();});
  app.get('/health',async()=>({status:'ok',version:config.version,notice:config.notice}));
  app.get('/health/ready',async(request,reply)=>{
    let problem;
    if(db.configured===false)problem='not_configured';
    else try{await checkMigrations(db);await db.query("SELECT public.api_hit('health:ready',60,1000000)");}
    catch(error){problem=error.code==='42501'?'key_not_allowed':error.code==='42883'||/schema differs/.test(error.message)?'migration_missing':['ECONNREFUSED','ETIMEDOUT'].includes(error.code)?'unreachable':'error';}
    if(problem)return reply.code(503).send({status:'degraded',database:problem,version:config.version});
    return {status:'ok',database:'ok',version:config.version};
  });
  app.register(async privateApp=>{
    privateApp.addHook('onRequest',auth.authenticate);
    privateApp.get('/v1/me',async request=>({user_id:request.user.id,email:request.user.email}));
    privateApp.delete('/v1/me',async(request,reply)=>{
      try{await db.query('SELECT public.delete_user_data($1)',[request.user.id]);}
      catch(error){if(error.message==='deletion_blocked')throw new HttpError(409,'deletion_blocked');throw error;}
      auth.invalidate(request.user.firebase_uid);
      try{await identity.deleteUser(request.user.firebase_uid);await db.query('UPDATE public.identity_deletion_queue SET completed_at=now() WHERE firebase_uid=$1',[request.user.firebase_uid]);}
      catch(error){if(error.code==='auth/user-not-found')await db.query('UPDATE public.identity_deletion_queue SET completed_at=now() WHERE firebase_uid=$1',[request.user.firebase_uid]);}
      return reply.code(204).send();
    });
    registerCatalog(privateApp,context);registerJobs(privateApp,context);registerProfile(privateApp,context);
    registerCV(privateApp,context);
    registerApplications(privateApp,context);
    registerEmailApply(privateApp,context);registerDevices(privateApp,context);
  });
  registerDeviceActivity(app,context);
  app.post('/internal/v1/downloads',{schema:{body:{type:'object',additionalProperties:false,required:['kind'],properties:{
    kind:{enum:['download','in_app_prompt']},source:{type:['string','null'],maxLength:100},device:{type:['string','null'],maxLength:40},
    tag:{type:['string','null'],maxLength:100},in_app:{type:['string','null'],maxLength:40},
    visitor:{type:['string','null'],maxLength:128},referrer:{type:['string','null'],maxLength:1000},user_agent:{type:['string','null'],maxLength:1000},
    country:{type:['string','null'],maxLength:10},is_bot:{type:'boolean'},version:{type:['string','null'],maxLength:100},
  }}}},async(request,reply)=>{
    const expected=Buffer.from(config.internalDownloadsKey),actual=Buffer.from(request.headers['x-internal-key']||'');
    if(expected.length<32)throw unavailable();
    if(actual.length!==expected.length || !timingSafeEqual(actual,expected))throw new HttpError(401,'Unauthorized');
    limiter.enforce('internal:downloads',300,60);
    const b=request.body;
    await db.query('INSERT INTO public.app_downloads(kind,source,device,visitor,referrer,user_agent,country,is_bot,version,tag,in_app) VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11)',
      [b.kind,b.source||null,b.device||null,b.visitor||null,b.referrer||null,b.user_agent||null,b.country||null,b.is_bot||false,b.version||null,b.tag||null,b.in_app||null]);
    return reply.code(204).send();
  });
  return app;
}
