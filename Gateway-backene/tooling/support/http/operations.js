import Fastify,{ LogController } from 'fastify';
import { errorHandler } from './errors.js';
import { checkMigrations } from '../../../../Data-baceknd/database/migrate.js';
import { requireServiceKey } from '../runtime.js';
export function createOperations({role,db,key,logger=false}){
  const app=Fastify({logger,bodyLimit:16384,requestTimeout:30000,logController:new LogController({disableRequestLogging:true})});
  app.setErrorHandler(errorHandler);requireServiceKey(app,key);
  app.addHook('onReady',()=>checkMigrations(db));app.addHook('onClose',()=>db.end?.());
  app.get('/health',async()=>({status:'ok',service:role}));
  app.get('/health/ready',async(request,reply)=>{try{await checkMigrations(db);return {status:'ok',service:role};}catch{return reply.code(503).send({status:'degraded',service:role});}});
  return app;
}
