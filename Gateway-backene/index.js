import { buildGateway,gatewayTargets } from './src/app.js';
import { serve } from '../backend-v2/shared/runtime.js';
import { loadConfig } from '../backend-v2/shared/config.js';
const env=process.env;
const config=loadConfig(env,{database:false,identity:false});
await serve(buildGateway({targets:gatewayTargets(env),origins:config.origins,notice:config.notice,version:config.version,logger:true}),config);
