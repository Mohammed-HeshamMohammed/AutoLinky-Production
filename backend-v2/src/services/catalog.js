import { SkillMatcher,RoleMatcher } from '../shared/skillmatch.js';
export function roleSearchTitle(name,keywords){
  if(!/[/&,()]/.test(name))return name;
  const acronyms=new Set((name.match(/[A-Za-z]+/g)||[]).filter(w=>w===w.toUpperCase()).map(w=>w.toLowerCase()));
  const keyword=keywords.find(w=>/^[a-z][a-z ]*[a-z]$/.test(w));
  return keyword?keyword.split(' ').map(w=>acronyms.has(w)?w.toUpperCase():w[0].toUpperCase()+w.slice(1)).join(' '):name;
}
export async function loadCatalog(db,cache){
  const data=await cache.load('catalog:analysis',3600000,async()=>{
    const [fields,roles,skills,learned]=await Promise.all([
      db.query('SELECT slug FROM public.job_fields WHERE active'),
      db.query('SELECT slug,field,name_en,keywords FROM public.job_roles WHERE active ORDER BY sort_order'),
      db.query('SELECT slug,name,aliases,learned FROM public.skills WHERE active'),
      db.query("SELECT name,slug FROM public.skill_candidates WHERE status IN ('alias','skill') AND slug IS NOT NULL"),
    ]);
    return {fields:fields.rows,roles:roles.rows,skills:skills.rows,learned:learned.rows};
  },{cacheIf:d=>d.roles.length>0});
  const learned=Object.fromEntries([...data.skills.filter(s=>s.learned).map(s=>[s.name,s.slug]),...data.learned.map(s=>[s.name,s.slug])]);
  return {...data,matcher:new SkillMatcher(data.skills.filter(s=>!s.learned).map(s=>[s.slug,s.aliases?.length?s.aliases:[s.name]]),learned),
    roleMatcher:new RoleMatcher(data.roles.map(r=>[r.slug,r.keywords||[]])),roleTitles:new Map(data.roles.map(r=>[r.slug,roleSearchTitle(r.name_en,r.keywords||[])]))};
}
