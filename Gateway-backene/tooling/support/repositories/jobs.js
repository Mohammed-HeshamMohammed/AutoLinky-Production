export const summaryColumns='id,source,title,company,city,country,country_code,work_mode,level,employment_type,field,role,skills,apply_methods,language,snippet,url,posted_at';
const columns=summaryColumns.split(',');
export function summary(row) {
  const result=Object.fromEntries(columns.map(name=>[name,row[name]??(['skills','apply_methods'].includes(name)?[]:null)]));
  return {...result,application:null};
}
export async function overlay(db,userId,items) {
  if(!items.length)return items;
  let rows=[];
  try {rows=(await db.query('SELECT opportunity_id,method,status,created_at FROM public.applications WHERE user_id=$1 AND opportunity_id=ANY($2::uuid[])',[userId,items.map(i=>i.id)])).rows;}catch{}
  const states=new Map(rows.map(r=>[r.opportunity_id,{method:r.method,status:r.status==='sending'?'queued':r.status,applied_at:r.created_at}]));
  return items.map(item=>({...item,application:states.get(item.id)||null}));
}
export async function matched(db,userId,{days=30,limit=20,offset=0,min=0,wm=null,apply=null,source=null}={}) {
  const {rows}=await db.query(`SELECT f.*,f.posted_at::text AS posted_at FROM public.match_opportunities($1,$2,$3,$4,$5,$6,$7,$8) f`,
    [userId,new Date(Date.now()-days*86400000),limit,offset,wm,apply,source,min]);
  return rows;
}
export async function countNewMatches(db,userId,since,min=0) {
  const rows=await matched(db,userId,{limit:50,min});
  if(!rows.length)return 0;
  return (await db.query('SELECT id FROM public.opportunities WHERE id=ANY($1::uuid[]) AND created_at>$2',[rows.map(r=>r.id),since])).rowCount;
}
