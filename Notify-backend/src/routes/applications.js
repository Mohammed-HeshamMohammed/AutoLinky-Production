import { HttpError,notFound } from '../../../backend-v2/shared/http/errors.js';
import { summary,summaryColumns } from '../../../backend-v2/shared/repositories/jobs.js';
import { queryOf,number,uuid,decodeCursor,encodeCursor,applyMethods } from '../../../backend-v2/shared/contracts/query.js';
import { transaction } from '../../../backend-v2/shared/db/client.js';
export function application(row){const status=row.status==='sending'?'queued':row.status;return {job:{...summary(row.job),application:{method:row.method,status,applied_at:row.created_at}},method:row.method,status,applied_at:row.created_at,error:row.error||null,auto:!!row.auto};}
export async function opportunity(db,id){if(!uuid.test(id))throw notFound();const row=(await db.query(`SELECT ${summaryColumns},source_ref FROM public.opportunities WHERE id=$1`,[id])).rows[0];if(!row)throw notFound();return row;}
export function registerApplications(app,{db,limiter,mail}){
  app.get('/v1/applications',async request=>{
    const q=queryOf(request),limit=number(q,'limit',20,1,50);let offset=0;
    if(q.get('cursor')){offset=decodeCursor(q.get('cursor')).o;if(!Number.isInteger(offset)||offset<0||offset>5000)throw new HttpError(400,'Invalid cursor');}
    const [data,count]=await Promise.all([db.query('SELECT opportunity_id,method,status,job,error,auto,created_at FROM public.applications WHERE user_id=$1 ORDER BY created_at DESC LIMIT $2 OFFSET $3',[request.user.id,limit,offset]),db.query('SELECT count(*)::int total FROM public.applications WHERE user_id=$1',[request.user.id])]);
    return {items:data.rows.map(application),total:count.rows[0].total,next_cursor:data.rows.length===limit&&offset+limit<=5000?encodeCursor({o:offset+limit}):null};
  });
  app.post('/v1/applications',{schema:{body:{type:'object',additionalProperties:false,required:['job_id','method'],properties:{job_id:{type:'string',format:'uuid'},method:{enum:applyMethods},letter:{type:['string','null'],maxLength:8000}}}}},async(request,reply)=>{
    limiter.enforce(`apply:${request.user.id}`,120,3600);
    const job=await opportunity(db,request.body.job_id),method=request.body.method;
    if(!job.apply_methods.includes(method)&&!(job.source==='linkedin_job'&&!job.apply_methods.length&&['easy_apply','external'].includes(method)))throw new HttpError(422,'method_not_offered');
    if(method==='email'){if(!mail)throw new HttpError(503,'mail_unavailable');return reply.code(201).send(application(await mail.send(request.user,job,request.body.letter)));}
    const row=await transaction(db,async c=>{
      await c.query('SELECT pg_advisory_xact_lock(hashtextextended($1,0))',[`mail:${request.user.id}`]);
      const existing=(await c.query('SELECT * FROM public.applications WHERE user_id=$1 AND opportunity_id=$2 FOR UPDATE',[request.user.id,job.id])).rows[0];
      if(existing?.method==='email'&&['queued','sending','sent'].includes(existing.status))return existing;
      return (await c.query(`INSERT INTO public.applications(user_id,opportunity_id,method,status,job) VALUES($1,$2,$3,'applied',$4)
        ON CONFLICT(user_id,opportunity_id) DO UPDATE SET method=EXCLUDED.method,status='applied',job=EXCLUDED.job,error=NULL,auto=false,recipient=NULL,sent_at=NULL,letter=NULL,updated_at=now() RETURNING *`,[request.user.id,job.id,method,summary(job)])).rows[0];
    });return reply.code(201).send(application(row));
  });
  app.get('/v1/applications/email-preview',async request=>{limiter.enforce(`email_preview:${request.user.id}`,60,3600);const id=queryOf(request).get('job_id');if(!id||!uuid.test(id))throw new HttpError(422,'Invalid job_id');if(!mail)throw new HttpError(503,'mail_unavailable');return mail.preview(request.user,await opportunity(db,id));});
  app.delete('/v1/applications/:job_id',async(request,reply)=>{
    const id=request.params.job_id;if(!uuid.test(id))throw notFound();
    await transaction(db,async c=>{await c.query('SELECT pg_advisory_xact_lock(hashtextextended($1,0))',[`mail:${request.user.id}`]);
      const row=(await c.query('SELECT method,status FROM public.applications WHERE user_id=$1 AND opportunity_id=$2 FOR UPDATE',[request.user.id,id])).rows[0];
      if(row?.method==='email'&&['queued','sending','sent'].includes(row.status))throw new HttpError(409,'already_sent');
      await c.query('DELETE FROM public.applications WHERE user_id=$1 AND opportunity_id=$2',[request.user.id,id]);
    });return reply.code(204).send();
  });
}
