import he from 'he';
const clean=fragment=>he.decode(fragment.replace(/<[^>]+>/g,' ')).trim().replace(/\s+/gu,' ');
export function parseSearch(page){
  const result=[],seen=new Set();
  for(const chunk of page.split(/<li[\s>]/).slice(1)){
    const id=/urn:li:jobPosting:(\d+)/.exec(chunk)?.[1],title=/base-search-card__title[^>]*>(.*?)<\/h3>/s.exec(chunk)?.[1];
    if(!id||title===undefined||seen.has(id))continue;seen.add(id);
    const match=pattern=>pattern.exec(chunk)?.[1];
    result.push({job_id:id,title:clean(title),company:clean(match(/base-search-card__subtitle[^>]*>(.*?)<\/h4>/s)||''),
      company_url:he.decode(match(/base-search-card__subtitle.*?href="([^"]+)"/s)||'').split('?')[0],
      location:clean(match(/job-search-card__location[^>]*>(.*?)<\/span>/s)||''),listed_at:match(/<time[^>]*datetime="(\d{4}-\d{2}-\d{2})"/)||null,
      job_url:`https://www.linkedin.com/jobs/view/${id}/`,details:{}});
  }return result;
}
export function parseDetails(page){
  const criteria=new Map([...page.matchAll(/description__job-criteria-subheader[^>]*>(.*?)<\/h3>\s*<span[^>]*description__job-criteria-text[^>]*>(.*?)<\/span>/gs)].map(m=>[clean(m[1]).toLowerCase(),clean(m[2])]));
  const description=/show-more-less-html__markup[^>]*>(.*?)<\/div>/s.exec(page)?.[1],applicants=/num-applicants__caption[^>]*>(.*?)</s.exec(page)?.[1];
  const text=description===undefined?null:he.decode(description.replace(/<\s*(br|\/p|\/li|\/ul|\/h\d)\s*\/?>/gi,'\n').replace(/<[^>]+>/g,' ')).split('\n').filter(line=>line.trim()).map(line=>line.trim().replace(/\s+/gu,' ')).join('\n')||null;
  return {seniority:criteria.get('seniority level')||null,employment_type:criteria.get('employment type')||null,job_function:criteria.get('job function')||null,industries:criteria.get('industries')||null,applicants:applicants===undefined?null:clean(applicants),apply_type:page.includes('apply-link-onsite')?'easy_apply':page.includes('apply-link-offsite')?'external':null,description:text};
}
export const looksRemote=(...texts)=>texts.some(text=>/\bremote\b|work from home|\bwfh\b/i.test(text||''));
