import { createHash } from 'node:crypto';
import { HttpError } from '../errors.js';
import { durableLimit } from '../rate-limit.js';
import { queryOf } from '../../contracts/query.js';
import { transaction } from '../../db/client.js';
import { extractCV } from '../../integrations/cv-extractor.js';
import { analyzeCV } from '../../ai/cv-analysis.js';
import { loadCatalog } from '../../services/catalog.js';
import { readProfile,saveProfile } from './profile.js';
import { unique } from '../../shared/text.js';

const infoColumns='file_name,file_type,file_size,pages,analysis,detected,created_at,analyzed_at';
const output=row=>({cv:{file_name:row.file_name,file_type:row.file_type,file_size:row.file_size,pages:row.pages??null,analysis:row.analysis,uploaded_at:row.created_at,analyzed_at:row.analyzed_at},detected:row.detected});
export function cleanFileName(name,type){const base=name.split(/[\\/]/).at(-1).normalize('NFC').replace(/\p{C}/gu,'').trim().replace(/\s+/g,' ').replace(/\.(pdf|docx?)$/i,'').replace(/^[ .]+|[ .]+$/g,'');return `${base.slice(0,100)||'CV'}.${type}`;}
async function limits(db,id){await durableLimit(db,`cv:${id}`,5,3600);await durableLimit(db,`cv_day:${id}`,10,86400);}
async function profileFromCV(db,id,detected){
  const existing=await readProfile(db,id),values={languages:unique([...detected.languages,'en','ar'])};
  for(const [name,value] of Object.entries({target_roles:detected.roles,skills:detected.skills,extra_skills:detected.extra_skills,search_titles:detected.search_titles,headline:detected.headline,level:detected.level,years_experience:detected.years_experience}))if((Array.isArray(value)?value.length:value)||name==='years_experience'&&value===0)values[name]=value;
  if(!existing){values.countries=detected.country?[detected.country]:[];values.remote_ok=true;}
  else if(!existing.countries.length&&detected.country)values.countries=[detected.country];
  return saveProfile(db,id,values);
}
export function registerCV(app,{db,config,cache,ai,extractor=extractCV}){
  app.register(async cvApp=>{
    cvApp.removeAllContentTypeParsers();cvApp.addContentTypeParser('*',{parseAs:'buffer',bodyLimit:config.cvMaxBytes},(request,body,done)=>done(null,body));
    cvApp.post('/v1/cv',async request=>{
      await limits(db,request.user.id);
      const bytes=request.body||Buffer.alloc(0),name=queryOf(request).get('name')||'';
      if(name.length>255)throw new HttpError(422,"Invalid 'name'");
      if(!bytes.length)throw new HttpError(400,'cv_empty');
      const sha=createHash('sha256').update(bytes).digest('hex');
      const previous=(await db.query(`SELECT sha256,${infoColumns} FROM public.user_cvs WHERE user_id=$1`,[request.user.id])).rows[0];
      if(previous?.sha256===sha&&previous.analysis==='full')return {...output(previous),profile:await readProfile(db,request.user.id)||{}};
      const cv=await extractor(bytes,config),analysis=await analyzeCV(db,cv.text,await loadCatalog(db,cache),ai,config);
      return transaction(db,async connection=>{
        await connection.query('SELECT pg_advisory_xact_lock(hashtextextended($1,0))',[`profile:${request.user.id}`]);
        const {rows}=await connection.query(`INSERT INTO public.user_cvs(user_id,file_name,file_type,file_size,pages,sha256,text,links,detected,analysis,model,tokens)
          VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12) ON CONFLICT(user_id) DO UPDATE SET
          file_name=EXCLUDED.file_name,file_type=EXCLUDED.file_type,file_size=EXCLUDED.file_size,pages=EXCLUDED.pages,sha256=EXCLUDED.sha256,
          text=EXCLUDED.text,links=EXCLUDED.links,detected=EXCLUDED.detected,analysis=EXCLUDED.analysis,model=EXCLUDED.model,tokens=EXCLUDED.tokens,
          storage_path=NULL,created_at=now(),analyzed_at=now() RETURNING ${infoColumns}`,
          [request.user.id,cleanFileName(name,cv.file_type),cv.file_type,bytes.length,cv.pages,sha,cv.text,cv.links,analysis.detected,analysis.analysis,analysis.model,analysis.tokens]);
        await connection.query('INSERT INTO public.user_cv_files(user_id,bytes,sha256) VALUES($1,$2,$3) ON CONFLICT(user_id) DO UPDATE SET bytes=EXCLUDED.bytes,sha256=EXCLUDED.sha256,created_at=now()',[request.user.id,bytes,sha]);
        const profile=await profileFromCV(connection,request.user.id,analysis.detected);
        return {...output(rows[0]),profile};
      });
    });
  });
  app.get('/v1/cv',async request=>{const row=(await db.query(`SELECT ${infoColumns} FROM public.user_cvs WHERE user_id=$1`,[request.user.id])).rows[0];if(!row)throw new HttpError(404,'no_cv');return output(row);});
  app.delete('/v1/cv',async(request,reply)=>{await transaction(db,async c=>{await c.query('SELECT pg_advisory_xact_lock(hashtextextended($1,0))',[`profile:${request.user.id}`]);await c.query('DELETE FROM public.user_cvs WHERE user_id=$1',[request.user.id]);});return reply.code(204).send();});
  app.post('/v1/cv/reanalyze',async request=>{
    await limits(db,request.user.id);
    const row=(await db.query('SELECT text,sha256 FROM public.user_cvs WHERE user_id=$1',[request.user.id])).rows[0];if(!row)throw new HttpError(404,'no_cv');
    const analysis=await analyzeCV(db,row.text,await loadCatalog(db,cache),ai,config);if(analysis.analysis!=='full')throw new HttpError(503,'ai_unavailable');
    return transaction(db,async c=>{
      await c.query('SELECT pg_advisory_xact_lock(hashtextextended($1,0))',[`profile:${request.user.id}`]);
      const {rows}=await c.query(`UPDATE public.user_cvs SET detected=$3,analysis=$4,model=$5,tokens=$6,analyzed_at=now() WHERE user_id=$1 AND sha256=$2 RETURNING ${infoColumns}`,[request.user.id,row.sha256,analysis.detected,analysis.analysis,analysis.model,analysis.tokens]);
      if(!rows.length)throw new HttpError(409,'cv_changed');
      return {...output(rows[0]),profile:await profileFromCV(c,request.user.id,analysis.detected)};
    });
  });
}
