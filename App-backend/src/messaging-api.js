import { summaryColumns,matched,countNewMatches } from '../lib/repositories/jobs.js';
import { notFound } from '../lib/http/errors.js';

export const messagingPaths=['/internal/v1/messaging/snapshot','/internal/v1/messaging/job','/internal/v1/messaging/matches','/internal/v1/messaging/new-matches'];
const userSchema={type:'string',format:'uuid'};
export function messagingRepository(db){
  async function contacts(rows){
    if(!rows.length)return rows;
    const found=(await db.query("SELECT o.id,p.value FROM public.opportunities o JOIN public.post_contacts p ON p.post_id::text=o.source_ref AND p.type='email' WHERE o.id=ANY($1::uuid[]) ORDER BY p.id",[rows.map(row=>row.id)])).rows;
    return rows.map(row=>({...row,email_contacts:found.filter(value=>value.id===row.id).map(value=>value.value)}));
  }
  return {
    async snapshot(user_id,include_bytes=false){
      const cv=(await db.query('SELECT file_name,file_type,text,links,sha256 FROM public.user_cvs WHERE user_id=$1',[user_id])).rows[0]||null;
      const profile=(await db.query('SELECT headline,years_experience,skills FROM public.user_profiles WHERE user_id=$1',[user_id])).rows[0]||{};
      const skill_names=profile.skills?.length?(await db.query('SELECT slug,name FROM public.skills WHERE slug=ANY($1::text[])',[profile.skills])).rows:[];
      const file=(await db.query('SELECT '+(include_bytes?'bytes':'user_id')+' FROM public.user_cv_files WHERE user_id=$1',[user_id])).rows[0];
      return {cv,profile,skill_names,has_file:!!file,...(include_bytes&&file?{bytes:file.bytes.toString('base64')}: {})};
    },
    async job(job_id){
      const row=(await db.query(`SELECT ${summaryColumns},source_ref FROM public.opportunities WHERE id=$1`,[job_id])).rows[0];
      if(!row)throw notFound();
      let body_text=row.snippet||'';
      if(row.source_ref){const result=row.source==='linkedin_job'?await db.query('SELECT description text FROM public.linkedin_jobs WHERE job_id=$1',[row.source_ref]):await db.query('SELECT post_text text FROM public.hiring_posts WHERE id::text=$1',[row.source_ref]);body_text=result.rows[0]?.text||body_text;}
      return {...(await contacts([row]))[0],body_text};
    },
    async matches(user_id,options){return contacts(await matched(db,user_id,options));},
    newMatches:(user_id,since,min)=>countNewMatches(db,user_id,new Date(since),min),
  };
}
export function registerMessagingAPI(app,{db}){
  const repository=messagingRepository(db);
  const route=(path,properties,required,handler)=>app.post(path,{schema:{body:{type:'object',additionalProperties:false,properties,required}}},handler);
  route(messagingPaths[0],{user_id:userSchema,include_bytes:{type:'boolean'}},['user_id'],request=>repository.snapshot(request.body.user_id,request.body.include_bytes));
  route(messagingPaths[1],{job_id:userSchema},['job_id'],request=>repository.job(request.body.job_id));
  route(messagingPaths[2],{user_id:userSchema,options:{type:'object',additionalProperties:false,properties:{days:{type:'integer',minimum:1,maximum:90},limit:{type:'integer',minimum:1,maximum:100},offset:{type:'integer',minimum:0,maximum:500},min:{type:'integer',minimum:0,maximum:100},apply:{type:'array',maxItems:4,items:{enum:['email','external','easy_apply','whatsapp']}},source:{type:'array',maxItems:2,items:{enum:['post','linkedin_job']}}}}},['user_id'],request=>repository.matches(request.body.user_id,request.body.options));
  route(messagingPaths[3],{user_id:userSchema,since:{type:'string',format:'date-time'},min:{type:'integer',minimum:0,maximum:100}},['user_id','since'],async request=>({count:await repository.newMatches(request.body.user_id,request.body.since,request.body.min||0)}));
}
