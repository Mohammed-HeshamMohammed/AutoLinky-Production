import { BrandWordmark } from './BrandMark';
import { useLayoutEffect } from 'react';
import { MESSAGES, WHATSAPP } from './content';
import { NAV, PAGES, pagePath } from './pageContent';
import { LEGAL_NAV } from './legalContent';
import { ProductPreview } from './ProductExperience';
import { useSiteMotion } from './useSiteMotion';
import { downloadLinkProps } from './config';
import SiteHeader, { accountHref } from './SiteHeader';

export default function ContentPage({ slug, lang }) {
  const page = PAGES[slug][lang];
  const isArabic = lang === 'ar';
  const isLegal = Boolean(page.legal);
  const hasPreview = slug === 'auto-apply' || slug === 'features';
  useSiteMotion(slug);
  const home = pagePath('', lang);
  const contact = `https://wa.me/${WHATSAPP}?text=${encodeURIComponent(MESSAGES.contact[lang])}`;

  useLayoutEffect(() => {
    document.documentElement.lang = lang;
    document.documentElement.dir = isArabic ? 'rtl' : 'ltr';
    document.title = page.title;
    document.querySelector('meta[name="description"]')?.setAttribute('content', page.description);
    try { localStorage.setItem('autolinky.lang', lang); } catch { /* Storage may be disabled. */ }
  }, [lang, isArabic, page.title, page.description]);

  return <div className="site-page">
    <a className="skip" href="#main">{isArabic ? 'تخطَّ إلى المحتوى' : 'Skip to content'}</a>
    <SiteHeader lang={lang} slug={slug} />
    <main id="main">
      <section className={`content-hero${hasPreview ? ' content-hero--auto' : ''}${isLegal ? ' content-hero--legal' : ''}`}>
        <div className="hero-bg" aria-hidden="true"><div className="glow g1" /><div className="glow g2" /><div className="grid" /></div>
        <div className="container content-hero-inner">
          <div className="content-hero-copy">
          <nav className="breadcrumbs" aria-label={isArabic ? 'مسار الصفحة' : 'Breadcrumb'}><a href={home}>{isArabic ? 'الرئيسية' : 'Home'}</a><span aria-hidden="true">/</span><span aria-current="page">{page.eyebrow}</span></nav>
          <p className="eyebrow">{page.eyebrow}</p>
          <h1>{page.heading}</h1>
          <p className="content-lead">{page.intro}</p>
          {isLegal ? <div className="legal-meta"><span>{isArabic ? 'آخر تحديث:' : 'Last updated:'} {page.updated}</span><a href={contact} target="_blank" rel="noopener noreferrer">{isArabic ? 'تواصل معنا بشأن هذه الصفحة' : 'Contact us about this page'} </a></div> : <div className="content-actions"><a className="btn btn-primary" href={accountHref('signup',lang)}>{isArabic ? 'أنشئ حسابك المجاني' : 'Create your free account'}</a><a className="btn btn-ghost" {...downloadLinkProps}>{isArabic ? 'حمّل AutoLinky لأندرويد' : 'Download AutoLinky for Android'}</a><a className="btn btn-ghost" href={contact} target="_blank" rel="noopener noreferrer">{isArabic ? 'اسألنا على واتساب' : 'Ask us on WhatsApp'}</a></div>}
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
      {page.answer && <section className="section answer-section"><div className="container narrow"><div className="answer-card"><div><h2>{page.answerHeading}</h2><p>{page.answer}</p></div></div></div></section>}
      <section className="section related-section"><div className="container">
        <h2>{isLegal ? (isArabic ? 'صفحات مرتبطة' : 'Related pages') : (isArabic ? 'اكتشف المزيد عن AutoLinky' : 'Explore more about AutoLinky')}</h2>
        <div className="related-grid">{page.related.map(key => <a className="related-card" href={pagePath(key, lang)} key={key}><span>{PAGES[key][lang].eyebrow}</span><strong>{PAGES[key][lang].heading}</strong></a>)}</div>
      </div></section>
    </main>
    <footer className="footer"><div className="container footer-inner"><div className="footer-brand"><a className="brand" href={home}><BrandWordmark height={28}/></a><p>{isArabic ? 'مساعد وظائف ذكي يساعدك على التقديم.' : 'The AI job assistant that helps you apply.'}</p></div><div className="footer-nav-groups"><nav className="footer-links" aria-label={isArabic ? 'روابط الموقع' : 'Site links'}><a href={accountHref('login',lang)}>{isArabic ? 'تسجيل الدخول' : 'Log in'}</a>{NAV.map(([key, en, ar]) => <a href={pagePath(key, lang)} key={key}>{isArabic ? ar : en}</a>)}</nav><nav className="footer-links footer-legal" aria-label={isArabic ? 'السياسات والشروط' : 'Policies and terms'}>{LEGAL_NAV.map(([key, en, ar]) => <a href={pagePath(key, lang)} key={key}>{isArabic ? ar : en}</a>)}</nav></div></div><div className="container footer-bottom"><p>© {new Date().getFullYear()} AutoLinky. {isArabic ? 'جميع الحقوق محفوظة. محتوى هذا الموقع والتطبيق وتصميمهما وبرمجياتهما محمية بحقوق النشر. أسماء الجهات الأخرى وعلاماتها التجارية ملك لأصحابها.' : 'All rights reserved. The content, design, and software of this site and app are protected by copyright. Third-party names and trademarks belong to their respective owners.'}</p><p className="muted">{isArabic ? 'AutoLinky غير تابع لـ Google أو لأي منصة وظائف.' : 'AutoLinky is not affiliated with Google or any job platform.'}</p></div></footer>
  </div>;
}
