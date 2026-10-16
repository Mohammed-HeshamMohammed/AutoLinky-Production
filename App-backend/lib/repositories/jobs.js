export const summaryColumns='id,source,title,company,city,country,country_code,work_mode,level,employment_type,field,role,skills,apply_methods,language,snippet,url,posted_at';
const columns=summaryColumns.split(',');
export function summary(row) {
  const result=Object.fromEntries(columns.map(name=>[name,row[name]??(['skills','apply_methods'].includes(name)?[]:null)]));
  return {...result,application:null};
}
export async function overlay(notifyData,userId,items) {
  if(!items.length)return items;
  const rows=await notifyData.overlay(userId,items.map(item=>item.id));
  const states=new Map(rows.map(row=>[row.opportunity_id,{method:row.method,status:row.status,applied_at:row.created_at}]));
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
