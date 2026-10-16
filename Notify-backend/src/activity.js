import { billing } from './billing.js';
import { countNewMatches } from '../../backend-v2/shared/repositories/jobs.js';
import { candidates } from './auto-apply.js';
export const defaultAuto={enabled:false,min_match:70,daily_limit:20,gap_minutes:5,enabled_at:null,next_send_at:null,paused_until:null,pause_reason:null};
export async function autoState(db,id,config){
  const [accounts,autos,cvs,hearts,plan]=await Promise.all([
    db.query('SELECT address,sender_name,status,error,checked_at,signature FROM public.mail_accounts WHERE user_id=$1',[id]),
    db.query('SELECT enabled,min_match,daily_limit,gap_minutes,enabled_at,next_send_at,paused_until,pause_reason FROM public.auto_apply WHERE user_id=$1',[id]),
    db.query('SELECT user_id FROM public.user_cv_files WHERE user_id=$1',[id]),
    db.query("SELECT seen_at FROM public.worker_heartbeats WHERE name='sender'"),billing(db,id,config),
  ]);
  const account=accounts.rows[0]||null,auto={...defaultAuto,...autos.rows[0]},connected=!!account&&account.status!=='invalid',paused=auto.paused_until&&new Date(auto.paused_until)>new Date();
  let problem=account?.status==='invalid'?'email_invalid':connected?(!cvs.rowCount?'no_cv':!plan.canSend?'free_limit':paused?auto.pause_reason||'gmail_busy':auto.enabled&&(!hearts.rows[0]||Date.now()-new Date(hearts.rows[0].seen_at)>600000)?'sender_offline':null):null;
  let waiting=null;if(connected)try{waiting=(await candidates(db,id,auto.min_match)).length;}catch{}
  return {email_connected:connected,email:account,enabled:auto.enabled,min_match:auto.min_match,daily_limit:plan.daily===null?auto.daily_limit:Math.min(auto.daily_limit,plan.daily),gap_minutes:auto.gap_minutes,sent_today:plan.dailyUsed,next_send_at:auto.enabled?auto.next_send_at:null,paused_until:paused?auto.paused_until:null,problem,
    waiting,plan:plan.pro?'pro':'free',free_limit:plan.limit,free_used:plan.used,free_left:plan.left,pro_until:plan.until,upgrade_url:plan.upgradeUrl};
}
export async function activitySince(db,id,after,config){
  const now=new Date(),since=new Date(Math.max(+after,+now-7*86400000));
  const rows=(await db.query("SELECT opportunity_id,job,status,error,updated_at FROM public.applications WHERE user_id=$1 AND auto AND status IN ('sent','failed') AND updated_at>$2 ORDER BY updated_at LIMIT 20",[id,since])).rows;
  const state=await autoState(db,id,config);let count=0;try{count=await countNewMatches(db,id,since,60);}catch{}
  return {items:rows.map(r=>({job_id:r.opportunity_id,title:r.job.title||'',company:r.job.company||null,status:r.status,error:r.error||null,at:r.updated_at})),enabled:state.enabled,problem:state.problem,new_matches:count,now};
}
