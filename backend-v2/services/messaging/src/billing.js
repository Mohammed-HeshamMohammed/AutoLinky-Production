export function normalizeEmail(value){return String(value||'').trim().toLowerCase().replace(/@googlemail\.com$/,'@gmail.com');}
export async function billing(db,id,config){
  const {rows}=await db.query(`SELECT u.email,l.free_emails,l.unlimited,l.daily_limit,l.daily_unlimited,
    s.ends_at pro_until,(s.email IS NOT NULL) subscription,
    (SELECT count(*)::int FROM public.applications a WHERE a.user_id=u.id AND a.method='email' AND a.status IN ('sent','sending')) used,
    (SELECT count(*)::int FROM public.applications a WHERE a.user_id=u.id AND a.method='email' AND a.status IN ('sent','sending') AND coalesce(a.sent_at,a.created_at)>now()-interval '24 hours') daily_used
    FROM public.app_users u LEFT JOIN public.user_limits l ON l.user_id=u.id
    LEFT JOIN public.subscriptions s ON s.email=public.plan_email(u.email) AND s.starts_at<=now() AND (s.ends_at IS NULL OR s.ends_at>now()) WHERE u.id=$1`,[id]);
  const row=rows[0]||{},pro=!!(row.unlimited||row.subscription),limit=row.free_emails??config.freeEmails,used=row.used||0;
  const message=config.upgradeMessage+(row.email?`\nMy Autolinky account: ${normalizeEmail(row.email)}`:'');
  return {pro,limit,used,left:pro?null:Math.max(0,limit-used),canSend:pro||used<limit,until:row.pro_until||null,daily:row.daily_unlimited?null:row.daily_limit??config.dailyEmails,dailyUsed:row.daily_used||0,
    upgradeUrl:`${config.upgradeUrl}${config.upgradeUrl.includes('?')?'&':'?'}text=${encodeURIComponent(message)}`};
}
