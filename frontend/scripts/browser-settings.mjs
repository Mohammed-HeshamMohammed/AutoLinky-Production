import { readFile } from 'node:fs/promises';

const allowed=new Set(Object.keys(JSON.parse(await readFile(new URL('../../mobile apps/shared/env/example.json',import.meta.url),'utf8'))));

export function browserBuildSettings(supplied={},env=process.env){
  if(!supplied||Array.isArray(supplied)||typeof supplied!=='object'||Object.keys(supplied).some(key=>!allowed.has(key)))throw Error('APP_DEFINES may contain only named public app settings');
  // Browser Firebase/OAuth registrations come from runtime settings, never defines.
  const publicBuild=Object.fromEntries(Object.entries(supplied).filter(([key])=>!key.startsWith('FIREBASE_')&&!key.startsWith('GOOGLE_')));
  const settings={EMAIL_SIGN_IN:'false',APPLE_SIGN_IN:'false',API_BASE_URL:'',...publicBuild};
  if(env.VITE_SITE_URL){
    settings.SITE_URL ||= new URL(env.VITE_SITE_URL).origin;
    settings.TERMS_URL ||= new URL('/terms/',env.VITE_SITE_URL).href;
    settings.PRIVACY_URL ||= new URL('/privacy/',env.VITE_SITE_URL).href;
  }
  if(env.APP_API_BASE_URL)settings.API_BASE_URL=env.APP_API_BASE_URL;
  else if(env.VITE_SITE_URL)settings.API_BASE_URL=new URL(env.VITE_SITE_URL).origin;
  if(settings.API_BASE_URL){
    const api=new URL(settings.API_BASE_URL);
    if(api.username||api.password||api.search||api.hash||!(api.protocol==='https:'||(api.protocol==='http:'&&['localhost','127.0.0.1','[::1]'].includes(api.hostname))))throw Error('Use HTTPS for the app API, or HTTP localhost for development');
  }
  return settings;
}
