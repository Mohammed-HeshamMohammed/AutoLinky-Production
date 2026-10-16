import { loadConfig } from '../../shared/config.js';
import { createDatabase } from '../../shared/db/client.js';
import { createOperations } from '../../shared/http/operations.js';
import { HttpError } from '../../shared/http/errors.js';
import { fetchProvider } from './src/fetch.js';

export function buildFetching({env=process.env,db,fetcher=fetch,logger=false}={}){
  const config=loadConfig(env,{identity:false});db||=createDatabase(config);
  const app=createOperations({role:'fetching',db,key:env.SERVICE_KEY,logger});
  const providers=JSON.parse(env.FETCH_PROVIDERS_JSON||'{}');
  if(!providers||Array.isArray(providers)||typeof providers!=='object')throw Error('Invalid provider configuration');
  for(const [name,provider] of Object.entries(providers))if(!/^[a-z0-9_-]{1,80}$/.test(name)||!provider?.url)throw Error('Invalid provider configuration');
  let active=0;
  app.post('/internal/v1/fetch',{schema:{body:{type:'object',additionalProperties:false,required:['provider'],properties:{provider:{type:'string',pattern:'^[a-z0-9_-]{1,80}$'}}}}},async(request,reply)=>{
    if(!config.collectorEnabled)throw new HttpError(409,'Collection is disabled');
    if(active>=2)throw new HttpError(429,'Provider capacity reached',{'Retry-After':'5'});
    active++;
    try{return reply.code(202).send(await fetchProvider({provider:request.body.provider,providers,db,fetcher}));}finally{active--;}
  });
  return app;
}
