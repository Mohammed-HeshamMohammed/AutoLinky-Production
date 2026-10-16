import { createBackend,protectedRoutes } from '../backend-v2/shared/http/server.js';
import { loadConfig } from '../backend-v2/shared/config.js';
import { createDatabase } from '../backend-v2/shared/db/client.js';
import { AIClient } from '../backend-v2/shared/ai/client.js';
import { remoteAuthentication,requireServiceKey } from '../backend-v2/shared/runtime.js';
import { registerAppRoutes,registerDownloads } from './routes.js';

export function buildAppBackend({config=loadConfig(process.env,{identity:false}),db=createDatabase(config),authProvider=remoteAuthentication({url:process.env.AUTH_SERVICE_URL,key:process.env.AUTH_SERVICE_KEY}),ai=new AIClient(config),extractor,serviceKey,logger=false}={}){
  const app=createBackend({config,db,logger}),context=app.services;
  Object.assign(context,{auth:authProvider,ai,extractor});
  protectedRoutes(app,authProvider,registerAppRoutes);registerDownloads(app,context);
  if(serviceKey!==undefined)requireServiceKey(app,serviceKey);
  return app;
}
