import { privateOrigin } from '../lib/runtime.js';
import { HttpError } from '../lib/http/errors.js';
export function remoteAdmin({url,key,fetcher=fetch}){
  const origin=privateOrigin(url);if(typeof key!=='string'||key.length<32)throw Error('AUTH_ADMIN_KEY is required');
  return {async authenticate(request,{write=false,elevated=false}={}){
    if(!request.headers.authorization)throw new HttpError(401,'invalid_login');
    let response;try{response=await fetcher(origin+'/internal/v1/admin/session',{method:'POST',redirect:'error',signal:AbortSignal.timeout(5000),headers:{'content-type':'application/json','x-service-key':key,authorization:request.headers.authorization,...(request.headers['x-admin-elevation']?{'x-admin-elevation':request.headers['x-admin-elevation']}:{})},body:JSON.stringify({write,elevated})});}catch{throw new HttpError(503,'Administrator verification unavailable');}
    const admin=await response.json().catch(()=>null);if(!response.ok)throw new HttpError([401,403,429].includes(response.status)?response.status:503,admin?.detail||'Administrator verification unavailable');
    if(!admin?.id||!['owner','operator','viewer'].includes(admin.role))throw new HttpError(503,'Administrator verification unavailable');
    return admin;
  }};
}
