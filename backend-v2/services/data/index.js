import { buildData } from './app.js';
import { serve } from '../../shared/runtime.js';
await serve(buildData({logger:true}),{host:process.env.HOST||'127.0.0.1',port:Number(process.env.PORT||4105)});
