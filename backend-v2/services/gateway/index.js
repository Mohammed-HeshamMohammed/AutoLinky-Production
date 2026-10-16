import { buildGateway,gatewayTargets } from './src/app.js';
import { serve } from '../../shared/runtime.js';
import { loadConfig } from '../../shared/config.js';
const env=process.env;
const config=loadConfig(env,{database:false,identity:false});
await serve(buildGateway({targets:gatewayTargets(env),origins:config.origins,notice:config.notice,version:config.version,logger:true}),config);
