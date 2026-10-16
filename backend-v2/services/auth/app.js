import { createBackend,protectedRoutes } from '../../shared/http/server.js';
import { loadConfig } from '../../shared/config.js';
import { createDatabase } from '../../shared/db/client.js';
import { firebaseIdentity,authentication } from './src/auth.js';
import { registerIdentityRoutes,registerAuthSession } from './routes.js';
import { requireServiceKey } from '../../shared/runtime.js';

export function buildAuth({config=loadConfig(),db=createDatabase(config),identity=firebaseIdentity(config),serviceKey,logger=false}={}){
  const app=createBackend({config,db,logger}),context=app.services;
  context.identity=identity;context.auth=authentication(db,identity,context.limiter,config);
  protectedRoutes(app,context.auth,registerIdentityRoutes);registerAuthSession(app,context);
  if(serviceKey!==undefined)requireServiceKey(app,serviceKey);
  return app;
}
