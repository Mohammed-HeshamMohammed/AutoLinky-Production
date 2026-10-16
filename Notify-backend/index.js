import { buildMessaging } from './app.js';
import { loadConfig } from '../backend-v2/shared/config.js';
import { serve } from '../backend-v2/shared/runtime.js';
const config=loadConfig(process.env,{identity:false});
await serve(buildMessaging({config,serviceKey:process.env.SERVICE_KEY||'',logger:{level:'info',redact:['req.headers','req.body']}}),config);
