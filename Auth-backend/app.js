import { createBackend,protectedRoutes } from '../backend-v2/shared/http/server.js';
import { loadConfig } from '../backend-v2/shared/config.js';
import { createDatabase } from '../backend-v2/shared/db/client.js';
import { firebaseIdentity,authentication } from './src/auth.js';
import { registerIdentityRoutes,registerAuthSession } from './routes.js';
import { requireServiceKey } from '../backend-v2/shared/runtime.js';

export function buildAuth({config=loadConfig(),db=createDatabase(config),identity=firebaseIdentity(config),serviceKey,logger=false}={}){
  const app=createBackend({config,db,logger}),context=app.services;
  context.identity=identity;context.auth=authentication(db,identity,context.limiter,config);
  protectedRoutes(app,context.auth,registerIdentityRoutes);registerAuthSession(app,context);
  if(serviceKey!==undefined)requireServiceKey(app,serviceKey);
  return app;
}
