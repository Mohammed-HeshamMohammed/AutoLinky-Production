import { useLayoutEffect } from 'react';
import { MESSAGES, WHATSAPP } from './content';
import { NAV, PAGES, pagePath } from './pageContent';
import { LEGAL_NAV } from './legalContent';
import { ProductPreview } from './ProductExperience';
import { useSiteMotion } from './useSiteMotion';
import WhatsAppIcon from './WhatsAppIcon';
import { downloadLinkProps } from './config';

function Icon({ name }) {
  const paths = {
    arrow: <><path d="M5 12h14m-5-5 5 5-5 5" /></>,
    download: <><path d="M12 4v12m0 0-5-5m5 5 5-5M5 20h14" /></>,
    globe: <><circle cx="12" cy="12" r="9" /><path d="M3 12h18M12 3c2.5 2.7 3.75 5.7 3.75 9S14.5 18.3 12 21c-2.5-2.7-3.75-5.7-3.75-9S9.5 5.7 12 3Z" /></>,
    check: <><path d="m5 12.5 4.5 4.5L19 7.5" /></>,
  };
  return <svg viewBox="0 0 24 24" aria-hidden="true" focusable="false">{paths[name]}</svg>;
}

export default function ContentPage({ slug, lang }) {
  const page = PAGES[slug][lang];
  const isArabic = lang === 'ar';
  const isLegal = Boolean(page.legal);
  const hasPreview = slug === 'auto-apply' || slug === 'features';
  useSiteMotion(slug);
  const home = pagePath('', lang);
  const opposite = isArabic ? 'en' : 'ar';
  const contact = `https://wa.me/${WHATSAPP}?text=${encodeURIComponent(MESSAGES.contact[lang])}`;
  const navLabel = isArabic ? 'التنقل الرئيسي' : 'Main navigation';

  useLayoutEffect(() => {
    document.documentElement.lang = lang;
    document.documentElement.dir = isArabic ? 'rtl' : 'ltr';
    document.title = page.title;
    document.querySelector('meta[name="description"]')?.setAttribute('content', page.description);
    try { localStorage.setItem('autolinky.lang', lang); } catch { /* Storage may be disabled. */ }
  }, [lang, isArabic, page.title, page.description]);

  return <div className="site-page">
    <a className="skip" href="#main">{isArabic ? 'تخطَّ إلى المحتوى' : 'Skip to content'}</a>
    <header className="nav">
      <div className="container nav-inner">
        <a className="brand" href={home} aria-label="Autolinky"><img src="/assets/logo.svg" alt="" width="34" height="34" /><span>Autolinky</span></a>
        <nav className="nav-links" aria-label={navLabel}>{NAV.map(([key, en, ar]) => <a className={key === slug ? 'active' : ''} aria-current={key === slug ? 'page' : undefined} href={pagePath(key, lang)} key={key}>{isArabic ? ar : en}</a>)}</nav>
        <div className="nav-actions">
          <a className="lang-toggle" href={pagePath(slug, opposite)} aria-label={isArabic ? 'English' : 'العربية'}><Icon name="globe" /><span>{isArabic ? 'English' : 'العربية'}</span></a>
          <a className="btn btn-ghost btn-sm content-contact" href={contact} target="_blank" rel="noopener noreferrer"><WhatsAppIcon />{isArabic ? 'تواصل معنا' : 'Contact us'}</a>
        </div>
        <details className="mobile-menu"><summary aria-label={isArabic ? 'افتح القائمة' : 'Open menu'}><span></span><span></span><span></span></summary><nav aria-label={isArabic ? 'القائمة' : 'Mobile menu'}>{NAV.map(([key, en, ar]) => <a href={pagePath(key, lang)} key={key}>{isArabic ? ar : en}</a>)}<span className="menu-divider" />{LEGAL_NAV.map(([key, en, ar]) => <a href={pagePath(key, lang)} key={key}>{isArabic ? ar : en}</a>)}</nav></details>
      </div>
    </header>
    <main id="main">
      <section className={`content-hero${hasPreview ? ' content-hero--auto' : ''}${isLegal ? ' content-hero--legal' : ''}`}>
        <div className="hero-bg" aria-hidden="true"><div className="glow g1" /><div className="glow g2" /><div className="grid" /></div>
        <div className="container content-hero-inner">
          <div className="content-hero-copy">
          <nav className="breadcrumbs" aria-label={isArabic ? 'مسار الصفحة' : 'Breadcrumb'}><a href={home}>{isArabic ? 'الرئيسية' : 'Home'}</a><span aria-hidden="true">/</span><span aria-current="page">{page.eyebrow}</span></nav>
          <p className="eyebrow">{page.eyebrow}</p>
          <h1>{page.heading}</h1>
          <p className="content-lead">{page.intro}</p>
          {isLegal ? <div className="legal-meta"><span>{isArabic ? 'آخر تحديث:' : 'Last updated:'} {page.updated}</span><a href={contact} target="_blank" rel="noopener noreferrer">{isArabic ? 'تواصل معنا بشأن هذه الصفحة' : 'Contact us about this page'} <Icon name="arrow" /></a></div> : <div className="content-actions"><a className="btn btn-primary" {...downloadLinkProps}><Icon name="download" />{isArabic ? 'حمّل Autolinky لأندرويد' : 'Download Autolinky for Android'}</a><a className="btn btn-ghost" href={contact} target="_blank" rel="noopener noreferrer"><WhatsAppIcon />{isArabic ? 'اسألنا على واتساب' : 'Ask us on WhatsApp'}</a></div>}
          </div>
          {hasPreview && <ProductPreview lang={lang} id={`${slug}-product`} />}
        </div>
      </section>
      {page.sections && <section className="section content-body"><div className="container narrow">
        {page.sections.map((section, index) => <article className="content-section" key={section.heading}>
          <div className="content-section-number" aria-hidden="true">{String(index + 1).padStart(2, '0')}</div>
          <div><h2>{section.heading}</h2>{section.paragraphs.map(paragraph => <p key={paragraph}>{paragraph}</p>)}</div>
        </article>)}
      </div></section>}
      {page.questions && <section className="section content-body"><div className="container narrow faq-page-list">
        {page.questions.map(([question, answer]) => <article className="faq-answer" key={question}><h2>{question}</h2><p>{answer}</p></article>)}
      </div></section>}
      {page.answer && <section className="section answer-section"><div className="container narrow"><div className="answer-card"><span className="answer-icon"><Icon name="check" /></span><div><h2>{page.answerHeading}</h2><p>{page.answer}</p></div></div></div></section>}
      <section className="section related-section"><div className="container">
        <h2>{isLegal ? (isArabic ? 'صفحات مرتبطة' : 'Related pages') : (isArabic ? 'اكتشف المزيد عن Autolinky' : 'Explore more about Autolinky')}</h2>
        <div className="related-grid">{page.related.map(key => <a className="related-card" href={pagePath(key, lang)} key={key}><span>{PAGES[key][lang].eyebrow}</span><strong>{PAGES[key][lang].heading}</strong><Icon name="arrow" /></a>)}</div>
      </div></section>
    </main>
    <footer className="footer"><div className="container footer-inner"><div className="footer-brand"><a className="brand" href={home}><img src="/assets/logo.svg" alt="" width="28" height="28" /><span>Autolinky</span></a><p>{isArabic ? 'مساعد وظائف ذكي يساعدك على التقديم.' : 'The AI job assistant that helps you apply.'}</p></div><div className="footer-nav-groups"><nav className="footer-links" aria-label={isArabic ? 'روابط الموقع' : 'Site links'}>{NAV.map(([key, en, ar]) => <a href={pagePath(key, lang)} key={key}>{isArabic ? ar : en}</a>)}</nav><nav className="footer-links footer-legal" aria-label={isArabic ? 'السياسات والشروط' : 'Policies and terms'}>{LEGAL_NAV.map(([key, en, ar]) => <a href={pagePath(key, lang)} key={key}>{isArabic ? ar : en}</a>)}</nav></div></div><div className="container footer-bottom"><p>© {new Date().getFullYear()} Autolinky. {isArabic ? 'جميع الحقوق محفوظة. محتوى هذا الموقع والتطبيق وتصميمهما وبرمجياتهما محمية بحقوق النشر. أسماء الجهات الأخرى وعلاماتها التجارية ملك لأصحابها.' : 'All rights reserved. The content, design, and software of this site and app are protected by copyright. Third-party names and trademarks belong to their respective owners.'}</p><p className="muted">{isArabic ? 'Autolinky غير تابع لـ Google أو لأي منصة وظائف.' : 'Autolinky is not affiliated with Google or any job platform.'}</p></div></footer>
  </div>;
}
