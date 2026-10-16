import { createHash } from 'node:crypto';
import { HttpError } from '../lib/http/errors.js';
import { transaction } from '../lib/db/client.js';
import { registerConsoleOperations } from './console-operations.js';
const hash=value=>createHash('sha256').update(JSON.stringify(value)).digest('hex');
const idSchema={type:'string',format:'uuid'},nullableInteger=max=>({anyOf:[{type:'integer',minimum:0,maximum:max},{type:'null'}]});
const bodySchema={type:'object',additionalProperties:false,required:['expected','reason','patch'],properties:{expected:{type:'string',pattern:'^[a-f0-9]{64}$'},reason:{type:'string',minLength:5,maxLength:500},patch:{type:'object',minProperties:1,additionalProperties:false,properties:{status:{enum:['active','blocked']},free_emails:nullableInteger(100000),daily_limit:nullableInteger(500),unlimited:{type:'boolean'},daily_unlimited:{type:'boolean'},limits_note:{type:['string','null'],maxLength:500},plan:{enum:['free','pro']},months:{type:'integer',minimum:1,maximum:120},until:{type:'string',pattern:'^[0-9]{4}-[0-9]{2}-[0-9]{2}$'},forever:{type:'boolean'}}}}};
async function userDetail(db,id){
  const user=(await db.query('SELECT id,email,status,created_at,last_seen_at FROM public.app_users WHERE id=$1',[id])).rows[0];if(!user)throw new HttpError(404,'Not found');
  const limits=await db.query('SELECT free_emails,unlimited,daily_limit,daily_unlimited,note,updated_at FROM public.user_limits WHERE user_id=$1',[id]);
  const subscription=await db.query('SELECT email,starts_at,ends_at,note,updated_at,(starts_at<=now() AND (ends_at IS NULL OR ends_at>now())) active FROM public.subscriptions WHERE email=public.plan_email($1)',[user.email]);
  const apps=await db.query('SELECT count(user_id)::integer count FROM public.applications WHERE user_id=$1',[id]);
  const devices=await db.query('SELECT count(id)::integer count FROM public.app_devices WHERE user_id=$1',[id]);
  const state={status:user.status,email:user.email,limits:limits.rows[0]||null,subscription:subscription.rows[0]||null};
  const cv=(await db.query('SELECT file_name,file_type,file_size,pages,created_at FROM public.user_cvs WHERE user_id=$1',[id])).rows[0]||null;
  const gmail=(await db.query('SELECT address,sender_name,status,error,checked_at FROM public.mail_accounts WHERE user_id=$1',[id])).rows[0]||null;
  const profile=(await db.query('SELECT headline,level,years_experience,search_scope FROM public.user_profiles WHERE user_id=$1',[id])).rows[0]||null;
  const auto=(await db.query('SELECT enabled,min_match,daily_limit,gap_minutes,next_send_at,paused_until,pause_reason FROM public.auto_apply WHERE user_id=$1',[id])).rows[0]||null;
  const emailStats=(await db.query("SELECT count(user_id) FILTER(WHERE status='sent')::integer sent,count(user_id) FILTER(WHERE status='failed')::integer failed,count(user_id) FILTER(WHERE status IN ('sent','sending'))::integer used,count(user_id) FILTER(WHERE status IN ('sent','sending') AND coalesce(sent_at,created_at)>now()-interval '24 hours')::integer sent_24h FROM public.applications WHERE user_id=$1 AND method='email'",[id])).rows[0];
  const emails=(await db.query("SELECT opportunity_id,status,error,auto,recipient,coalesce(sent_at,updated_at,created_at) at,job->>'title' title,job->>'company' company FROM public.applications WHERE user_id=$1 AND method='email' ORDER BY updated_at DESC LIMIT 100",[id])).rows;
  const perDay=(await db.query(`WITH days AS(SELECT generate_series((now() AT TIME ZONE 'Africa/Cairo')::date-13,(now() AT TIME ZONE 'Africa/Cairo')::date,interval '1 day')::date d) SELECT d::text AS "day",count(a.user_id)::integer emails FROM days LEFT JOIN public.applications a ON a.user_id=$1 AND a.method='email' AND a.status='sent' AND(a.sent_at AT TIME ZONE 'Africa/Cairo')::date=d GROUP BY d ORDER BY d`,[id])).rows;
  const changes=(await db.query("SELECT created_at,admin,action,details->>'reason' reason FROM public.admin_log WHERE user_id=$1 ORDER BY created_at DESC,id DESC LIMIT 20",[id])).rows;
  return {...user,limits:state.limits,subscription:state.subscription,applications:apps.rows[0].count,devices:devices.rows[0].count,revision:hash(state),cv,gmail,profile,auto_apply:auto,email_stats:emailStats,emails,per_day:perDay,changes};
}
async function audit(db,admin,{id=null,email=null,action,reason='',before=null,after=null,requestId}){
  await db.query('INSERT INTO public.admin_log(admin,actor_id,user_id,email,action,details,before_state,after_state,request_id) VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9)',[admin.username,admin.id,id,email,action,{reason},before,after,requestId]);
}
export function registerConsole(app,{db,auth,serviceURLs={},operationServices={}}){
  const overviews=new Map();
  app.register(async consoleApp=>{
    consoleApp.decorateRequest('admin',null);
    consoleApp.addHook('onRequest',async request=>{
      const write=!['GET','HEAD'].includes(request.method);request.admin=await auth.authenticate(request,{write,elevated:write});
    });
    registerConsoleOperations(consoleApp,{db,services:operationServices});
    consoleApp.get('/admin/api/overview',{schema:{querystring:{type:'object',additionalProperties:false,properties:{days:{enum:['14','30','90']}}}}},async request=>{
      const days=Number(request.query.days||30),cached=overviews.get(days);if(cached?.expires>Date.now())return cached.value;
      const value=(await db.query('SELECT public.console_overview($1) data',[days])).rows[0].data;
      // Keep existing overview DTO consumers working while adding the reference analytics.
      value.email={sent:value.emails.last_30d,failed:value.emails.failed_30d};value.auto_enabled=value.auto_apply.on;value.cvs=value.auto_apply.with_cv;value.pro=value.plans.pro;value.history=value.series;
      overviews.set(days,{value,expires:Date.now()+15000});return value;
    });
    consoleApp.get('/admin/api/users',{schema:{querystring:{type:'object',additionalProperties:false,properties:{q:{type:'string',maxLength:100},filter:{enum:['all','pro','free','blocked','auto','active','new','custom','sending']},sort:{enum:['new','seen','sent','sent_24h','email']},offset:{type:'string',pattern:'^[0-9]{1,7}$'}}}}},async request=>{
      const offset=Number(request.query.offset||0),filter=request.query.filter||'all';
      const {rows}=await db.query('SELECT * FROM public.admin_users($1,$2,$3,$4,$5)',[request.query.q||null,filter,request.query.sort||'new',30,offset]);
      return {items:rows.map(({total_count,...row})=>row),total:rows.length?Number(rows[0].total_count):0,offset};
    });
    consoleApp.get('/admin/api/users/:id',{schema:{params:{type:'object',required:['id'],properties:{id:idSchema}}}},async request=>transaction(db,async connection=>{
      const user=await userDetail(connection,request.params.id);await audit(connection,request.admin,{id:user.id,email:user.email,action:'view_user',requestId:request.id});return user;
    }));
    consoleApp.put('/admin/api/users/:id',{schema:{params:{type:'object',required:['id'],properties:{id:idSchema}},body:bodySchema}},async request=>transaction(db,async connection=>{
      const {id}=request.params,{expected,reason,patch}=request.body;
      if((patch.months||patch.until||patch.forever)&&patch.plan!=='pro')throw new HttpError(422,'Pro duration requires a Pro change');
      if(patch.until){const date=new Date(patch.until+'T00:00:00Z');if(!Number.isFinite(+date)||date.toISOString().slice(0,10)!==patch.until)throw new HttpError(422,'Invalid Pro end date');}
      await connection.query('SELECT pg_advisory_xact_lock(hashtextextended($1,0))',['console:'+id]);
      const locked=(await connection.query('SELECT email FROM public.app_users WHERE id=$1 FOR UPDATE',[id])).rows[0];if(!locked)throw new HttpError(404,'Not found');
      if(locked.email)await connection.query('SELECT pg_advisory_xact_lock(hashtextextended($1,0))',['console-plan:'+locked.email.toLowerCase()]);
      const before=await userDetail(connection,id);if(before.revision!==expected)throw new HttpError(409,'changed_meanwhile');
      if(patch.status){await connection.query('UPDATE public.app_users SET status=$2 WHERE id=$1',[id,patch.status]);if(patch.status==='blocked')await connection.query('UPDATE public.auto_apply SET enabled=false,updated_at=now() WHERE user_id=$1',[id]);}
      if(['free_emails','daily_limit','unlimited','daily_unlimited','limits_note'].some(name=>Object.hasOwn(patch,name))){
        const free=Object.hasOwn(patch,'free_emails')?patch.free_emails:before.limits?.free_emails??null,daily=Object.hasOwn(patch,'daily_limit')?patch.daily_limit:before.limits?.daily_limit??null;
        const unlimited=patch.unlimited??before.limits?.unlimited??false,dailyUnlimited=patch.daily_unlimited??before.limits?.daily_unlimited??false,note=Object.hasOwn(patch,'limits_note')?patch.limits_note:before.limits?.note??null;
        if(free===null&&daily===null&&!unlimited&&!dailyUnlimited&&!note)await connection.query('DELETE FROM public.user_limits WHERE user_id=$1',[id]);
        else await connection.query('INSERT INTO public.user_limits(user_id,free_emails,daily_limit,unlimited,daily_unlimited,note,updated_by) VALUES($1,$2,$3,$4,$5,$6,$7) ON CONFLICT(user_id) DO UPDATE SET free_emails=EXCLUDED.free_emails,daily_limit=EXCLUDED.daily_limit,unlimited=EXCLUDED.unlimited,daily_unlimited=EXCLUDED.daily_unlimited,note=EXCLUDED.note,updated_by=EXCLUDED.updated_by,updated_at=now()',[id,free,daily,unlimited,dailyUnlimited,note,request.admin.username]);
      }
      if(patch.plan){
        if(!before.email)throw new HttpError(409,'no_email');
        if(patch.plan==='free')await connection.query('DELETE FROM public.subscriptions WHERE email=public.plan_email($1)',[before.email]);
        else{
          if([!!patch.months,!!patch.until,!!patch.forever].filter(Boolean).length>1)throw new HttpError(422,'Choose one Pro duration');
          if(patch.until&&!(await connection.query("SELECT $1::date >= (now() AT TIME ZONE 'Africa/Cairo')::date AND $1::date < current_date+interval '10 years' valid",[patch.until])).rows[0].valid)throw new HttpError(422,'Invalid Pro end date');
          await connection.query(`INSERT INTO public.subscriptions(email,starts_at,ends_at,note) VALUES(public.plan_email($1),now(),CASE WHEN $4::boolean THEN NULL WHEN $5::text IS NOT NULL THEN($5::date+1)::timestamp AT TIME ZONE 'Africa/Cairo' ELSE now()+$2*interval '1 month' END,$3) ON CONFLICT(email) DO UPDATE SET starts_at=CASE WHEN subscriptions.starts_at<=now() AND(subscriptions.ends_at IS NULL OR subscriptions.ends_at>now()) THEN subscriptions.starts_at ELSE now() END,ends_at=CASE WHEN $4::boolean THEN NULL WHEN $5::text IS NOT NULL THEN($5::date+1)::timestamp AT TIME ZONE 'Africa/Cairo' WHEN subscriptions.starts_at<=now() AND subscriptions.ends_at IS NULL THEN NULL ELSE(CASE WHEN subscriptions.starts_at<=now() AND subscriptions.ends_at>now() THEN subscriptions.ends_at ELSE now() END)+$2*interval '1 month' END,note=EXCLUDED.note,updated_at=now()`,[before.email,patch.months||1,reason,patch.forever||false,patch.until||null]);
        }
      }
      const after=await userDetail(connection,id),state=row=>({status:row.status,limits:row.limits,subscription:row.subscription});await audit(connection,request.admin,{id,email:before.email,action:'update_user',reason,before:state(before),after:state(after),requestId:request.id});overviews.clear();return after;
    }));
    consoleApp.get('/admin/api/subscriptions',async()=>({items:(await db.query('SELECT email,starts_at,ends_at,(starts_at<=now() AND (ends_at IS NULL OR ends_at>now())) active FROM public.subscriptions ORDER BY updated_at DESC LIMIT 100')).rows}));
    consoleApp.get('/admin/api/audit',async()=>({items:(await db.query("SELECT id,created_at,admin,email,action,details->>'reason' reason FROM public.admin_log ORDER BY created_at DESC,id DESC LIMIT 100")).rows}));
    consoleApp.get('/admin/api/health',async()=>({services:await Promise.all(Object.entries(serviceURLs).map(async([name,url])=>{
      try{const response=await fetch(new URL('/health/ready',url),{redirect:'error',signal:AbortSignal.timeout(2000)});await response.arrayBuffer();return {name,ready:response.ok};}catch{return {name,ready:false};}
    })),workers:(await db.query('SELECT name,seen_at FROM public.worker_heartbeats ORDER BY name')).rows}));
  });
}
