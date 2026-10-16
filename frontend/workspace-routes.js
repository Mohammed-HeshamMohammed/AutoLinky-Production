export const workspaceScreens=['login','signup','dashboard','matches','jobs','saved','compare','applications','compose','profile','cv','automation','settings'];
export const accountPaths=workspaceScreens.flatMap(screen=>[`/${screen}/`,`/ar/${screen}/`]);
export function workspaceRoute(value){
  const url=value instanceof URL?value:new URL(value,'http://local.web');
  const parts=url.pathname.split('/').filter(Boolean),lang=parts[0]==='ar'?'ar':url.searchParams.get('lang')==='ar'?'ar':'en';
  if(parts[0]==='ar')parts.shift();
  if(parts[0]==='admin'&&parts.length<=2&&['','login','users','subscriptions','health','audit','collector','accounts','search-titles','sender'].includes(parts[1]||''))return {admin:true,screen:parts[1]||'overview',lang};
  if(parts.length!==1||!workspaceScreens.includes(parts[0]))return null;
  return {admin:false,screen:parts[0]==='matches'?'dashboard':parts[0]==='automation'?'auto-apply':parts[0],lang};
}
export function workspacePath(screen,lang='en'){return `${lang==='ar'?'/ar':''}/${screen==='auto-apply'?'automation':screen}/`;}
// Old browser-app bookmarks now open the independent responsive React client.
export function legacyWorkspaceRedirect(value){
  const url=value instanceof URL?value:new URL(value,'http://local.web');
  const match=url.pathname.match(/^\/app(?:\/(android|ios))?(?:\/(.*))?$/);
  if(!match)return null;
  const path=(match[2]||'').replace(/\/$/,'');
  const screens={'':'dashboard',matches:'dashboard',explore:'jobs',jobs:'jobs',profile:'profile',settings:'settings',applications:'applications',cv:'cv','auto-apply':'auto-apply',welcome:'login','welcome/email':'login','welcome/email/verify':'login'};
  if(!Object.hasOwn(screens,path))return null;
  return workspacePath(screens[path],url.searchParams.get('lang')==='ar'?'ar':'en')+url.search;
}
export function safeWorkspaceNext(value,lang='en'){
  if(typeof value!=='string'||!value.startsWith('/')||value.startsWith('//'))return workspacePath('dashboard',lang);
  const url=new URL(value,'http://local.web'),route=workspaceRoute(url);
  return url.origin==='http://local.web'&&route&&(route.admin||!['login','signup'].includes(route.screen))?url.pathname+url.search:workspacePath('dashboard',lang);
}
