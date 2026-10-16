import { loadConfig } from './lib/config.js';
import { createOperations } from './lib/http/operations.js';
import { HttpError } from './lib/http/errors.js';
import { fetchProvider } from './src/fetch.js';
import { createDataClient } from './src/data-client.js';

export function buildFetching({env=process.env,data=createDataClient({url:env.DATA_SERVICE_URL,key:env.DATA_INGESTION_KEY}),fetcher=fetch,logger=false}={}){
  const config=loadConfig(env,{identity:false,database:false});
  const statusPath='/internal/v1/admin/collector-status';
  const app=createOperations({role:'fetching',ready:()=>data.ready(),key:env.SERVICE_KEY,routeKeys:env.FETCHING_ADMIN_KEY?{[statusPath]:env.FETCHING_ADMIN_KEY}:{},logger});
  const providers=JSON.parse(env.FETCH_PROVIDERS_JSON||'{}');
  if(!providers||Array.isArray(providers)||typeof providers!=='object')throw Error('Invalid provider configuration');
  for(const [name,provider] of Object.entries(providers))if(!/^[a-z0-9_-]{1,80}$/.test(name)||!provider?.url)throw Error('Invalid provider configuration');
  let active=0;
  if(env.FETCHING_ADMIN_KEY)app.get(statusPath,async()=>({enabled:config.collectorEnabled,active_requests:active,capacity:2,providers:Object.keys(providers),linkedin_worker:false}));
  app.post('/internal/v1/fetch',{schema:{body:{type:'object',additionalProperties:false,required:['provider'],properties:{provider:{type:'string',pattern:'^[a-z0-9_-]{1,80}$'}}}}},async(request,reply)=>{
    if(!config.collectorEnabled)throw new HttpError(409,'Collection is disabled');
    if((await data.control()).paused)throw new HttpError(409,'Collection is paused');
    if(active>=2)throw new HttpError(429,'Provider capacity reached',{'Retry-After':'5'});
    active++;
    try{return reply.code(202).send(await fetchProvider({provider:request.body.provider,providers,data,fetcher}));}finally{active--;}
  });
  return app;
}
