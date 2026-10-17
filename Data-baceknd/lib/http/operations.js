import Fastify,{ LogController } from 'fastify';
import { errorHandler } from './errors.js';
import { checkMigrations } from '../../database/migrate.js';
import { requireServiceKey } from '../runtime.js';
export function createOperations({role,db,key,routeKeys={},bodyLimit=16384,logger=false,schemaSetup}){
  const app=Fastify({logger,bodyLimit,requestTimeout:30000,logController:new LogController({disableRequestLogging:true}),ajv:{customOptions:{coerceTypes:false,removeAdditional:false}}});
  app.setErrorHandler(errorHandler);requireServiceKey(app,key,routeKeys);
  app.addHook('onReady',async()=>{await schemaSetup?.();await checkMigrations(db);});app.addHook('onClose',()=>db.end?.());
  app.get('/health',async()=>({status:'ok',service:role}));
  app.get('/health/ready',async(request,reply)=>{try{await checkMigrations(db);return {status:'ok',service:role};}catch{return reply.code(503).send({status:'degraded',service:role});}});
  return app;
}
