import { createBackend,protectedRoutes } from './lib/http/server.js';
import { loadConfig } from './lib/config.js';
import { createDatabase } from './lib/db/client.js';
import { firebaseIdentity,authentication } from './src/auth.js';
import { registerIdentityRoutes,registerAuthSession } from './routes.js';
import { requireServiceKey } from './lib/runtime.js';
import { createIdentityDataClient } from './src/data-client.js';
import { registerAdminAuthentication,adminSessionPath } from './src/admin.js';

export function buildAuth({config=loadConfig(),db=createDatabase(config),identity=firebaseIdentity(config),identityData=createIdentityDataClient(),adminOptions={secret:process.env.ADMIN_SESSION_SECRET,totpKey:process.env.ADMIN_TOTP_KEY},adminServiceKey=process.env.AUTH_ADMIN_KEY,serviceKey,schemaCheck,logger=false}={}){
  const app=createBackend({config,db,logger,schemaCheck}),context=app.services;
  context.identity=identity;context.identityData=identityData;context.auth=authentication(db,identity,context.limiter,config);
  protectedRoutes(app,context.auth,registerIdentityRoutes);registerAuthSession(app,context);
  context.admin=registerAdminAuthentication(app,{db,auth:context.auth,...adminOptions});
  if(serviceKey!==undefined)requireServiceKey(app,serviceKey,context.admin?{[adminSessionPath]:adminServiceKey}:{});
  return app;
}
