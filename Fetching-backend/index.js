import { buildFetching } from './app.js';
import { serve } from './lib/runtime.js';
await serve(buildFetching({logger:true}),{host:process.env.HOST||'127.0.0.1',port:Number(process.env.PORT||4104)});
