import { apiClient } from '../lib/api.js';
export function createAppClient({url=process.env.APP_SERVICE_URL,key=process.env.APP_READ_KEY,fetcher}={}){
  const call=apiClient(url,key,{fetcher});
  return {
    snapshot:(user_id,include_bytes=false)=>call('/internal/v1/messaging/snapshot',{user_id,include_bytes}),
    job:job_id=>call('/internal/v1/messaging/job',{job_id}),
    matches:(user_id,options)=>call('/internal/v1/messaging/matches',{user_id,options}),
    newMatches:async(user_id,since,min)=>(await call('/internal/v1/messaging/new-matches',{user_id,since:new Date(since).toISOString(),min})).count,
  };
}
