import { buildAppBackend } from './app.js';
import { loadConfig } from './lib/config.js';
import { serve } from './lib/runtime.js';
const config=loadConfig(process.env,{identity:false});
await serve(buildAppBackend({config,serviceKey:process.env.SERVICE_KEY||'',logger:{level:'info',redact:['req.headers','req.body']}}),config);
