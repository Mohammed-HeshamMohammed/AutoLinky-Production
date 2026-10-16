import { buildGateway,gatewayTargets } from '../../src/services/gateway.js';
import { serve } from '../../src/services/runtime.js';
import { loadConfig } from '../../src/config.js';
const env=process.env;
const config=loadConfig(env,{database:false,identity:false});
await serve(buildGateway({targets:gatewayTargets(env),origins:config.origins,notice:config.notice,version:config.version,logger:true}),config);
