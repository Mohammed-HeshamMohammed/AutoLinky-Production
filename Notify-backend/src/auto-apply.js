import { randomInt } from 'node:crypto';
import { validAddress } from './email/composition.js';
import { billing } from './billing.js';

export async function candidates(db,id,minMatch,{now=new Date(),limit=50,appData}={}){
  const found=[];
  for(let page=0;page<5;page++){
    const rows=await appData.matches(id,{days:14,limit:100,offset:page*100,min:minMatch,apply:['email'],source:['post']});
    if(!rows.length)break;
    const ids=rows.map(r=>r.id);
    const [applied,recent]=await Promise.all([
      db.query('SELECT opportunity_id FROM public.applications WHERE user_id=$1 AND opportunity_id=ANY($2::uuid[])',[id,ids]),
      db.query("SELECT recipient FROM public.applications WHERE user_id=$1 AND created_at>$2 AND recipient IS NOT NULL",[id,new Date(+now-30*86400000)]),
    ]);
    const used=new Set(applied.rows.map(r=>r.opportunity_id)),cooldown=new Set(recent.rows.map(r=>r.recipient)),byId=new Map();
    for(const row of rows)byId.set(row.id,{source_ref:row.source_ref,recipient:(row.email_contacts||[]).map(validAddress).find(Boolean)});
    for(const row of rows){if(used.has(row.id))continue;const contact=byId.get(row.id);if(contact?.recipient&&!cooldown.has(contact.recipient))found.push({...row,...contact});}
    const sorted=[...found].sort((a,b)=>b.score-a.score||Date.parse(b.posted_at)-Date.parse(a.posted_at)||b.id.localeCompare(a.id));
    if(rows.length<100 || sorted.length>=limit && sorted[limit-1].score>=rows.at(-1).score+5)break;
  }
  const recipients=new Set();return found.sort((a,b)=>b.score-a.score||Date.parse(b.posted_at)-Date.parse(a.posted_at)||b.id.localeCompare(a.id)).filter(r=>{if(recipients.has(r.recipient))return false;recipients.add(r.recipient);return true;}).slice(0,limit);
}
export function inHours(hour,range){const [start,end]=range.split('-').map(Number);return start<=end?hour>=start&&hour<end:hour>=start||hour<end;}
export async function senderTick({db,config,mail,signal,now=new Date(),pickCandidates=candidates,appData}){
  await db.query("INSERT INTO public.worker_heartbeats(name,seen_at) VALUES('sender',$1) ON CONFLICT(name) DO UPDATE SET seen_at=EXCLUDED.seen_at",[now]);
  const hour=Number(new Intl.DateTimeFormat('en-GB',{timeZone:config.senderTimezone,hour:'2-digit',hourCycle:'h23'}).format(now));
  if(!inHours(hour,config.senderHours))return 0;
  const due=(await db.query(`SELECT a.user_id,a.min_match,a.daily_limit,a.gap_minutes FROM public.auto_apply a
    JOIN public.app_users u ON u.id=a.user_id WHERE a.enabled AND u.status='active' AND a.next_send_at<=$1
    AND (a.paused_until IS NULL OR a.paused_until<=$1) ORDER BY a.next_send_at LIMIT 100`,[now])).rows;
  let sent=0;
  for(const auto of due){
    if(signal?.aborted)break;
    const claim=await db.query("UPDATE public.auto_apply SET next_send_at=$2::timestamptz+interval '10 minutes' WHERE user_id=$1 AND enabled AND next_send_at<=$2 RETURNING user_id",[auto.user_id,now]);
    if(!claim.rowCount)continue;
    let delay=15*60000;
    try{
      const plan=await billing(db,auto.user_id,config),daily=plan.daily===null?auto.daily_limit:Math.min(auto.daily_limit,plan.daily);
      const hourly=(await db.query("SELECT count(*)::int n FROM public.applications WHERE user_id=$1 AND method='email' AND status IN ('sent','sending') AND coalesce(sent_at,created_at)>$2::timestamptz-interval '1 hour'",[auto.user_id,now])).rows[0].n;
      if(!plan.canSend||plan.dailyUsed>=daily||hourly>=15){delay=3600000;continue;}
      const jobs=await pickCandidates(db,auto.user_id,auto.min_match,{now,limit:1,appData});if(!jobs.length)continue;
      const user=(await db.query('SELECT id,email,status FROM public.app_users WHERE id=$1',[auto.user_id])).rows[0];if(user?.status!=='active')continue;
      const result=await mail.send(user,jobs[0],null,{auto:true});
      if(result.status==='sent')sent++;
      // Sending is also delayed: an uncertain previous attempt never accelerates another turn.
      const gap=Math.min(120,Math.max(3,auto.gap_minutes));delay=randomInt(gap*60000,Math.ceil(gap*90000)+1);
    }catch{delay=3600000;}
    finally{await db.query('UPDATE public.auto_apply SET next_send_at=$2 WHERE user_id=$1',[auto.user_id,new Date(+now+delay)]);}
  }
  return sent;
}
