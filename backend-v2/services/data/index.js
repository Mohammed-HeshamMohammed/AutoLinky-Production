import { buildOperations } from '../../src/services/operations.js';
import { serve } from '../../src/services/runtime.js';
await serve(buildOperations({role:'data',logger:true}),{host:process.env.HOST||'127.0.0.1',port:Number(process.env.PORT||4105)});
