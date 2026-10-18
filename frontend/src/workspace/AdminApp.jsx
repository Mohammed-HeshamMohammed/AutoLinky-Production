import React,{useCallback,useEffect,useMemo,useRef,useState} from 'react';
import {LoginFrame} from './Login.jsx';
import {createClient,friendlyError} from './api.js';
import {Field,Notice,useResource} from './ui.jsx';
import {AdminNumbers} from './AdminNumbers.jsx';
import AdminUsers from './AdminUsers.jsx';
import {AdminCollector,AdminAccounts,AdminTitles,AdminSender} from './AdminOperations.jsx';
import {AdminSubscriptions,AdminHealth,AdminAudit} from './AdminSupport.jsx';
import './admin-console.css';
import {Sidebar,NavGroup,AppearanceButton} from './Navigation.jsx';
const sections=[['overview','Overview','نظرة عامة'],['users','Users','المستخدمون'],['subscriptions','Subscriptions','الاشتراكات'],['collector','Collector','المجمّع'],['accounts','Accounts','حسابات المصادر'],['search-titles','Search titles','مسميات البحث'],['sender','Sender','المرسل'],['health','Health','الحالة'],['audit','Audit','التدقيق']];
export default function AdminApp({route,url,navigate,appSession}){
  const ar=route.lang==='ar',t=(en,arabic)=>ar?arabic:en,base=ar?'/ar/admin/':'/admin/';
  const [session,setSession]=useState(null),[enrollment,setEnrollment]=useState(null),[code,setCode]=useState(''),[challenge,setChallenge]=useState(''),[busy,setBusy]=useState(false),[error,setError]=useState(null),[action,setAction]=useState(null),[dark,setDark]=useState(()=>{try{return localStorage.getItem('autolinky.admin.dark')==='true';}catch{return false;}});
  const resolver=useRef(null),[refreshVersion,setRefreshVersion]=useState(0),[mobileOpen,setMobileOpen]=useState(false);
  const closeMenu=useCallback(()=>setMobileOpen(false),[]);
  useEffect(closeMenu,[route.screen,route.lang,closeMenu]);
  const client=useMemo(()=>{const request=createClient({getToken:()=>appSession.user.getIdToken(),getAdminSession:()=>session?.token});return async(...args)=>{try{return await request(...args);}catch(error){if((error.status===401&&!args[0].endsWith('/reauth'))||error.message==='admin_required'){setSession(null);setEnrollment(null);setChallenge('');}throw error;}};},[session?.token,appSession.user]);
  function finish(value){if(value)setRefreshVersion(version=>version+1);resolver.current?.(value);resolver.current=null;setAction(null);}
  function confirm(next){if(resolver.current)return Promise.resolve(false);return new Promise(resolve=>{resolver.current=resolve;setAction(next);});}
  useEffect(()=>{if(!session)finish(false);},[session?.token]);
  useEffect(()=>()=>{resolver.current?.(false);},[]);
  async function login(event){event.preventDefault();setBusy(true);setError(null);try{
    if(!challenge){const result=await client('/admin/api/login',{method:'POST',body:{}});setChallenge(result.challenge);setEnrollment(result.enrollment||null);}
    else{const result=await client('/admin/api/verify',{method:'POST',body:{challenge,code}});setCode('');setChallenge('');setEnrollment(null);setSession(result);if(route.screen==='login')navigate(base,true);}
  }catch(error){setError(error);}finally{setBusy(false);}}
  async function logout(){try{await client('/admin/api/logout',{method:'POST',body:{}});}finally{finish(false);setSession(null);setCode('');setChallenge('');setEnrollment(null);navigate(base,true);}}
  if(!session)return <div className="ws-app"><LoginFrame admin ar={ar}><h2>{enrollment?t('Set up your authenticator','إعداد تطبيق المصادقة'):challenge?t('Verify your authenticator','التحقق من المصادقة'):t('Verify administrator access','التحقق من وصول الإدارة')}</h2><p>{enrollment?t('Add AutoLinky to your authenticator using the setup key, then enter its six-digit code.','أضف AutoLinky في تطبيق المصادقة باستخدام مفتاح الإعداد ثم أدخل الرمز المكون من ستة أرقام.'):challenge?t('Enter the current six-digit code from your authenticator app.','أدخل رمز المصادقة الحالي المكون من ستة أرقام.'):t('Your account has an administrator role. Confirm your authenticator to open the dashboard.','حسابك معين كمسؤول. أكد تطبيق المصادقة لفتح لوحة الإدارة.')}</p><p><b>{appSession.account.email}</b></p>{error&&<Notice tone="error">{friendlyError(error,ar)}</Notice>}<form onSubmit={login}>{enrollment&&<><Field label={t('Authenticator setup key','مفتاح إعداد المصادقة')} hint={t('Choose a time-based account, SHA1, six digits and 30 seconds. This key is shown only until setup is verified.','اختر حسابًا زمنيًا وخوارزمية SHA1 وستة أرقام و٣٠ ثانية. يظهر المفتاح حتى يتم تأكيد الإعداد فقط.')}><input aria-label={t('Authenticator setup key','مفتاح إعداد المصادقة')} readOnly autoComplete="off" spellCheck={false} value={enrollment.secret} onFocus={event=>event.target.select()}/></Field><a className="ws-text-button" href={enrollment.authenticator_uri}>{t('Open authenticator app','فتح تطبيق المصادقة')}</a></>}{challenge&&<Field label={t('Authenticator code','رمز المصادقة')}><input autoComplete="one-time-code" inputMode="numeric" pattern="[0-9]{6}" minLength={6} maxLength={6} required autoFocus value={code} onChange={e=>setCode(e.target.value.replace(/\D/g,''))}/></Field>}<button className="ws-button primary full" disabled={busy}>{busy?t('Verifying…','جارٍ التحقق…'):challenge?t('Verify and continue','تحقق وتابع'):t('Continue','متابعة')}</button>{challenge&&<button className="ws-text-button" type="button" disabled={busy} onClick={()=>{setChallenge('');setEnrollment(null);setCode('');setError(null);}}>{t('Start again','البدء مجددًا')}</button>}</form><small className="ws-form-note">{t('AutoLinky account + assigned admin role + authenticator','حساب AutoLinky ودور مسؤول ومصادقة')}</small><button className="ws-login-switch ws-text-button" onClick={appSession.signOut}>{t('Switch account','تبديل الحساب')}</button></LoginFrame></div>;
  const props={client,admin:session.admin,t,ar,url,navigate,confirm};
  const Screen={overview:AdminNumbers,users:AdminUsers,collector:AdminCollector,accounts:AdminAccounts,'search-titles':AdminTitles,sender:AdminSender,subscriptions:AdminSubscriptions,health:AdminHealth,audit:AdminAudit}[route.screen]||AdminNumbers;
  function theme(){setDark(value=>{try{localStorage.setItem('autolinky.admin.dark',String(!value));}catch{}return !value;});}
  const current=sections.find(([id])=>id===route.screen)||sections[0];
  const links=ids=>sections.filter(([id])=>ids.includes(id)).map(([id,en,arabic])=><a key={id} className={route.screen===id?'active':''} aria-current={route.screen===id?'page':undefined} href={base+(id==='overview'?'':id+'/')} onClick={closeMenu}><span className="ws-nav-index" aria-hidden="true">{String(sections.findIndex(([name])=>name===id)+1).padStart(2,'0')}</span><span>{ar?arabic:en}</span></a>);
  return <div className={`ws-app ws-admin ${dark?'is-dark':''}`} dir={ar?'rtl':'ltr'}>
    <a className="ws-skip" href="#workspace-main">{t('Skip to content','تخطى إلى المحتوى')}</a>
    <Sidebar open={mobileOpen} onClose={closeMenu} ar={ar} label={t('Administration','الإدارة')} footer={<>
      <div className="ac-sidebar-status"><span className="ws-space-label">{t('Sending status','حالة الإرسال')}</span><SenderPulse {...props} refreshVersion={refreshVersion}/></div>
      <a href={ar?'/ar/dashboard/':'/dashboard/'}>{t('Your workspace','مساحة عملك')}</a>
      <div className="ws-account"><span className="ws-avatar" aria-hidden="true">{session.admin.username.slice(0,1).toUpperCase()}</span><div><b>{session.admin.username}</b><small>{session.admin.role}</small></div></div>
      <button className="ws-signout" onClick={logout}>{t('Sign out','تسجيل الخروج')}</button>
    </>}>
      <NavGroup label={t('Platform','المنصة')}>{links(['overview','users','subscriptions'])}</NavGroup>
      <NavGroup label={t('Operations','العمليات')}>{links(['collector','accounts','search-titles','sender'])}</NavGroup>
      <NavGroup label={t('System','النظام')}>{links(['health','audit'])}</NavGroup>
    </Sidebar>
    <div className="ws-main-wrap">
      <header className="ws-topbar"><div className="ws-topbar-left"><button className="ws-menu ws-text-button" aria-expanded={mobileOpen} aria-controls="workspace-navigation" onClick={()=>setMobileOpen(true)}>{t('Menu','القائمة')}</button><span className="ws-breadcrumb">{t('Administration','الإدارة')}<span>/</span></span><b>{ar?current[2]:current[1]}</b></div>
        <form className="ws-global-search ac-global-search" role="search" onSubmit={event=>{event.preventDefault();const value=new FormData(event.currentTarget).get('q');navigate(base+'users/?q='+encodeURIComponent(value));}}><input type="search" name="q" maxLength={100} aria-label={t('Find a user by email','ابحث بالبريد الإلكتروني')} placeholder={t('Find a user…','ابحث عن مستخدم…')}/><button type="submit">{t('Search','بحث')}</button></form>
        <div className="ws-topbar-actions"><a className="ws-text-button" href={(ar?'/admin/':'/ar/admin/')+(route.screen==='overview'?'':route.screen+'/')+url.search}>{ar?'EN':'عربي'}</a><AppearanceButton dark={dark} onClick={theme} ar={ar}/></div>
      </header>
      <div className="ws-content-sheet"><main className="ac-view" id="workspace-main" tabIndex={-1}><Screen key={route.screen} {...props}/></main>
      <footer className="ac-footer"><span>{t('AutoLinky administration','إدارة AutoLinky')}</span><span>{t('Cairo time · changes are audited','توقيت القاهرة · التغييرات مسجلة')}</span></footer></div>
    </div>
    {action&&<Confirmation key={action.title} {...{action,client,t,ar}} finish={finish}/>}
  </div>;
}
function SenderPulse({client,t,ar,refreshVersion}){
  const resource=useResource(signal=>client('/admin/api/sender',{signal}),'sender-pulse:'+refreshVersion);
  const data=resource.data,alive=data?.runtime.connected&&data.runtime.enabled&&!data.control.paused&&data.heartbeat&&Date.now()-Date.parse(data.heartbeat)<600000;
  return <a className={'ac-pulse '+(alive?'alive':'')} href={ar?'/ar/admin/sender/':'/admin/sender/'}><i/>{resource.loading?t('Checking sender…','جارٍ فحص المرسل…'):resource.error?t('Sender unavailable','المرسل غير متاح'):alive?t('Sender running','المرسل يعمل'):data.control.paused?t('Sender paused','المرسل متوقف مؤقتًا'):data.runtime.connected&&!data.runtime.enabled?t('Sender disabled','المرسل معطل'):t('Sender offline','المرسل غير متصل')}</a>;
}
function Confirmation({action,client,t,ar,finish}){
  const dialog=useRef(null),[reason,setReason]=useState(''),[code,setCode]=useState(''),[busy,setBusy]=useState(false),[error,setError]=useState(null);
  useEffect(()=>{dialog.current.showModal();return()=>dialog.current?.close();},[]);
  async function save(event){event.preventDefault();setBusy(true);setError(null);try{const elevation=await client('/admin/api/reauth',{method:'POST',body:{code}});setCode('');const result=await action.run({reason,headers:{'X-Admin-Elevation':elevation.token}});finish(result);}catch(error){setError(error);}finally{setCode('');setBusy(false);}}
  return <dialog className="ac-confirm" ref={dialog} aria-labelledby="ac-confirm-title" onCancel={e=>{e.preventDefault();if(!busy)finish(false);}}><form onSubmit={save}><span className="ws-eyebrow">{t('VERIFIED CHANGE','تغيير موثق')}</span><h2 id="ac-confirm-title">{action.title}</h2><p>{t('Add the reason, then confirm with a new authenticator code. Wait for the next code if you just signed in.','اكتب السبب ثم أكد برمز مصادقة جديد. انتظر الرمز التالي إذا سجلت الدخول للتو.')}</p><Field label={t('Reason for this change','سبب التغيير')}><textarea required autoFocus minLength={5} maxLength={500} rows={3} value={reason} onChange={e=>setReason(e.target.value)}/></Field><Field label={t('Authenticator code','رمز المصادقة')}><input autoComplete="one-time-code" required inputMode="numeric" pattern="[0-9]{6}" maxLength={6} value={code} onChange={e=>setCode(e.target.value.replace(/\D/g,''))}/></Field>{error&&<Notice tone="error">{friendlyError(error,ar)}</Notice>}<div className="ws-form-actions"><button type="button" className="ws-button secondary" disabled={busy} onClick={()=>finish(false)}>{t('Cancel','إلغاء')}</button><button className="ws-button primary" disabled={busy||error?.uncertain}>{busy?t('Saving…','جارٍ الحفظ…'):t('Confirm change','تأكيد التغيير')}</button></div></form></dialog>;
}
