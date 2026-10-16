import { createBackend,protectedRoutes } from '../backend-v2/shared/http/server.js';
import { loadConfig } from '../backend-v2/shared/config.js';
import { createDatabase } from '../backend-v2/shared/db/client.js';
import { AIClient } from '../backend-v2/shared/ai/client.js';
import { remoteAuthentication,requireServiceKey } from '../backend-v2/shared/runtime.js';
import { gmailTransport } from './src/email/gmail.js';
import { deliveryService } from './src/email/delivery.js';
import { registerDeviceActivity } from './src/routes/devices.js';
import { registerMessagingRoutes } from './routes.js';

export function buildMessaging({config=loadConfig(process.env,{identity:false}),db=createDatabase(config),authProvider=remoteAuthentication({url:process.env.AUTH_SERVICE_URL,key:process.env.AUTH_SERVICE_KEY}),ai=new AIClient(config),transport=gmailTransport(),mail=deliveryService({db,config,transport,ai}),serviceKey,logger=false}={}){
  const app=createBackend({config,db,logger}),context=app.services;
  Object.assign(context,{auth:authProvider,ai,transport,mail});
  protectedRoutes(app,authProvider,registerMessagingRoutes);registerDeviceActivity(app,context);
  if(serviceKey!==undefined)requireServiceKey(app,serviceKey);
  return app;
}
