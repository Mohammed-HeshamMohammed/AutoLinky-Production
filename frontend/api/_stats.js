import { createHmac } from 'node:crypto';

const BOT = /bot\b|crawl|spider|preview|facebookexternalhit|whatsapp|telegram|slackbot|discord|curl\/|wget|python-requests|headless|uptime|monitor|vercel|lighthouse|pingdom/i;
const IN_APP = [
  ['linkedin', /LinkedInApp/i], ['facebook', /FBAN|FBAV|FB_IAB|FBIOS/i],
  ['instagram', /Instagram/i], ['tiktok', /musical_ly|BytedanceWebview|TikTok/i],
  ['snapchat', /Snapchat/i], ['twitter', /Twitter|TwitterAndroid/i], ['line', /\bLine\//i],
];
export function describe(userAgent) {
  const ua=String(userAgent||'');
  const found=IN_APP.find(([,re])=>re.test(ua));
  return {device:/android/i.test(ua)?'android':/iPhone|iPad|iPod/i.test(ua)?'ios':ua?'desktop':'unknown',inApp:found?.[0]||'',isBot:BOT.test(ua)||!ua};
}
function configuration() {
  const {API_BASE_URL,STATS_KEY,STATS_SALT}=process.env;
  if (!API_BASE_URL || !STATS_KEY || !STATS_SALT) return null;
  try {
    const url=new URL(API_BASE_URL);
    if (!['https:','http:'].includes(url.protocol) || url.username || url.password || url.search || url.hash || url.pathname!=='/') return null;
    if (process.env.NODE_ENV==='production' && url.protocol!=='https:') return null;
    if(STATS_KEY.length<32 || STATS_SALT.length<32)return null;
    return {url:url.origin,key:STATS_KEY,salt:STATS_SALT};
  } catch { return null; }
}
export const enabled=()=>Boolean(configuration());
function host(value) { try{return new URL(value).hostname.slice(0,80);}catch{return null;} }

/// Recording is bounded and best-effort; a failure cannot interrupt a download.
export async function record(req,{kind,release,source}) {
  const config=configuration();
  if(!config)return false;
  const userAgent=String(req.headers['user-agent']||'').slice(0,300);
  const {device,inApp,isBot}=describe(userAgent);
  const ip=String(req.headers['x-forwarded-for']||req.socket?.remoteAddress||'').split(',')[0].trim();
  const visitor=createHmac('sha256',config.salt).update(`${new Date().toISOString().slice(0,10)}|${ip}|${userAgent}`).digest('hex').slice(0,16);
  const row={kind,version:release?.version||null,tag:release?.tag||null,device,in_app:inApp||null,is_bot:isBot,
    country:String(req.headers['x-vercel-ip-country']||'').slice(0,2)||null,referrer:host(req.headers.referer),
    source:source||null,visitor,user_agent:userAgent||null};
  try {
    const response=await fetch(`${config.url}/internal/v1/downloads`,{method:'POST',redirect:'error',
      headers:{'Content-Type':'application/json','X-Internal-Key':config.key},body:JSON.stringify(row),signal:AbortSignal.timeout(800)});
    return response.ok;
  } catch { return false; }
}
