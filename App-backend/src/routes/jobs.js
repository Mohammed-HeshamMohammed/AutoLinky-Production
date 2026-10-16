import { HttpError,notFound } from '../../../backend-v2/shared/http/errors.js';
import { queryOf,filter,number,time,decodeCursor,encodeCursor,uuid,workModes,applyMethods,sources } from '../../../backend-v2/shared/contracts/query.js';
import { normalize } from '../../../backend-v2/shared/domain/text.js';

import { summaryColumns,summary,overlay,matched,countNewMatches } from '../../../backend-v2/shared/repositories/jobs.js';
const hasProfile=async(db,id)=>(await db.query('SELECT user_id FROM public.user_profiles WHERE user_id=$1',[id])).rowCount>0;
export function registerJobs(app,{db,cache,limiter}) {
  app.get('/v1/jobs',async request=>{
    const q=queryOf(request);const limit=number(q,'limit',20,1,50),days=number(q,'days',30,1,90);
    if((q.get('q')||'').length>100)throw new HttpError(422,"Invalid 'q'");
    let afterAt=null,afterId=null;
    if(q.get('cursor')){const c=decodeCursor(q.get('cursor'));if(!uuid.test(c.i)||typeof c.t!=='string'||!Number.isFinite(Date.parse(c.t)))throw new HttpError(400,'Invalid cursor');afterAt=c.t;afterId=c.i;}
    const slug=/^[a-z][a-z0-9_]{1,59}$/;
    const countries=q.getAll('country').map(c=>c.toUpperCase());
    if(countries.length>10 || countries.some(c=>!/^[A-Z]{2}$/.test(c)))throw new HttpError(422,"Invalid 'country' filter");
    const {rows}=await db.query(`SELECT f.*,f.posted_at::text AS posted_at FROM public.opportunity_feed($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14) f`,[
      normalize(q.get('q')||'')||null,filter(q,'field',null,slug),filter(q,'role',null,slug),filter(q,'skill',null,slug),
      countries.length?[...new Set(countries)]:null,filter(q,'work_mode',workModes),filter(q,'level',['intern','junior','mid','senior','manager','unknown']),
      filter(q,'apply',applyMethods),filter(q,'source',sources),filter(q,'language',['en','ar','de','fr','nl','es','pt','other']),
      new Date(Date.now()-days*86400000),afterAt,afterId,limit,
    ]);
    return {items:await overlay(db,request.user.id,rows.map(summary)),next_cursor:rows.length===limit?encodeCursor({t:rows.at(-1).posted_at,i:rows.at(-1).id}):null};
  });
  app.get('/v1/jobs/matched',async request=>{
    const q=queryOf(request);const limit=number(q,'limit',20,1,50),days=number(q,'days',30,1,90),min=number(q,'min_percent',0,0,100);
    let offset=0;if(q.get('cursor')){offset=decodeCursor(q.get('cursor')).o;if(!Number.isInteger(offset)||offset<0||offset>500)throw new HttpError(400,'Invalid cursor');}
    if(!await hasProfile(db,request.user.id))throw new HttpError(409,'Profile needed: set your roles and skills first');
    const rows=await matched(db,request.user.id,{days,limit,offset,min,wm:filter(q,'work_mode',workModes),apply:filter(q,'apply',applyMethods),source:filter(q,'source',sources)});
    const items=rows.map(r=>({...summary(r),match_percent:r.score||0,match_reasons:{role:r.reasons?.role||'skills_only',skills:r.reasons?.skills||[],missing:r.reasons?.missing||[],level:r.reasons?.level||'unknown',location:r.reasons?.location||'unknown'}}));
    return {items:await overlay(db,request.user.id,items),next_cursor:rows.length===limit && offset+limit<=500?encodeCursor({o:offset+limit}):null};
  });
  app.get('/v1/jobs/matched/new',async request=>{
    const q=queryOf(request),since=time(q.get('since'),'since'),now=new Date(),min=number(q,'min_percent',0,0,100);
    const count=await hasProfile(db,request.user.id)?await countNewMatches(db,request.user.id,new Date(Math.max(+since,+now-7*86400000)),min):0;
    return {count,now};
  });
  app.get('/v1/jobs/filters',async()=>cache.load('jobs:facets:30',600000,async()=>{
    return (await db.query('SELECT public.opportunity_facets($1) data',[new Date(Date.now()-30*86400000)])).rows[0].data||{};
  }));
  app.get('/v1/jobs/:job_id',async request=>{
    limiter.enforce(`job_detail:${request.user.id}`,300,3600);
    const id=request.params.job_id;if(!uuid.test(id))throw notFound();
    const row=(await db.query(`SELECT ${summaryColumns},source_ref,last_seen_at FROM public.opportunities WHERE id=$1`,[id])).rows[0];
    if(!row)throw notFound();
    let extra={description:null,author_url:null,contacts:[],company_url:null,location:null,applicants:null,industries:null,last_seen_at:row.last_seen_at};
    if(row.source==='post'){
      const post=(await db.query('SELECT post_text,author_url FROM public.hiring_posts WHERE id::text=$1',[row.source_ref])).rows[0];
      if(post)extra={...extra,description:post.post_text,author_url:post.author_url};
      extra.contacts=(await db.query('SELECT type,value,label FROM public.post_contacts WHERE post_id::text=$1',[row.source_ref])).rows;
    }else{
      const job=(await db.query('SELECT description,company_url,location,applicants,industries FROM public.linkedin_jobs WHERE job_id=$1',[row.source_ref])).rows[0];
      if(job)extra={...extra,...job};
    }
    return (await overlay(db,request.user.id,[{...summary(row),...extra}]))[0];
  });
}
