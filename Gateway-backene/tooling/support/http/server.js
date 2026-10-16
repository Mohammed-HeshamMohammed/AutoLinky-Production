import Fastify,{ LogController } from 'fastify';
import cors from '@fastify/cors';
import { randomBytes } from 'node:crypto';
import { MemoryCache } from '../cache/memory.js';
import { MemoryLimiter } from './rate-limit.js';
import { errorHandler,HttpError } from './errors.js';
import { checkMigrations } from '../../../../Data-baceknd/database/migrate.js';

// Infrastructure only. No identity SDK, mail transport, or domain controllers.
export function createBackend({config,db,logger=false}){
  const app=Fastify({logger,bodyLimit:config.cvMaxBytes,requestTimeout:30000,connectionTimeout:10000,
    genReqId:()=>randomBytes(8).toString('hex'),ajv:{customOptions:{coerceTypes:false,removeAdditional:false}},
    logController:new LogController({disableRequestLogging:true})});
  app.setErrorHandler(errorHandler);
  app.setNotFoundHandler((request,reply)=>reply.code(404).send({detail:'Not Found'}));
  app.addHook('onSend',async(request,reply)=>{reply.header('X-Request-ID',request.id);reply.header('X-Content-Type-Options','nosniff');reply.header('Cache-Control','no-store');});
  app.register(cors,{origin:(origin,callback)=>!origin||config.origins.includes(origin)?callback(null,true):callback(new HttpError(403,'Origin not allowed'),false),
    credentials:false,methods:['GET','POST','PUT','DELETE','OPTIONS'],allowedHeaders:['Authorization','Content-Type','X-Request-ID','X-Autolinky-Client-Version'],exposedHeaders:['Retry-After','X-Request-ID'],maxAge:600});
  const cache=new MemoryCache(),limiter=new MemoryLimiter();
  app.decorate('services',{config,db,cache,limiter});app.decorateRequest('user',null);
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
  return app;
}

export function protectedRoutes(app,auth,register){
  app.register(async privateApp=>{privateApp.addHook('onRequest',auth.authenticate);register(privateApp,app.services);});
}
