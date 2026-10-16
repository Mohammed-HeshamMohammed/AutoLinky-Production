import { apiClient,schemaReadiness } from '../lib/api.js';
export function createDataClient({url,key,fetcher}={}){
  const call=apiClient(url,key,{fetcher});
  return {stage:(provider,items)=>call('/internal/v1/ingestion',{provider,items}),control:()=>call('/internal/v1/collection/control',{}),ready:()=>schemaReadiness(url)};
}
