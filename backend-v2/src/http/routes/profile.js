import { HttpError } from '../errors.js';
import { transaction } from '../../db/client.js';
import { unique,uniqueText } from '../../shared/text.js';
import { countryCode } from '../../shared/countries.js';

export const profileColumns='headline,target_roles,target_fields,skills,extra_skills,level,years_experience,countries,remote_ok,languages,search_titles,search_scope,updated_at';
const slug={type:'string',pattern:'^[a-zA-Z][a-zA-Z0-9_]{1,59}$'};
const array=(items,maxItems)=>({anyOf:[{type:'array',items,maxItems},{type:'null'}]});
const nullable=value=>({anyOf:[value,{type:'null'}]});
export const profileSchema={type:'object',additionalProperties:false,properties:{
  headline:nullable({type:'string',maxLength:100}),target_roles:array(slug,5),target_fields:array(slug,5),skills:array(slug,60),
  extra_skills:array({type:'string',minLength:1,maxLength:80},30),level:nullable({enum:['intern','junior','mid','senior','manager']}),
  years_experience:nullable({type:'integer',minimum:0,maximum:60}),countries:array({type:'string',maxLength:60},15),remote_ok:nullable({type:'boolean'}),
  languages:array({enum:['en','ar','de','fr','nl','es','pt']},7),search_titles:array({type:'string',minLength:1,maxLength:80},8),
  search_scope:nullable({enum:['egypt','egypt_gulf','egypt_remote','egypt_gulf_remote','remote','worldwide']}),
}};
export async function readProfile(db,id){return (await db.query(`SELECT ${profileColumns} FROM public.user_profiles WHERE user_id=$1`,[id])).rows[0]||null;}
export async function saveProfile(db,id,values){
  const entries=Object.entries(values).filter(([key])=>profileColumns.split(',').includes(key)&&key!=='updated_at');
  const names=entries.map(([key])=>key),params=entries.map(([,value])=>value);
  const updates=names.map(name=>`${name}=EXCLUDED.${name}`);
  await db.query(`INSERT INTO public.user_profiles(user_id${names.length?','+names.join(','):''}) VALUES($1${params.map((_,i)=>`,$${i+2}`).join('')})
    ON CONFLICT(user_id) DO UPDATE SET ${[...updates,'updated_at=now()'].join(',')}`,[id,...params]);
  return readProfile(db,id);
}
export async function searchStatus(db,id){
  const ask=(await db.query("SELECT titles,searched FROM public.user_searches WHERE user_id=$1 AND done_at IS NULL AND requested_at>now()-interval '1 hour'",[id])).rows[0];
  const keys=ask?.titles || (await db.query('SELECT search_keys FROM public.user_profiles WHERE user_id=$1',[id])).rows[0]?.search_keys || [];
  const rows=(await db.query('SELECT title,active,last_searched_at FROM public.search_titles WHERE title=ANY($1::text[])',[keys])).rows;
  const found=new Map(rows.map(r=>[r.title,r]));
  const titles=keys.map(title=>{const row=found.get(title);return {title,status:!row||!row.active?'skipped':ask?(ask.searched.includes(title)?'searched':'searching'):(row.last_searched_at?'searched':'searching')};});
  return {titles,searching:titles.some(t=>t.status==='searching')};
}
export function registerProfile(app,{db,limiter}){
  app.get('/v1/profile',async request=>{const row=await readProfile(db,request.user.id);if(!row)throw new HttpError(404,'no_profile');return row;});
  app.put('/v1/profile',{schema:{body:profileSchema}},async request=>{
    const values={},unknown={};
    for(const [key,raw] of Object.entries(request.body)){
      const value=typeof raw==='string'?raw.trim():Array.isArray(raw)?raw.map(v=>typeof v==='string'?v.trim():v):raw;
      if(['target_roles','target_fields','skills'].includes(key)){
        const table={target_roles:'job_roles',target_fields:'job_fields',skills:'skills'}[key];
        const items=unique((value||[]).map(v=>v.toLowerCase()));
        const valid=new Set((await db.query(`SELECT slug FROM public.${table} WHERE active AND slug=ANY($1::text[])`,[items])).rows.map(r=>r.slug));
        const bad=items.filter(v=>!valid.has(v));if(bad.length)unknown[key]=bad;values[key]=items;
      }else if(key==='countries'){
        const bad=(value||[]).filter(v=>!countryCode(v));if(bad.length)unknown[key]=bad;values[key]=unique((value||[]).map(countryCode).filter(Boolean));
      }else if(['extra_skills','search_titles'].includes(key))values[key]=uniqueText(value||[]);
      else if(key==='languages')values[key]=unique(value||[]);
      else if(key==='remote_ok'){if(value!==null)values[key]=value;}
      else values[key]=value===''?null:value;
    }
    if(Object.keys(unknown).length)throw new HttpError(422,{code:'unknown_values',unknown});
    return transaction(db,async connection=>{
      await connection.query('SELECT pg_advisory_xact_lock(hashtextextended($1,0))',[`profile:${request.user.id}`]);
      const existing=await readProfile(connection,request.user.id);
      if(!existing && !('languages' in values))values.languages=['en','ar'];
      if(existing && !Object.keys(values).length)return existing;
      return saveProfile(connection,request.user.id,values);
    });
  });
  app.get('/v1/profile/search-status',request=>searchStatus(db,request.user.id));
  app.post('/v1/profile/search-now',async request=>{
    limiter.enforce(`search_now:${request.user.id}`,12,3600);
    await db.query(`INSERT INTO public.user_searches(user_id,titles) SELECT user_id,search_keys FROM public.user_profiles WHERE user_id=$1 AND cardinality(search_keys)>0
      ON CONFLICT(user_id) DO UPDATE SET titles=EXCLUDED.titles,searched='{}',requested_at=now(),started_at=NULL,done_at=NULL
      WHERE user_searches.done_at IS NOT NULL OR user_searches.requested_at<now()-interval '1 hour' OR user_searches.titles<>EXCLUDED.titles`,[request.user.id]);
    return searchStatus(db,request.user.id);
  });
}
