import { readFile } from 'node:fs/promises';
import { jobTitle } from '../email/composition.js';
import { redactContacts } from './cv-analysis.js';
import { durableLimit } from '../http/rate-limit.js';
import { AIUnavailable } from './client.js';
const system=await readFile(new URL('./prompts/letter-system.txt',import.meta.url),'utf8');
export function cleanBody(content){
  if(typeof content!=='string'||!content.trim())throw new AIUnavailable('Empty letter');
  let lines=content.replaceAll('\r\n','\n').trim().split('\n').map(s=>s.trimEnd());
  while(lines.length&&(/^\s*(dear\b|to whom|hello\b|hi\b)/i.test(lines[0])||!lines[0].trim()))lines.shift();
  const index=lines.findIndex(s=>/^\s*(sincerely|best regards|kind regards|warm regards|regards|yours (truly|faithfully|sincerely)|best wishes|thank you,?\s*$)/i.test(s));
  if(index>=0)lines=lines.slice(0,index);
  const body=lines.map(s=>s.replace(/^\s*(?:[-*•]\s+|#+\s*)/,'').replaceAll('**','').replaceAll('__','')).join('\n').replace(/\n{3,}/g,'\n\n').trim();
  const words=body.split(/\s+/).length;
  if(/\[[^\]\n]{2,40}\]|\{[^}\n]{2,40}\}|<[^>\n]{2,40}>/.test(body)||words<90||words>420)throw new AIUnavailable('Unusable letter');
  return body;
}
async function jobText(db,job){
  if(!job.source_ref)return job.snippet||'';
  const {rows}=job.source==='linkedin_job'?await db.query('SELECT description text FROM public.linkedin_jobs WHERE job_id=$1',[job.source_ref]):await db.query('SELECT post_text text FROM public.hiring_posts WHERE id::text=$1',[job.source_ref]);
  return rows[0]?.text||job.snippet||'';
}
export function letterService({db,config,ai}){
  const inflight=new Map();
  return async function letterBody(id,job,cv){
    const existing=(await db.query('SELECT body,cv_sha256 FROM public.cover_letters WHERE user_id=$1 AND opportunity_id=$2',[id,job.id])).rows[0];
    if(existing?.cv_sha256===cv.sha256&&existing.body)return existing.body;
    if(!cv.text?.trim()||!ai)return null;
    const key=`${id}:${job.id}:${cv.sha256}`;
    if(inflight.has(key))return inflight.get(key);
    if(inflight.size>=64)return null;
    const pending=(async()=>{
      try{
        await durableLimit(db,'letter_ai:all',300,86400);
        const post=await jobText(db,job),result=await ai.ask({model:config.letterModel,json:false,maxTokens:900,temperature:0.2,messages:[
          {role:'system',content:system.replace('{{today}}',new Date().toISOString().slice(0,10))},
          {role:'user',content:`Job title: ${jobTitle(job.title)}\nCompany: ${job.company||'not given'}\nJob post:\n<<<\n${post.trim().slice(0,3500)}\n>>>\n\nCV:\n<<<\n${redactContacts(cv.text).slice(0,9000)}\n>>>`},
        ]});
        const body=cleanBody(result.data);
        try{await db.query(`INSERT INTO public.cover_letters(user_id,opportunity_id,cv_sha256,body,model) VALUES($1,$2,$3,$4,$5)
          ON CONFLICT(user_id,opportunity_id) DO UPDATE SET cv_sha256=EXCLUDED.cv_sha256,body=EXCLUDED.body,model=EXCLUDED.model,created_at=now()`,[id,job.id,cv.sha256,body,config.letterModel]);}catch{}
        return body;
      }catch{return null;}
    })().finally(()=>inflight.delete(key));
    inflight.set(key,pending);return pending;
  };
}
