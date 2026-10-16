import { createBackend,protectedRoutes } from './lib/http/server.js';
import { loadConfig } from './lib/config.js';
import { createDatabase } from './lib/db/client.js';
import { AIClient } from './lib/ai/client.js';
import { remoteAuthentication,requireServiceKey } from './lib/runtime.js';
import { gmailTransport } from './src/email/gmail.js';
import { deliveryService } from './src/email/delivery.js';
import { registerDeviceActivity } from './src/routes/devices.js';
import { registerMessagingRoutes } from './routes.js';
import { createAppClient } from './src/app-client.js';
import { registerApplicationAPI,overlayPath } from './src/application-api.js';

export function buildMessaging({config=loadConfig(process.env,{identity:false}),db=createDatabase(config),authProvider=remoteAuthentication({url:process.env.AUTH_SERVICE_URL,key:process.env.AUTH_SERVICE_KEY}),appData=createAppClient(),readKey=process.env.NOTIFY_READ_KEY,ai=new AIClient(config),transport=gmailTransport(),mail=deliveryService({db,config,transport,ai,appData}),serviceKey,schemaCheck,logger=false}={}){
  const app=createBackend({config,db,logger,schemaCheck}),context=app.services;
  Object.assign(context,{auth:authProvider,ai,transport,mail,appData});
  protectedRoutes(app,authProvider,registerMessagingRoutes);registerDeviceActivity(app,context);
  if(readKey)registerApplicationAPI(app,context);
  if(serviceKey!==undefined)requireServiceKey(app,serviceKey,{[overlayPath]:readKey||serviceKey});
  return app;
}
