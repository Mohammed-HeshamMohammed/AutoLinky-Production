import { HttpError } from '../lib/http/errors.js';
export const identityPath='/internal/v1/identity/delete-data';
export function registerIdentityData(app,db){
  app.post(identityPath,{schema:{body:{type:'object',additionalProperties:false,required:['user_id'],properties:{user_id:{type:'string',format:'uuid'}}}}},async request=>{
    try{await db.query('SELECT public.delete_user_data($1)',[request.body.user_id]);return {deleted:true};}
    catch(error){if(error.message==='deletion_blocked')throw new HttpError(409,'deletion_blocked');throw error;}
  });
}
