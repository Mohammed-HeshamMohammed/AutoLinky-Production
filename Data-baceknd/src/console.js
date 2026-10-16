import { createHash } from 'node:crypto';
import { HttpError } from '../lib/http/errors.js';
import { transaction } from '../lib/db/client.js';
const hash=value=>createHash('sha256').update(JSON.stringify(value)).digest('hex');
const idSchema={type:'string',format:'uuid'},nullableInteger=max=>({anyOf:[{type:'integer',minimum:0,maximum:max},{type:'null'}]});
const bodySchema={type:'object',additionalProperties:false,required:['expected','reason','patch'],properties:{expected:{type:'string',pattern:'^[a-f0-9]{64}$'},reason:{type:'string',minLength:5,maxLength:500},patch:{type:'object',additionalProperties:false,properties:{status:{enum:['active','blocked']},free_emails:nullableInteger(100000),daily_limit:nullableInteger(500),plan:{enum:['free','pro']},months:{type:'integer',minimum:1,maximum:120}}}}};
async function userDetail(db,id){
  const user=(await db.query('SELECT id,email,status,created_at,last_seen_at FROM public.app_users WHERE id=$1',[id])).rows[0];if(!user)throw new HttpError(404,'Not found');
  const limits=await db.query('SELECT free_emails,unlimited,daily_limit,daily_unlimited,note,updated_at FROM public.user_limits WHERE user_id=$1',[id]);
  const subscription=await db.query('SELECT email,starts_at,ends_at,note,updated_at,(starts_at<=now() AND (ends_at IS NULL OR ends_at>now())) active FROM public.subscriptions WHERE email=public.plan_email($1)',[user.email]);
  const apps=await db.query('SELECT count(user_id)::integer count FROM public.applications WHERE user_id=$1',[id]);
  const devices=await db.query('SELECT count(id)::integer count FROM public.app_devices WHERE user_id=$1',[id]);
  const state={status:user.status,email:user.email,limits:limits.rows[0]||null,subscription:subscription.rows[0]||null};
  return {...user,limits:state.limits,subscription:state.subscription,applications:apps.rows[0].count,devices:devices.rows[0].count,revision:hash(state)};
}
async function audit(db,admin,{id=null,email=null,action,reason='',before=null,after=null,requestId}){
  await db.query('INSERT INTO public.admin_log(admin,actor_id,user_id,email,action,details,before_state,after_state,request_id) VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9)',[admin.username,admin.id,id,email,action,{reason},before,after,requestId]);
}
export function registerConsole(app,{db,auth,serviceURLs={}}){
  let overview;
  app.register(async consoleApp=>{
    consoleApp.decorateRequest('admin',null);
    consoleApp.addHook('onRequest',async request=>{
      const write=!['GET','HEAD'].includes(request.method);request.admin=await auth.authenticate(request,{write,elevated:write});
    });
    consoleApp.get('/admin/api/overview',async()=>{
      if(overview?.expires>Date.now())return overview.value;
      const [users,email,auto,cvs,pro,batches,history]=await Promise.all([
        db.query("SELECT count(id)::integer total,count(id) FILTER(WHERE status='blocked')::integer blocked FROM public.app_users"),
        db.query("SELECT count(user_id) FILTER(WHERE status='sent')::integer sent,count(user_id) FILTER(WHERE status='sending')::integer sending,count(user_id) FILTER(WHERE status='failed')::integer failed FROM public.applications WHERE method='email' AND created_at>now()-interval '30 days'"),
        db.query('SELECT count(*)::integer count FROM public.auto_apply WHERE enabled'),db.query('SELECT count(user_id)::integer count FROM public.user_cvs'),
        db.query("SELECT count(*)::integer count FROM public.subscriptions WHERE starts_at<=now() AND (ends_at IS NULL OR ends_at>now())"),db.query("SELECT count(id)::integer count FROM public.ingestion_batches WHERE status='pending'"),
        db.query(`SELECT d.at::date::text AS "day",count(u.id)::integer signups FROM generate_series(current_date-29,current_date,interval '1 day') d(at) LEFT JOIN public.app_users u ON u.created_at>=d.at AND u.created_at<d.at+interval '1 day' GROUP BY d.at ORDER BY d.at`),
      ]);
      const value={users:users.rows[0],email:email.rows[0],auto_enabled:auto.rows[0].count,cvs:cvs.rows[0].count,pro:pro.rows[0].count,batches:batches.rows[0].count,history:history.rows};overview={value,expires:Date.now()+30000};return value;
    });
    consoleApp.get('/admin/api/users',{schema:{querystring:{type:'object',additionalProperties:false,properties:{q:{type:'string',maxLength:100},filter:{enum:['all','pro','free','blocked','auto','active','new']},offset:{type:'string',pattern:'^[0-9]{1,7}$'}}}}},async request=>{
      const offset=Number(request.query.offset||0),filter=request.query.filter||'all';
      const {rows}=await db.query('SELECT * FROM public.admin_users($1,$2,$3,$4,$5)',[request.query.q||null,filter,'new',30,offset]);
      return {items:rows.map(({total_count,...row})=>row),total:rows.length?Number(rows[0].total_count):0,offset};
    });
    consoleApp.get('/admin/api/users/:id',{schema:{params:{type:'object',required:['id'],properties:{id:idSchema}}}},async request=>transaction(db,async connection=>{
      const user=await userDetail(connection,request.params.id);await audit(connection,request.admin,{id:user.id,email:user.email,action:'view_user',requestId:request.id});return user;
    }));
    consoleApp.put('/admin/api/users/:id',{schema:{params:{type:'object',required:['id'],properties:{id:idSchema}},body:bodySchema}},async request=>transaction(db,async connection=>{
      const {id}=request.params,{expected,reason,patch}=request.body;
      await connection.query('SELECT pg_advisory_xact_lock(hashtextextended($1,0))',['console:'+id]);
      const locked=(await connection.query('SELECT email FROM public.app_users WHERE id=$1 FOR UPDATE',[id])).rows[0];if(!locked)throw new HttpError(404,'Not found');
      if(locked.email)await connection.query('SELECT pg_advisory_xact_lock(hashtextextended($1,0))',['console-plan:'+locked.email.toLowerCase()]);
      const before=await userDetail(connection,id);if(before.revision!==expected)throw new HttpError(409,'changed_meanwhile');
      if(patch.status){await connection.query('UPDATE public.app_users SET status=$2 WHERE id=$1',[id,patch.status]);if(patch.status==='blocked')await connection.query('UPDATE public.auto_apply SET enabled=false,updated_at=now() WHERE user_id=$1',[id]);}
      if(Object.hasOwn(patch,'free_emails')||Object.hasOwn(patch,'daily_limit')){
        const free=Object.hasOwn(patch,'free_emails')?patch.free_emails:before.limits?.free_emails??null,daily=Object.hasOwn(patch,'daily_limit')?patch.daily_limit:before.limits?.daily_limit??null;
        await connection.query('INSERT INTO public.user_limits(user_id,free_emails,daily_limit,updated_by) VALUES($1,$2,$3,$4) ON CONFLICT(user_id) DO UPDATE SET free_emails=EXCLUDED.free_emails,daily_limit=EXCLUDED.daily_limit,updated_by=EXCLUDED.updated_by,updated_at=now()',[id,free,daily,request.admin.username]);
      }
      if(patch.plan){
        if(!before.email)throw new HttpError(409,'no_email');
        if(patch.plan==='free')await connection.query('DELETE FROM public.subscriptions WHERE email=public.plan_email($1)',[before.email]);
        else if(!before.subscription?.active||patch.months)await connection.query("INSERT INTO public.subscriptions(email,starts_at,ends_at,note) VALUES(public.plan_email($1),now(),now()+$2*interval '1 month',$3) ON CONFLICT(email) DO UPDATE SET starts_at=EXCLUDED.starts_at,ends_at=EXCLUDED.ends_at,note=EXCLUDED.note,updated_at=now()",[before.email,patch.months||1,reason]);
      }
      const after=await userDetail(connection,id);await audit(connection,request.admin,{id,email:before.email,action:'update_user',reason,before,after,requestId:request.id});overview=null;return after;
    }));
    consoleApp.get('/admin/api/subscriptions',async()=>({items:(await db.query('SELECT email,starts_at,ends_at,(starts_at<=now() AND (ends_at IS NULL OR ends_at>now())) active FROM public.subscriptions ORDER BY updated_at DESC LIMIT 100')).rows}));
    consoleApp.get('/admin/api/audit',async()=>({items:(await db.query("SELECT id,created_at,admin,email,action,details->>'reason' reason FROM public.admin_log ORDER BY created_at DESC,id DESC LIMIT 100")).rows}));
    consoleApp.get('/admin/api/health',async()=>({services:await Promise.all(Object.entries(serviceURLs).map(async([name,url])=>{
      try{const response=await fetch(new URL('/health/ready',url),{redirect:'error',signal:AbortSignal.timeout(2000)});await response.arrayBuffer();return {name,ready:response.ok};}catch{return {name,ready:false};}
    })),workers:(await db.query('SELECT name,seen_at FROM public.worker_heartbeats ORDER BY name')).rows}));
  });
}
