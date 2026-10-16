import { safeExternal } from './api.js';
// Same channels and target rules as the mobile application. Source data can
// supply only web URLs; WhatsApp URLs are constructed from a bounded number.
export function applicationChannels(job){
  const methods=job.apply_methods?.length?job.apply_methods:job.source==='linkedin_job'?['external']:[];
  const contact=(...types)=>job.contacts?.find(item=>types.includes(item.type))?.value;
  const channels=[];
  for(const method of methods){
    if(method==='email'||method==='phone'&&methods.includes('whatsapp'))continue;
    let target,label;
    if(['phone','whatsapp'].includes(method)){
      const digits=String(contact('whatsapp','phone')||'').replace(/\D/g,'');
      if(digits.length<8||digits.length>15)continue;
      target=`https://wa.me/${digits}?text=${encodeURIComponent(`Hello, I am interested in the ${job.title} opportunity.`)}`;label=['Apply on WhatsApp','التقديم عبر واتساب'];
    }else if(method==='link'){target=contact('link');label=['Open application link','فتح رابط التقديم'];}
    else if(method==='dm'){target=contact('dm')||job.author_url;label=['Message recruiter','مراسلة صاحب الفرصة'];}
    else if(method==='comment'){target=contact('comment')||job.url;label=['Open post to comment','فتح المنشور للتعليق'];}
    else if(method==='easy_apply'){target=job.url;label=['LinkedIn Easy Apply','التقديم السريع على LinkedIn'];}
    else if(method==='external'){target=job.url;label=['Open application page','فتح صفحة التقديم'];}
    const href=safeExternal(target);if(href&&label)channels.push({method,href,label});
  }
  return channels;
}
