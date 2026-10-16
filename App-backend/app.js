import { createBackend,protectedRoutes } from './lib/http/server.js';
import { loadConfig } from './lib/config.js';
import { createDatabase } from './lib/db/client.js';
import { AIClient } from './lib/ai/client.js';
import { remoteAuthentication,requireServiceKey } from './lib/runtime.js';
import { registerAppRoutes,registerDownloads } from './routes.js';
import { registerMessagingAPI,messagingPaths } from './src/messaging-api.js';
import { createNotifyClient } from './src/notify-client.js';

export function buildAppBackend({config=loadConfig(process.env,{identity:false}),db=createDatabase(config),authProvider=remoteAuthentication({url:process.env.AUTH_SERVICE_URL,key:process.env.AUTH_SERVICE_KEY}),notifyData=createNotifyClient(),readKey=process.env.APP_READ_KEY,ai=new AIClient(config),extractor,serviceKey,schemaCheck,logger=false}={}){
  const app=createBackend({config,db,logger,schemaCheck}),context=app.services;
  Object.assign(context,{auth:authProvider,ai,extractor,notifyData});
  protectedRoutes(app,authProvider,registerAppRoutes);registerDownloads(app,context);
  if(readKey)registerMessagingAPI(app,context);
  if(serviceKey!==undefined)requireServiceKey(app,serviceKey,Object.fromEntries(messagingPaths.map(path=>[path,readKey||serviceKey])));
  return app;
}
