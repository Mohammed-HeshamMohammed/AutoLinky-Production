import { HttpError } from '../backend-v2/shared/http/errors.js';

export function registerIdentityRoutes(app,{db,auth,identity}){
    app.get('/v1/me',async request=>({user_id:request.user.id,email:request.user.email}));
    app.delete('/v1/me',async(request,reply)=>{
      try{await db.query('SELECT public.delete_user_data($1)',[request.user.id]);}
      catch(error){if(error.message==='deletion_blocked')throw new HttpError(409,'deletion_blocked');throw error;}
      auth.invalidate(request.user.firebase_uid);
      try{await identity.deleteUser(request.user.firebase_uid);await db.query('UPDATE public.identity_deletion_queue SET completed_at=now() WHERE firebase_uid=$1',[request.user.firebase_uid]);}
      catch(error){if(error.code==='auth/user-not-found')await db.query('UPDATE public.identity_deletion_queue SET completed_at=now() WHERE firebase_uid=$1',[request.user.firebase_uid]);}
      return reply.code(204).send();
    });
}

export function registerAuthSession(app,{auth}){
  app.post('/internal/v1/session',{schema:{body:{type:'object',additionalProperties:false,required:['method'],properties:{method:{enum:['GET','HEAD','POST','PUT','DELETE','PATCH']}}}}},async request=>{
    const context={headers:request.headers,method:request.body.method};
    await auth.authenticate(context);
    return context.user;
  });
}
