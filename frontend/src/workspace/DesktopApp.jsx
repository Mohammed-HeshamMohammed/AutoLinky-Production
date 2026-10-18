import React,{useCallback,useEffect,useState} from 'react';
import { workspacePath,workspaceRoute } from '../../workspace-routes.js';
import { SessionProvider,useSession } from './session.jsx';
import Login from './Login.jsx';
import AdminApp from './AdminApp.jsx';
import { Brand,Loading,ErrorState } from './ui.jsx';
import { Dashboard,Jobs,Applications,Compare,Compose } from './JobScreens.jsx';
import { Profile,CV,AutoApply,Settings } from './AccountScreens.jsx';
import './workspace.css';
import './workspace-design.css';
import {Sidebar,NavGroup,AppearanceButton} from './Navigation.jsx';
const destinations=[['dashboard','My matches','المطابقات'],['jobs','Explore jobs','استكشف الوظائف'],['saved','Saved jobs','الوظائف المحفوظة'],['applications','Applications','طلبات التوظيف'],['compare','Compare jobs','قارن الوظائف'],['profile','My profile','ملفي الشخصي'],['cv','My CV','سيرتي الذاتية'],['auto-apply','Auto Apply','التقديم التلقائي']];
export function WorkspaceShell({route,url,navigate,session,children}){
  const ar=route.lang==='ar',[mobileOpen,setMobileOpen]=useState(false),[search,setSearch]=useState(''),[dark,setDark]=useState(false);
  const closeMenu=useCallback(()=>setMobileOpen(false),[]);
  useEffect(()=>{try{setDark(localStorage.getItem('autolinky.web.dark')==='true');}catch{}},[]);
  useEffect(closeMenu,[route.screen,route.lang,closeMenu]);
  const labels=destinations.find(([name])=>name===route.screen)||[route.screen,route.screen==='settings'?'Settings':route.screen==='compose'?'Review application':'Workspace',route.screen==='settings'?'الإعدادات':route.screen==='compose'?'مراجعة الطلب':'مساحة العمل'];
  const name=session.user?.displayName||session.account?.email?.split('@')[0]||(ar?'حسابك':'Your account');
  function toggleTheme(){setDark(value=>{try{localStorage.setItem('autolinky.web.dark',String(!value));}catch{}return !value;});}
  const navItems=items=>items.map(([screen,en,arabic])=><a key={screen} href={workspacePath(screen,route.lang)} className={route.screen===screen||route.screen==='compose'&&screen==='applications'?'active':''} aria-current={route.screen===screen?'page':undefined} onClick={closeMenu}><span className="ws-nav-index" aria-hidden="true">{String(destinations.findIndex(([id])=>id===screen)+1).padStart(2,'0')}</span><span>{ar?arabic:en}</span></a>);
  return <div className={`ws-app ws-workspace ${dark?'is-dark':''}`} dir={ar?'rtl':'ltr'}>
    <a className="ws-skip" href="#workspace-main">{ar?'تخطى إلى المحتوى':'Skip to content'}</a>
    <Sidebar open={mobileOpen} onClose={closeMenu} ar={ar} label={ar?'مساحة عملك':'Personal workspace'} footer={<>
      <a href={workspacePath('settings',route.lang)} className={route.screen==='settings'?'active':''} aria-current={route.screen==='settings'?'page':undefined}>{ar?'الإعدادات':'Settings'}</a>
      <div className="ws-account"><span className="ws-avatar" aria-hidden="true">{name.slice(0,1).toUpperCase()}</span><div><b>{name}</b><small>{session.account?.email}</small></div></div>
      <button className="ws-signout" onClick={async()=>{await session.signOut();navigate(workspacePath('login',route.lang));}}>{ar?'تسجيل الخروج':'Sign out'}</button>
    </>}>
      <NavGroup label={ar?'بحثك عن وظيفة':'Job search'}>{navItems(destinations.slice(0,5))}</NavGroup>
      <NavGroup label={ar?'ملفك وتفضيلاتك':'Profile & preferences'}>{navItems(destinations.slice(5))}</NavGroup>
    </Sidebar>
    <div className="ws-main-wrap">
      <header className="ws-topbar">
        <div className="ws-topbar-left"><button className="ws-menu ws-text-button" aria-expanded={mobileOpen} aria-controls="workspace-navigation" onClick={()=>setMobileOpen(true)}>{ar?'القائمة':'Menu'}</button><span className="ws-breadcrumb">{ar?'مساحة العمل':'Workspace'}<span>/</span></span><b>{ar?labels[2]:labels[1]}</b></div>
        <form className="ws-global-search" role="search" onSubmit={event=>{event.preventDefault();navigate(workspacePath('jobs',route.lang)+'?q='+encodeURIComponent(search.trim()));}}><input type="search" aria-label={ar?'ابحث عن وظيفة':'Search jobs'} placeholder={ar?'ابحث عن وظيفة…':'Search jobs…'} value={search} onChange={event=>setSearch(event.target.value)}/><button type="submit">{ar?'بحث':'Search'}</button></form>
        <div className="ws-topbar-actions"><button className="ws-text-button" onClick={()=>navigate(workspacePath(route.screen,ar?'en':'ar')+url.search)}>{ar?'EN':'عربي'}</button><AppearanceButton dark={dark} onClick={toggleTheme} ar={ar}/></div>
      </header>
      <div className="ws-content-sheet"><main id="workspace-main" className="ws-main" tabIndex={-1}>{children}</main>
      <footer className="ws-workspace-footer"><span>AutoLinky · {ar?'مساحة لخطوتك القادمة.':'Room for your next move.'}</span><a href={ar?'/ar/':'/'}>{ar?'زيارة الموقع':'Visit website'}</a></footer></div>
    </div>
  </div>;
}
function UserApp(props){
  const session=useSession(),{route,url,navigate}=props,ar=route.lang==='ar';
  useEffect(()=>{if(session.status==='signed-out'&&!['login','signup'].includes(route.screen))navigate(workspacePath('login',route.lang)+'?next='+encodeURIComponent(url.pathname+url.search),true);},[session.status,route.screen]);
  if(['login','signup'].includes(route.screen))return <Login {...props}/>;
  if(session.status==='loading'||session.status==='signed-out')return <div className="ws-app ws-opening"><Brand/><Loading label={ar?'نجهز مساحة العمل…':'Opening your workspace…'}/></div>;
  if(session.status==='error')return <div className="ws-app ws-opening"><Brand/><ErrorState error={session.error} ar={ar} onRetry={session.retry}/><a href={workspacePath('login',route.lang)}>{ar?'العودة للدخول':'Back to sign in'}</a></div>;
  const context={...props,session,client:session.client,ar,t:(en,arabic)=>ar?arabic:en};
  const Screen={dashboard:Dashboard,jobs:Jobs,saved:Jobs,compare:Compare,applications:Applications,compose:Compose,profile:Profile,cv:CV,'auto-apply':AutoApply,settings:Settings}[route.screen]||Dashboard;
  return <WorkspaceShell {...props} session={session}><Screen key={session.account.user_id+':'+route.screen} {...context}/></WorkspaceShell>;
}
function AdminGate(props){
  const session=useSession(),{route,url,navigate}=props,ar=route.lang==='ar';
  useEffect(()=>{if(session.status==='signed-out')navigate(workspacePath('login',route.lang)+'?next='+encodeURIComponent(url.pathname+url.search),true);},[session.status]);
  if(session.status==='loading'||session.status==='signed-out')return <div className="ws-app ws-opening"><Brand/><Loading label={ar?'جارٍ التحقق من وصول الإدارة…':'Checking administrator access…'}/></div>;
  if(session.status==='error')return <div className="ws-app ws-opening"><Brand/><ErrorState error={session.error} ar={ar} onRetry={session.retry}/><button className="ws-button secondary" onClick={session.signOut}>{ar?'تبديل الحساب':'Switch account'}</button></div>;
  if(!session.account.admin_role)return <div className="ws-app ws-opening"><Brand/><h1>{ar?'الوصول مخصص للإدارة':'Administrator access required'}</h1><p>{ar?'لم يتم تعيين هذا الحساب كمسؤول.':'This account has not been assigned an administrator role.'}</p><button className="ws-button secondary" onClick={session.signOut}>{ar?'تبديل الحساب':'Switch account'}</button><a href={workspacePath('dashboard',route.lang)}>{ar?'مساحة العمل':'Your workspace'}</a></div>;
  return <AdminApp key={session.account.user_id} {...props} appSession={session}/>;
}
export default function DesktopApp({initialURL='/login/'}){
  const [url,setURL]=useState(()=>new URL(initialURL,'http://local.web'));
  const route=workspaceRoute(url)||{screen:'login',lang:'en',admin:false};
  function navigate(path,replace=false){const next=new URL(path,location.origin),destination=workspaceRoute(next);if(next.origin!==location.origin||!destination)return;if(destination.admin!==route.admin){location[replace?'replace':'assign'](next.href);return;}history[replace?'replaceState':'pushState']({},'',next.pathname+next.search);setURL(next);window.scrollTo({top:0,behavior:'instant'});}
  useEffect(()=>{const pop=()=>setURL(new URL(location.href));const click=event=>{if(event.defaultPrevented||event.button!==0||event.ctrlKey||event.metaKey||event.shiftKey||event.altKey)return;const link=event.target.closest?.('a[href]');if(!link||link.target||link.hasAttribute('download'))return;const next=new URL(link.href,location.origin);if(next.origin===location.origin&&workspaceRoute(next)?.admin===route.admin){event.preventDefault();navigate(next.pathname+next.search);}};window.addEventListener('popstate',pop);document.addEventListener('click',click);return()=>{window.removeEventListener('popstate',pop);document.removeEventListener('click',click);};},[]);
  useEffect(()=>{document.documentElement.lang=route.lang;document.documentElement.dir=route.lang==='ar'?'rtl':'ltr';document.title=`${route.admin?'Admin':route.screen.replaceAll('-',' ')} · AutoLinky`;document.body.classList.add('desktop-app');document.querySelector('meta[name="robots"]')?.setAttribute('content','noindex, nofollow');return()=>document.body.classList.remove('desktop-app');},[route.lang,route.screen]);
  const props={route,url,navigate};
  return <SessionProvider>{route.admin?<AdminGate {...props}/>:<UserApp {...props}/>}</SessionProvider>;
}
