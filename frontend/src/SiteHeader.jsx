import { NAV, pagePath } from './pageContent';
import { LEGAL_NAV } from './legalContent';
import { BrandWordmark } from './BrandMark';

export function accountHref(page,lang){return `${lang==='ar'?'/ar':''}/${page}/`;}

export default function SiteHeader({lang='en',slug=''}){
  const ar=lang==='ar',opposite=ar?'en':'ar';
  const items=slug?NAV:[['how','How it works','طريقة العمل'],['pricing','Plans','الخطط'],['faq','Questions','الأسئلة']];
  return <header className="nav site-header" id="top"><div className="container nav-inner">
    <a className="brand" href={pagePath('',lang)} aria-label="AutoLinky"><BrandWordmark/></a>
    <nav className="nav-links" aria-label={ar?'التنقل الرئيسي':'Main navigation'}>{items.map(([key,en,arabic])=><a href={slug?pagePath(key,lang):'#'+key} className={key===slug?'active':undefined} aria-current={key===slug?'page':undefined} key={key}>{ar?arabic:en}</a>)}</nav>
    <div className="nav-actions">
      <a className="btn btn-ghost btn-sm nav-login" href={accountHref('login',lang)}>{ar?'تسجيل الدخول':'Log in'}</a>
      <a className="btn btn-primary btn-sm nav-signup" href={accountHref('signup',lang)}>{ar?'إنشاء حساب':'Create account'}</a>
      <a className="lang-toggle" href={pagePath(slug,opposite)} aria-label={ar?'English':'العربية'}><span>{ar?'English':'العربية'}</span></a>
    </div>
    <details className="mobile-menu" onKeyDown={event=>{if(event.key==='Escape'){event.currentTarget.open=false;event.currentTarget.querySelector('summary').focus();}}}><summary aria-label={ar?'افتح القائمة':'Open menu'}>{ar?'القائمة':'Menu'}</summary><nav aria-label={ar?'القائمة':'Mobile menu'}>
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
