import { randomUUID,randomBytes,createHash } from 'node:crypto';
import { HttpError,notFound } from '../../../../shared/http/errors.js';
import { durableLimit } from '../../../../shared/http/rate-limit.js';
import { transaction } from '../../../../shared/db/client.js';
import { uuid,queryOf,time } from '../../../../shared/contracts/query.js';
import { activitySince } from '../activity.js';
export const tokenHash=value=>createHash('sha256').update(value).digest('hex');
export function registerDevices(app,{db}){
  app.post('/v1/devices',{schema:{body:{type:'object',additionalProperties:false,properties:{platform:{enum:['android','ios']}}}}},async(request,reply)=>{
    await durableLimit(db,`devices:${request.user.id}`,20,86400);
    const token='dv1_'+randomBytes(32).toString('base64url'),id=randomUUID();
    await transaction(db,async c=>{
      await c.query('SELECT pg_advisory_xact_lock(hashtextextended($1,0))',[`devices:${request.user.id}`]);
      await c.query('DELETE FROM public.app_devices WHERE id IN (SELECT id FROM public.app_devices WHERE user_id=$1 ORDER BY created_at DESC,id DESC OFFSET 9)',[request.user.id]);
      await c.query('INSERT INTO public.app_devices(id,user_id,token_hash,platform) VALUES($1,$2,$3,$4)',[id,request.user.id,tokenHash(token),request.body.platform||'android']);
    });return reply.code(201).send({device_id:id,token});
  });
  app.delete('/v1/devices/:device_id',async(request,reply)=>{if(!uuid.test(request.params.device_id))throw notFound();await db.query('DELETE FROM public.app_devices WHERE id=$1 AND user_id=$2',[request.params.device_id,request.user.id]);return reply.code(204).send();});
}
export function registerDeviceActivity(app,{db,config}){
  app.get('/v1/device/activity',async request=>{
    const match=/^Device (dv1_[A-Za-z0-9_-]+)$/.exec(request.headers.authorization||'');if(!match||match[1].length>100)throw new HttpError(401,'Invalid device token');
    const device=(await db.query('SELECT d.id,d.user_id,u.status FROM public.app_devices d JOIN public.app_users u ON u.id=d.user_id WHERE d.token_hash=$1',[tokenHash(match[1])])).rows[0];
    if(!device)throw new HttpError(401,'Invalid device token');if(device.status!=='active')throw new HttpError(403,'Forbidden');
    await durableLimit(db,`device:${device.id}`,30,3600);await db.query('UPDATE public.app_devices SET last_seen_at=now() WHERE id=$1',[device.id]).catch(()=>{});
    return activitySince(db,device.user_id,time(queryOf(request).get('after'),'after'),config);
  });
}
