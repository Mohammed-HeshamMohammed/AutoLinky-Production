import { timingSafeEqual } from 'node:crypto';
import { HttpError,unavailable } from '../../src/http/errors.js';
import { registerCatalog } from '../../src/http/routes/catalog.js';
import { registerJobs } from '../../src/http/routes/jobs.js';
import { registerProfile } from '../../src/http/routes/profile.js';
import { registerCV } from '../../src/http/routes/cv.js';

export function registerAppRoutes(app,context){
  registerCatalog(app,context);registerJobs(app,context);
  registerProfile(app,context);registerCV(app,context);
}
export function registerDownloads(app,{db,config,limiter}){
  app.post('/internal/v1/downloads',{schema:{body:{type:'object',additionalProperties:false,required:['kind'],properties:{
    kind:{enum:['download','in_app_prompt']},source:{type:['string','null'],maxLength:100},device:{type:['string','null'],maxLength:40},
    tag:{type:['string','null'],maxLength:100},in_app:{type:['string','null'],maxLength:40},
    visitor:{type:['string','null'],maxLength:128},referrer:{type:['string','null'],maxLength:1000},user_agent:{type:['string','null'],maxLength:1000},
    country:{type:['string','null'],maxLength:10},is_bot:{type:'boolean'},version:{type:['string','null'],maxLength:100},
  }}}},async(request,reply)=>{
    const expected=Buffer.from(config.internalDownloadsKey),actual=Buffer.from(request.headers['x-internal-key']||'');
    if(expected.length<32)throw unavailable();
    if(actual.length!==expected.length || !timingSafeEqual(actual,expected))throw new HttpError(401,'Unauthorized');
    limiter.enforce('internal:downloads',300,60);
    const b=request.body;
    await db.query('INSERT INTO public.app_downloads(kind,source,device,visitor,referrer,user_agent,country,is_bot,version,tag,in_app) VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11)',
      [b.kind,b.source||null,b.device||null,b.visitor||null,b.referrer||null,b.user_agent||null,b.country||null,b.is_bot||false,b.version||null,b.tag||null,b.in_app||null]);
    return reply.code(204).send();
  });
}
