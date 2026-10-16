import { buildAuth } from './app.js';
import { loadConfig } from '../../shared/config.js';
import { serve } from '../../shared/runtime.js';
const config=loadConfig(process.env,{identity:true});
await serve(buildAuth({config,serviceKey:process.env.SERVICE_KEY||'',logger:{level:'info',redact:['req.headers','req.body']}}),config);
