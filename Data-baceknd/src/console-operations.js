import {createHash} from 'node:crypto';
import {HttpError} from '../lib/http/errors.js';
import {transaction} from '../lib/db/client.js';
const revision=row=>createHash('sha256').update(JSON.stringify(row)).digest('hex');
const reason={type:'string',minLength:5,maxLength:500},expected={type:'string',pattern:'^[a-f0-9]{64}$'};
const body=properties=>({body:{type:'object',additionalProperties:false,required:Object.keys(properties),properties}});
async function capability(url,key,path){
  if(!url||!key)return {connected:false};
  try{const response=await fetch(new URL(path,url),{headers:{'x-service-key':key},redirect:'error',signal:AbortSignal.timeout(2500)});if(!response.ok)throw Error();return {...await response.json(),connected:true};}catch{return {connected:false};}
}
async function control(db,service){const row=(await db.query('SELECT service,paused,version,updated_at,updated_by FROM public.console_service_control WHERE service=$1',[service])).rows[0];return {...row,revision:revision(row)};}
async function record(db,request,action,reason,before,after){await db.query('INSERT INTO public.admin_log(admin,actor_id,action,details,before_state,after_state,request_id) VALUES($1,$2,$3,$4,$5,$6,$7)',[request.admin.username,request.admin.id,action,{reason},before,after,request.id]);}
export function registerConsoleOperations(app,{db,services={}}){
  const fetchStatus=()=>capability(services.fetching,services.fetchingKey,'/internal/v1/admin/collector-status');
  const senderStatus=()=>capability(services.messaging,services.messagingKey,'/internal/v1/admin/sender-status');
  app.get('/admin/api/collector',async()=>({control:await control(db,'collector'),runtime:await fetchStatus(),legacy_linkedin_worker:false,batches:(await db.query('SELECT status,count(id)::integer count FROM public.ingestion_batches GROUP BY status')).rows}));
  app.get('/admin/api/accounts',async()=>({supported:false,reason:'linkedin_worker_not_ported',runtime:await fetchStatus()}));
  app.get('/admin/api/sender',async()=>({control:await control(db,'sender'),runtime:await senderStatus(),heartbeat:(await db.query("SELECT seen_at FROM public.worker_heartbeats WHERE name='sender'")).rows[0]?.seen_at||null,stats:(await db.query(`SELECT count(user_id) FILTER(WHERE auto AND status='sent' AND sent_at>now()-interval '1 hour')::integer sent_1h,count(user_id) FILTER(WHERE auto AND status='sent' AND sent_at>now()-interval '24 hours')::integer sent_24h,count(user_id) FILTER(WHERE NOT auto AND status='sent' AND sent_at>now()-interval '24 hours')::integer manual_24h,count(user_id) FILTER(WHERE auto AND status='failed' AND updated_at>now()-interval '24 hours')::integer failed_24h,count(user_id) FILTER(WHERE status IN ('queued','sending'))::integer sending FROM public.applications WHERE method='email'`)).rows[0]}));
  app.put('/admin/api/controls/:service',{schema:{...body({expected,reason,paused:{type:'boolean'}}),params:{type:'object',required:['service'],properties:{service:{enum:['collector','sender']}}}}},async request=>transaction(db,async connection=>{
    const service=request.params.service;
    await connection.query('SELECT service FROM public.console_service_control WHERE service=$1 FOR UPDATE',[service]);
    const before=await control(connection,service);if(before.revision!==request.body.expected)throw new HttpError(409,'changed_meanwhile');
    await connection.query('UPDATE public.console_service_control SET paused=$2,version=version+1,updated_at=now(),updated_by=$3 WHERE service=$1',[service,request.body.paused,request.admin.username]);
    const after=await control(connection,service);await record(connection,request,service+(after.paused?'_pause':'_resume'),request.body.reason,before,after);return after;
  }));
  app.get('/admin/api/search-titles',{schema:{querystring:{type:'object',additionalProperties:false,properties:{q:{type:'string',maxLength:80},show:{enum:['all','searched','manual','off','unwanted']},offset:{type:'string',pattern:'^[0-9]{1,6}$'}}}}},async request=>{
    const {q='',show='all',offset='0'}=request.query;
    const result=await db.query(`SELECT t.*,count(*) OVER()::integer total_count,coalesce(a.runs,0)::integer runs,coalesce(a.saved,0)::integer saved,a.last_run_at,a.next_run_at FROM public.search_titles t LEFT JOIN LATERAL(SELECT sum(runs) runs,sum(total_saved) saved,max(last_run_at) last_run_at,min(next_run_at) next_run_at FROM public.search_queries q WHERE q.title=t.title) a ON true WHERE ($1='' OR position(lower($1) in lower(t.title))>0) AND CASE $2 WHEN 'searched' THEN coalesce(t.active,true) AND(t.users>0 OR t.manual) WHEN 'manual' THEN t.manual WHEN 'off' THEN NOT coalesce(t.active,true) WHEN 'unwanted' THEN t.users=0 AND NOT t.manual ELSE true END ORDER BY t.users DESC,t.title LIMIT 50 OFFSET $3`,[q,show,Number(offset)]);
    return {items:result.rows.map(({total_count,...row})=>({...row,revision:revision({id:row.id,title:row.title,active:row.active,manual:row.manual,users:row.users,last_searched_at:row.last_searched_at})})),total:result.rows[0]?.total_count||0,offset:Number(offset),worker_connected:false};
  });
  app.post('/admin/api/search-titles',{schema:body({title:{type:'string',minLength:2,maxLength:80},reason})},async request=>transaction(db,async connection=>{
    await connection.query("SELECT pg_advisory_xact_lock(hashtext('autolinky.search_titles'))");
    const title=(await connection.query('SELECT public.search_title_key($1) title',[request.body.title])).rows[0].title;if(!title)throw new HttpError(422,'invalid_title');
    const result=await connection.query('INSERT INTO public.search_titles(title,canonical,manual,active) VALUES($1,$2,true,true) ON CONFLICT(title) DO NOTHING RETURNING id,title,active,manual',[title,request.body.title.trim()]);if(!result.rowCount)throw new HttpError(409,'title_exists');
    await record(connection,request,'title_add',request.body.reason,null,result.rows[0]);return result.rows[0];
  }));
  app.put('/admin/api/search-titles/:id',{schema:{...body({expected,reason,action:{enum:['enable','disable','manual','automatic','search','delete']}}),params:{type:'object',required:['id'],properties:{id:{type:'string',format:'uuid'}}}}},async request=>transaction(db,async connection=>{
    await connection.query("SELECT pg_advisory_xact_lock(hashtext('autolinky.search_titles'))");
    const before=(await connection.query('SELECT id,title,active,manual,users,last_searched_at FROM public.search_titles WHERE id=$1 FOR UPDATE',[request.params.id])).rows[0];if(!before)throw new HttpError(404,'Not found');if(revision(before)!==request.body.expected)throw new HttpError(409,'changed_meanwhile');
    const action=request.body.action;if(action==='delete'){
      if(request.admin.role!=='owner')throw new HttpError(403,'Forbidden');if(before.users>0)throw new HttpError(409,'has_users');await connection.query('DELETE FROM public.search_titles WHERE id=$1',[before.id]);
    }else if(['enable','disable'].includes(action))await connection.query('UPDATE public.search_titles SET active=$2 WHERE id=$1',[before.id,action==='enable']);
    else if(['manual','automatic'].includes(action))await connection.query('UPDATE public.search_titles SET manual=$2 WHERE id=$1',[before.id,action==='manual']);
    else{if(before.active===false||before.users===0&&!before.manual)throw new HttpError(409,'title_not_active');await connection.query('UPDATE public.search_titles SET last_searched_at=NULL WHERE id=$1',[before.id]);await connection.query('UPDATE public.search_queries SET next_run_at=now() WHERE title=$1',[before.title]);}
    await record(connection,request,'title_'+action,request.body.reason,before,{id:before.id,action});return {saved:true,worker_connected:false};
  }));
}
