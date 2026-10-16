import { buildApp } from '../app.js';
import { loadConfig } from '../config.js';
import { remoteAuthentication,requireServiceKey,serve } from './runtime.js';

export async function userService(role,env=process.env){
  const config=loadConfig(env,{identity:role==='auth'});
  const authProvider=role==='auth'?undefined:remoteAuthentication({url:env.AUTH_SERVICE_URL,key:env.AUTH_SERVICE_KEY});
  const app=buildApp({config,role,authProvider,logger:{level:'info',redact:['req.headers','req.body']}});
  requireServiceKey(app,env.SERVICE_KEY);
  await serve(app,config);
}
