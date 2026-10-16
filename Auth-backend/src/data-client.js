import { apiClient } from '../lib/api.js';
export function createIdentityDataClient({url=process.env.DATA_SERVICE_URL,key=process.env.DATA_IDENTITY_KEY,fetcher}={}){
  const call=apiClient(url,key,{fetcher});
  return {deleteUser:user_id=>call('/internal/v1/identity/delete-data',{user_id})};
}
