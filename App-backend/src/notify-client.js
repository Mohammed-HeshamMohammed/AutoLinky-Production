import { apiClient } from '../lib/api.js';
export function createNotifyClient({url=process.env.NOTIFY_SERVICE_URL,key=process.env.NOTIFY_READ_KEY,fetcher}={}){
  const call=apiClient(url,key,{fetcher});
  return {overlay:(user_id,ids)=>call('/internal/v1/applications/overlay',{user_id,ids})};
}
