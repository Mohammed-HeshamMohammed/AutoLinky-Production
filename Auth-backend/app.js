import { createBackend,protectedRoutes } from './lib/http/server.js';
import { loadConfig } from './lib/config.js';
import { createDatabase } from './lib/db/client.js';
import { firebaseIdentity,authentication } from './src/auth.js';
import { registerIdentityRoutes,registerAuthSession } from './routes.js';
import { requireServiceKey } from './lib/runtime.js';
import { createIdentityDataClient } from './src/data-client.js';

export function buildAuth({config=loadConfig(),db=createDatabase(config),identity=firebaseIdentity(config),identityData=createIdentityDataClient(),serviceKey,schemaCheck,logger=false}={}){
  const app=createBackend({config,db,logger,schemaCheck}),context=app.services;
  context.identity=identity;context.identityData=identityData;context.auth=authentication(db,identity,context.limiter,config);
  protectedRoutes(app,context.auth,registerIdentityRoutes);registerAuthSession(app,context);
  if(serviceKey!==undefined)requireServiceKey(app,serviceKey);
  return app;
}
