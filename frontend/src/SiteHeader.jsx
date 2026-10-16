import { NAV, pagePath } from './pageContent';
import { LEGAL_NAV } from './legalContent';

export function accountHref(page,lang){return `${lang==='ar'?'/ar':''}/${page}/`;}

export default function SiteHeader({lang='en',slug=''}){
  const ar=lang==='ar',opposite=ar?'en':'ar';
  return <header className="nav site-header" id="top"><div className="container nav-inner">
    <a className="brand" href={pagePath('',lang)} aria-label="Autolinky"><img src="/assets/logo.svg" alt="" width="34" height="34" /><span>Autolinky</span></a>
    <nav className="nav-links" aria-label={ar?'التنقل الرئيسي':'Main navigation'}>{NAV.map(([key,en,arabic])=><a href={pagePath(key,lang)} className={key===slug?'active':undefined} aria-current={key===slug?'page':undefined} key={key}>{ar?arabic:en}</a>)}</nav>
    <div className="nav-actions">
      <a className="btn btn-ghost btn-sm nav-login" href={accountHref('login',lang)}>{ar?'تسجيل الدخول':'Log in'}</a>
      <a className="btn btn-primary btn-sm nav-signup" href={accountHref('signup',lang)}>{ar?'إنشاء حساب':'Create account'}</a>
      <a className="lang-toggle" href={pagePath(slug,opposite)} aria-label={ar?'English':'العربية'}><svg viewBox="0 0 24 24" aria-hidden="true"><circle cx="12" cy="12" r="9.25"/><path d="M2.75 12h18.5M12 2.75c2.6 2.6 3.9 5.7 3.9 9.25s-1.3 6.65-3.9 9.25c-2.6-2.6-3.9-5.7-3.9-9.25S9.4 5.35 12 2.75Z"/></svg><span>{ar?'English':'العربية'}</span></a>
    </div>
    <details className="mobile-menu"><summary aria-label={ar?'افتح القائمة':'Open menu'}><span/><span/><span/></summary><nav aria-label={ar?'القائمة':'Mobile menu'}>
      <a href={accountHref('login',lang)}>{ar?'تسجيل الدخول':'Log in'}</a>
      <a href={accountHref('signup',lang)}>{ar?'إنشاء حساب مجاني':'Create a free account'}</a>
      <a href={accountHref('dashboard',lang)}>{ar?'لوحة حسابك':'Your dashboard'}</a>
      <span className="menu-divider"/>
      {NAV.map(([key,en,arabic])=><a href={pagePath(key,lang)} key={key}>{ar?arabic:en}</a>)}
      <span className="menu-divider"/>
      {LEGAL_NAV.map(([key,en,arabic])=><a href={pagePath(key,lang)} key={key}>{ar?arabic:en}</a>)}
    </nav></details>
  </div></header>;
}
