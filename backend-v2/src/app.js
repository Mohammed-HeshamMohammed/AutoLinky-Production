import Fastify, { LogController } from 'fastify';
import cors from '@fastify/cors';
import { randomBytes } from 'node:crypto';
import { loadConfig } from './config.js';
import { createDatabase } from './db/client.js';
import { MemoryCache } from './cache/memory.js';
import { MemoryLimiter } from './http/rate-limit.js';
import { errorHandler,HttpError } from './http/errors.js';
import { firebaseIdentity,authentication } from './http/auth.js';
import { checkMigrations } from '../database/migrate.js';
import { AIClient } from './ai/client.js';
import { registerDeviceActivity } from './http/routes/devices.js';
import { registerIdentityRoutes,registerAuthSession } from '../services/auth/routes.js';
import { registerAppRoutes,registerDownloads } from '../services/app/routes.js';
import { registerMessagingRoutes } from '../services/messaging/routes.js';
import { gmailTransport } from './email/gmail.js';
import { deliveryService } from './email/delivery.js';

export function buildApp({config=loadConfig(),role='all',db=createDatabase(config),identity=['all','auth'].includes(role)?firebaseIdentity(config):null,logger=false,ai=role==='auth'?null:new AIClient(config),extractor,transport=['all','messaging'].includes(role)?gmailTransport():null,mail=['all','messaging'].includes(role)?deliveryService({db,config,transport,ai}):null,authProvider}={}) {
  if(!['all','auth','app','messaging'].includes(role))throw Error('Unknown API service');
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
  const cache=new MemoryCache(),limiter=new MemoryLimiter(),auth=authProvider||authentication(db,identity,limiter,config);
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
    if(['all','auth'].includes(role)){
      registerIdentityRoutes(privateApp,context);
    }
    if(['all','app'].includes(role)){
      registerAppRoutes(privateApp,context);
    }
    if(['all','messaging'].includes(role)){
      registerMessagingRoutes(privateApp,context);
    }
  });
  if(role==='auth')registerAuthSession(app,context);
  if(['all','messaging'].includes(role))registerDeviceActivity(app,context);
  if(['all','app'].includes(role)){
    registerDownloads(app,context);
  }
  return app;
}
