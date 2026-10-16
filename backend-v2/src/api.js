import { buildApp } from './app.js';
import { loadConfig } from './config.js';
const config=loadConfig();
const app=buildApp({config,logger:{level:'info',redact:['req.headers.authorization','req.headers.cookie','req.body','res.headers["set-cookie"]']}});
let stopping=false;
for(const signal of ['SIGINT','SIGTERM'])process.on(signal,async()=>{
  if(stopping)return;stopping=true;
  const timeout=setTimeout(()=>process.exit(1),15000);timeout.unref();
  try{await app.close();clearTimeout(timeout);}catch{process.exitCode=1;}
});
try{await app.listen({host:config.host,port:config.port});}
catch(error){app.log.error({type:error.name,code:error.code},'API startup failed; check configuration and migration status');await app.close();process.exitCode=1;}
