import { readFile } from 'node:fs/promises';
import { HttpError } from '../../lib/http/errors.js';
import { countryCode } from '../../lib/domain/countries.js';
import { unique,uniqueText } from '../../lib/domain/text.js';
import { durableLimit } from '../../lib/http/rate-limit.js';
import { AIUnavailable } from '../../lib/ai/client.js';
const levels=['intern','junior','mid','senior','manager'],languages=['en','ar','de','fr','nl','es','pt'];
const languageNames={english:'en',arabic:'ar',german:'de',french:'fr',dutch:'nl',spanish:'es',portuguese:'pt','عربي':'ar','العربية':'ar','انجليزي':'en'};
const dialing={'20':'EG','966':'SA','971':'AE','974':'QA','965':'KW','973':'BH','968':'OM','962':'JO','961':'LB','964':'IQ','963':'SY','970':'PS','967':'YE','212':'MA','213':'DZ','216':'TN','218':'LY','249':'SD','44':'GB','49':'DE','33':'FR','31':'NL','34':'ES','39':'IT','90':'TR','91':'IN','92':'PK'};
const phone=/(?<![\p{L}\p{N}_+])\+?\(?\d[\d\s().\-/]{6,}\d(?![\p{L}\p{N}_])/gu;
export { redactContacts } from '../../lib/domain/redaction.js';
import { redactContacts } from '../../lib/domain/redaction.js';
export function phoneCountry(text){for(const [s] of text.slice(0,3000).matchAll(phone)){const written=s.replace(/^\(/,''),digits=written.replace(/\D/g,'');if(digits.length<9||digits.length>15)continue;if(written.startsWith('+')||written.startsWith('00')){const n=written.startsWith('00')?digits.slice(2):digits;for(const [code,country] of Object.entries(dialing))if(n.startsWith(code))return country;}else if(/^01[0125]\d{8}$/.test(digits))return 'EG';}return null;}
export function textLanguage(text){const sample=text.slice(0,5000),letters=(sample.match(/\p{L}/gu)||[]).length;return letters&&(sample.match(/[ء-ي]/gu)||[]).length/letters>0.3?'ar':'en';}
const short=(value,max)=>typeof value==='string'?value.replace(/[\x00-\x1f\x7f<>]/g,' ').trim().replace(/\s+/g,' ').replace(/^[ ,;]+|[ ,;]+$/g,'').slice(0,max)||null:null;
const strings=(value,max,len)=>uniqueText((Array.isArray(value)?value:typeof value==='string'?[value]:[]).slice(0,100).map(v=>short(v,len)).filter(Boolean)).slice(0,max);
export function titleKey(title){
  if(typeof title!=='string')return null;
  let key=title.normalize('NFKC').toLowerCase();
  if(/@|https?:|www\./.test(key))return null;
  key=key.replace(/\([^)]*\)|\[[^\]]*\]/g,' ').replace(/\s+[-–—]\s+.*$|\s*[|:•·].*$/g,'').trim().replace(/\s+/gu,' ')
    .replace(/^(?:(?:senior|sr|junior|jr|mid-level|mid level|entry-level|entry level)\.?(?:\s+|$))+/,'')
    .replace(/^[\s,;/\\_*'"-]+|[\s.,;/\\_*'"-]+$/g,'');
  return key.length>=2&&key.length<=60&&key.split(' ').length<=6&&/[a-zà-ɏ؀-ۿ]/.test(key)?key:null;
}
function searchTitles(titles,roles,headline,catalog){const found=[],keys=new Set();const add=t=>{const key=titleKey(t);if(key&&!keys.has(key)&&found.length<5){keys.add(key);found.push(t.trim());}};for(const title of titles)add(title);for(const title of [...roles.map(r=>catalog.roleTitles.get(r)),headline]){if(found.length>=3)break;add(title);}return found;}
export function rulesOnly(text,catalog){let roles=[];for(const line of text.split(/\r?\n/).slice(0,6)){const role=catalog.roleMatcher.match(line);if(role){roles=[role];break;}}return {headline:null,roles,skills:catalog.matcher.extract(text,60),extra_skills:[],level:null,years_experience:null,languages:[textLanguage(text)],country:phoneCountry(text),city:null,search_titles:searchTitles([],roles,null,catalog)};}
export function buildDetected(raw,text,catalog){
  if(raw.is_cv===false)throw new HttpError(422,'not_a_cv');
  const roleSet=new Set(catalog.roles.map(r=>r.slug)),skillSet=new Set(catalog.skills.map(s=>s.slug));
  const roles=unique((Array.isArray(raw.roles)?raw.roles:[]).filter(v=>typeof v==='string').map(v=>v.trim().toLowerCase())).filter(r=>roleSet.has(r)).slice(0,3);
  const skills=[],extra=[];for(const name of strings(raw.skills,60,60)){const slug=catalog.matcher.lookup(name),found=slug?[slug]:catalog.matcher.extract(name);if(found.length)skills.push(...found);else if(extra.length<30)extra.push(name);}
  const langs=unique((Array.isArray(raw.languages)?raw.languages:[]).filter(v=>typeof v==='string').map(v=>languages.includes(v.trim().toLowerCase())?v.trim().toLowerCase():languageNames[v.trim().toLowerCase()]).filter(Boolean));
  if(!langs.includes(textLanguage(text)))langs.push(textLanguage(text));
  for(const lang of langs){const skill={en:'english',ar:'arabic',fr:'french',de:'german',es:'spanish'}[lang];if(skillSet.has(skill))skills.push(skill);}
  skills.push(...catalog.matcher.extract(text,60));
  const n=typeof raw.years_experience==='boolean'||raw.years_experience==null||raw.years_experience===''?NaN:Number(raw.years_experience);
  // Python round uses ties to even.
  const rounded=Math.abs(n%1)===0.5?2*Math.round(n/2):Math.round(n),years=rounded>=0&&rounded<=60?rounded:null;
  let level=levels.includes(raw.level)?raw.level:years===null?null:years<=2?'junior':years<=5?'mid':'senior';
  if(years!==null&&level!=='intern'){if(level==='manager'&&years<7)level='senior';if(level==='senior'&&years<5)level='mid';if(level==='mid'&&years<2)level='junior';}
  const headline=short(raw.headline,80);
  return {headline,roles,skills:unique(skills).filter(s=>skillSet.has(s)).slice(0,60),extra_skills:extra,level,years_experience:years,languages:langs,country:countryCode(raw.country)||phoneCountry(text),city:short(raw.city,60),search_titles:searchTitles(strings(raw.search_titles,20,60),roles,headline,catalog)};
}
const prompt=await readFile(new URL('./prompts/cv-system.txt',import.meta.url),'utf8');
export async function analyzeCV(db,text,catalog,client,config){
  try{
    await durableLimit(db,'cv_ai:all',500,86400);
    const {data,tokens}=await client.ask({model:config.cvModel,messages:[
      {role:'system',content:prompt.replace('{{today}}',new Date().toISOString().slice(0,10)).replace('{{roles}}',catalog.roles.map(r=>`${r.slug}: ${r.name_en}`).join('\n'))},
      {role:'user',content:`CV text:\n<<<\n${redactContacts(text).slice(0,15000)}\n>>>`},
    ]});
    return {detected:buildDetected(data,text,catalog),analysis:'full',model:config.cvModel,tokens};
  }catch(error){if(error instanceof HttpError&&error.status===422)throw error;if(!(error instanceof AIUnavailable)&&!(error instanceof HttpError))throw error;return {detected:rulesOnly(text,catalog),analysis:'partial',model:null,tokens:0};}
}
