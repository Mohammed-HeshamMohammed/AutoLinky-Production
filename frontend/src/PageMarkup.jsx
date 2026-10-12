import { cloneElement, isValidElement } from 'react';
import { AR, MESSAGES, WHATSAPP } from './content';
import { LEGAL_NAV } from './legalContent';
import { HeroExperience, WorkflowStory } from './ProductExperience';
import WhatsAppIcon from './WhatsAppIcon';
import { downloadLinkProps } from './config';

function releaseText(release, lang) {
  if (!release?.version) return lang === 'ar' ? 'دائمًا أحدث نسخة' : 'Always the newest release';
  const parts = [(lang === 'ar' ? 'الإصدار ' : 'v') + release.version];
  if (release.size) parts.push(`${Math.round(release.size / 1048576)} ${lang === 'ar' ? 'ميجابايت' : 'MB'}`);
  if (release.publishedAt) {
    const date = new Date(release.publishedAt);
    if (!Number.isNaN(date.getTime())) {
      parts.push(`${lang === 'ar' ? 'تحديث ' : 'Updated '}${new Intl.DateTimeFormat(lang === 'ar' ? 'ar-EG-u-nu-latn' : 'en-US', { day: 'numeric', month: 'short', year: 'numeric' }).format(date)}`);
    }
  }
  return parts.join(' · ');
}

function localize(node, state) {
  if (Array.isArray(node)) return node.map((child, index) => {
    const localized = localize(child, state);
    return isValidElement(localized) ? cloneElement(localized, { key: localized.key ?? index }) : localized;
  });
  if (!isValidElement(node)) return node;
  const props = { ...node.props };
  const key = props['data-i18n'];
  let children = props.children;

  if (key && state.lang === 'ar' && AR[key] != null) {
    const value = AR[key];
    if (value.includes('<')) {
      props.dangerouslySetInnerHTML = { __html: value }; // Fixed, local translation strings only.
      children = undefined;
    } else children = value;
  } else if (children != null) children = localize(children, state);

  if (props['data-i18n-attr'] === 'aria-label:waAria' && state.lang === 'ar') props['aria-label'] = AR.waAria;
  if ('data-wa' in props) props.href = `https://wa.me/${WHATSAPP}?text=${encodeURIComponent(MESSAGES[props['data-wa']][state.lang])}`;
  if ('data-page-link' in props) props.href = `${state.lang === 'ar' ? '/ar' : ''}/${props['data-page-link']}/`;
  if ('data-lang-label' in props) children = state.lang === 'ar' ? 'English' : 'العربية';
  if ('data-lang-toggle' in props) {
    props['aria-label'] = state.lang === 'ar' ? 'English' : 'العربية';
    props.href = state.lang === 'ar' ? '/' : '/ar/';
  }
  if ('data-release-text' in props) children = releaseText(state.release, state.lang);
  if ('data-release-name' in props && state.release?.version) children = `${state.lang === 'ar' ? 'الإصدار ' : 'Autolinky '}${state.release.version}`;
  if ('data-year' in props) children = String(new Date().getFullYear());
  if ('data-sticky-cta' in props) props.className += state.sticky ? ' show' : '';
  delete props.children;
  return cloneElement(node, props, children);
}

export default function PageMarkup({ lang, release, sticky, onClick }) {
  return (
localize(<div onClick={onClick}>
  <svg className="sprite" aria-hidden="true" focusable="false">
    <symbol id="i-android" viewBox="0 0 24 24"><path d="M17.6 9.48 19.44 6.3a.38.38 0 0 0-.66-.38l-1.87 3.23a11.4 11.4 0 0 0-9.82 0L5.22 5.92a.38.38 0 0 0-.66.38L6.4 9.48A10.8 10.8 0 0 0 1 18h22a10.8 10.8 0 0 0-5.4-8.52ZM7 15.25a1.25 1.25 0 1 1 0-2.5 1.25 1.25 0 0 1 0 2.5Zm10 0a1.25 1.25 0 1 1 0-2.5 1.25 1.25 0 0 1 0 2.5Z" /></symbol>
  </svg>
  <a className="skip" href="#main" data-i18n="skip">Skip to content</a>
  <header className="nav" id="top">
    <div className="container nav-inner">
      <a className="brand" href={lang === 'ar' ? '/ar/' : '/'} aria-label="Autolinky">
        <img src="/assets/logo.svg" alt="" width={34} height={34} />
        <span>Autolinky</span>
      </a>
      <nav className="nav-links" aria-label={lang === 'ar' ? 'التنقل الرئيسي' : 'Main navigation'}>
        <a href="/features/" data-page-link="features" data-i18n="navFeatures">Features</a>
        <a href="/auto-apply/" data-page-link="auto-apply" data-i18n="navAuto">Auto Apply</a>
        <a href="/how-it-works/" data-page-link="how-it-works" data-i18n="navHow">How it works</a>
        <a href="/pricing/" data-page-link="pricing" data-i18n="navPricing">Pricing</a>
        <a href="/faq/" data-page-link="faq" data-i18n="navFaq">FAQ</a>
      </nav>
      <div className="nav-actions">
        <a className="lang-toggle" href="/ar/" data-lang-toggle aria-label="العربية">
          <svg viewBox="0 0 24 24" aria-hidden="true"><circle cx={12} cy={12} r="9.25" /><path d="M2.75 12h18.5M12 2.75c2.6 2.6 3.9 5.7 3.9 9.25s-1.3 6.65-3.9 9.25c-2.6-2.6-3.9-5.7-3.9-9.25S9.4 5.35 12 2.75Z" /></svg>
          <span data-lang-label>العربية</span>
        </a>
        <a className="btn btn-ghost btn-sm nav-contact" aria-label={lang === 'ar' ? 'تواصل معنا على واتساب' : 'Contact us on WhatsApp'} data-wa="contact" href="#" target="_blank" rel="noopener">
          <WhatsAppIcon />
          <span data-i18n="contact">Contact us</span>
        </a>
      </div>
      <details className="mobile-menu">
        <summary aria-label={lang === 'ar' ? 'افتح القائمة' : 'Open menu'}><span></span><span></span><span></span></summary>
        <nav aria-label={lang === 'ar' ? 'القائمة' : 'Mobile menu'}>
          <a href={lang === 'ar' ? '/ar/features/' : '/features/'}>{lang === 'ar' ? 'المميزات' : 'Features'}</a>
          <a href={lang === 'ar' ? '/ar/auto-apply/' : '/auto-apply/'}>{lang === 'ar' ? 'التقديم التلقائي' : 'Auto Apply'}</a>
          <a href={lang === 'ar' ? '/ar/how-it-works/' : '/how-it-works/'}>{lang === 'ar' ? 'طريقة العمل' : 'How it works'}</a>
          <a href={lang === 'ar' ? '/ar/pricing/' : '/pricing/'}>{lang === 'ar' ? 'الأسعار' : 'Pricing'}</a>
          <a href={lang === 'ar' ? '/ar/faq/' : '/faq/'}>{lang === 'ar' ? 'الأسئلة الشائعة' : 'FAQ'}</a>
          <span className="menu-divider" />
          {LEGAL_NAV.map(([key, en, ar]) => <a href={`${lang === 'ar' ? '/ar' : ''}/${key}/`} key={key}>{lang === 'ar' ? ar : en}</a>)}
        </nav>
      </details>
    </div>
  </header>
  <main id="main">
    <section className="hero">
      <div className="hero-bg" aria-hidden="true"><div className="glow g1" /><div className="glow g2" /><div className="grid" /></div>
      <div className="container hero-inner">
        <div className="hero-copy">
        <p className="badge reveal">
          <span className="badge-dot" />
          <span data-i18n="heroBadge">AI-powered job assistant</span>
        </p>
        <h1 className="hero-title reveal" data-i18n="heroTitle">Your next job.<br /><span className="grad">A smarter search.</span></h1>
        <p className="hero-sub reveal" data-i18n="heroSub">Autolinky searches for jobs, matches them to your CV with AI, and can <strong>auto-apply to eligible email jobs</strong> from your own Gmail with a tailored cover letter.</p>
        <div className="cta-block reveal" id="download">
          <a className="btn-download" {...downloadLinkProps}>
            <span className="btn-download-icon" aria-hidden="true">
              <svg viewBox="0 0 24 24"><use href="#i-android" /></svg>
            </span>
            <span className="btn-download-text">
              <small data-i18n="dlSmall">Free download for</small>
              <strong data-i18n="dlBig">Android</strong>
            </span>
            <span className="btn-download-arrow" aria-hidden="true">
              <svg viewBox="0 0 24 24"><path d="M12 4v12m0 0-5-5m5 5 5-5M5 20h14" /></svg>
            </span>
          </a>
          <p className="release-meta" data-release-meta aria-live="polite">
            <span className="pill-live"><span /><span data-i18n="latest">Latest version</span></span>
            <span data-release-text>Always the newest release</span>
          </p>
          <a className="btn btn-whatsapp" data-wa="contact" href="#" target="_blank" rel="noopener">
            <WhatsAppIcon />
            <span data-i18n="talkWhatsapp">Talk to us on WhatsApp</span>
          </a>
          <ul className="trust">
            <li><svg viewBox="0 0 24 24" aria-hidden="true"><path d="m5 12.5 4.5 4.5L19 7.5" /></svg><span data-i18n="trust1">20 free applications</span></li>
            <li><svg viewBox="0 0 24 24" aria-hidden="true"><path d="m5 12.5 4.5 4.5L19 7.5" /></svg><span data-i18n="trust2">No credit card</span></li>
            <li><svg viewBox="0 0 24 24" aria-hidden="true"><path d="m5 12.5 4.5 4.5L19 7.5" /></svg><span data-i18n="trust3">Updates install themselves</span></li>
          </ul>
        </div>
        </div>
        <HeroExperience lang={lang} />
      </div>
    </section>
    <section className="strip" aria-label="Highlights">
      <div className="container strip-inner">
        <div className="strip-item reveal"><b>24/7</b><span data-i18n="s1">Searching for jobs around the clock</span></div>
        <div className="strip-item reveal"><b data-i18n="s2b">Minutes</b><span data-i18n="s2">New jobs every few minutes</span></div>
        <div className="strip-item reveal"><b data-i18n="s3b">1 tap</b><span data-i18n="s3">Email, WhatsApp or apply link</span></div>
        <div className="strip-item reveal"><b>AI</b><span data-i18n="s4">A cover letter for every job</span></div>
      </div>
    </section>
    <section className="section" id="features">
      <div className="container">
        <header className="section-head reveal">
          <p className="eyebrow" data-i18n="featEyebrow">Features</p>
          <h2 data-i18n="featTitle">Everything you need to get hired, in one app</h2>
          <p data-i18n="featSub">Autolinky is the job assistant that does the boring part for you: finding, sorting and applying. You just pick the offer.</p>
        </header>
        <div className="bento">
          <article className="card card-wide reveal">
            <div className="card-icon blue"><svg viewBox="0 0 24 24"><path d="M9.5 2.75 11 7l4.25 1.5L11 10l-1.5 4.25L8 10 3.75 8.5 8 7l1.5-4.25ZM17 13l.9 2.6 2.6.9-2.6.9L17 20l-.9-2.6-2.6-.9 2.6-.9L17 13Z" /></svg></div>
            <h3 data-i18n="f1Title">AI matching that explains itself</h3>
            <p data-i18n="f1Body">Upload your CV once. Autolinky reads your skills, title and level, scores every new job, and tells you why it fits you, and which skills you're missing.</p>
            <div className="match-demo" aria-hidden="true">
              <div className="md-row"><span>Senior Flutter Developer</span><span className="md-bar"><i className="w92" /></span><b>92%</b></div>
              <div className="md-row"><span>Mobile Engineer</span><span className="md-bar"><i className="w85" /></span><b>85%</b></div>
              <div className="md-row"><span>Frontend Developer</span><span className="md-bar"><i className="w71" /></span><b>71%</b></div>
            </div>
          </article>
          <article className="card card-tall card-accent reveal">
            <div className="card-icon mint"><svg viewBox="0 0 24 24"><path d="M13 2 4.5 13.5H12L11 22l8.5-11.5H12L13 2Z" /></svg></div>
            <div className="auto-mini" aria-hidden="true">
              <div className="am-toggle"><span data-i18n="amOn">Auto apply</span><span className="aa-switch"><i /></span></div>
              <div className="am-row"><span className="dot ok" /><b>Nile Tech</b><small data-i18n="amSent">CV sent</small></div>
              <div className="am-row"><span className="dot ok" /><b>Delta Labs</b><small data-i18n="amSent">CV sent</small></div>
              <div className="am-row"><span className="dot ok" /><b>Cedar Soft</b><small data-i18n="amSent">CV sent</small></div>
            </div>
            <p className="tag" data-i18n="f2Tag">Star feature</p>
            <h3 data-i18n="f2Title">Auto Apply: your job hunt on autopilot</h3>
            <p data-i18n="f2Body">Turn it on once. Autolinky emails your CV to eligible matching jobs, one by one, while you live your day. The app tracks each send and can notify you when a CV goes out.</p>
            <a className="link-arrow" href="/auto-apply/" data-page-link="auto-apply"><span data-i18n="f2Link">See how Auto Apply works</span><svg viewBox="0 0 24 24" aria-hidden="true"><path d="M5 12h14m-5-5 5 5-5 5" /></svg></a>
          </article>
          <article className="card reveal">
            <div className="card-icon violet"><svg viewBox="0 0 24 24"><path d="M14 3H7a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2V8l-5-5Zm0 0v5h5M9 13h6m-6 4h4" /></svg></div>
            <h3 data-i18n="f3Title">A cover letter for every job</h3>
            <p data-i18n="f3Body">Email applications include a letter prepared for that role from your CV. You can review and edit it before a manual send.</p>
          </article>
          <article className="card reveal">
            <div className="card-icon blue"><svg viewBox="0 0 24 24"><path d="M3 7.5 12 13l9-5.5M4.5 5h15A1.5 1.5 0 0 1 21 6.5v11a1.5 1.5 0 0 1-1.5 1.5h-15A1.5 1.5 0 0 1 3 17.5v-11A1.5 1.5 0 0 1 4.5 5Z" /></svg></div>
            <h3 data-i18n="f4Title">Sent from your own Gmail</h3>
            <p data-i18n="f4Body">Recruiters reply straight to you, and every email sits in your Sent folder. Connected through a secure, revocable link that you control.</p>
          </article>
          <article className="card reveal">
            <div className="card-icon mint"><svg viewBox="0 0 24 24"><path d="M10 14a4.5 4.5 0 0 0 6.36 0l3-3a4.5 4.5 0 0 0-6.36-6.36l-1 1M14 10a4.5 4.5 0 0 0-6.36 0l-3 3a4.5 4.5 0 0 0 6.36 6.36l1-1" /></svg></div>
            <h3 data-i18n="f5Title">Every way to apply, one tap away</h3>
            <p data-i18n="f5Body">Email, WhatsApp, apply links, Easy Apply or the company site: Autolinky sorts every job by how to apply and opens the right one, with the message ready.</p>
          </article>
          <article className="card reveal">
            <div className="card-icon amber"><svg viewBox="0 0 24 24"><circle cx={12} cy={12} r={9} /><path d="M12 7v5l3 2" /></svg></div>
            <h3 data-i18n="f6Title">Fresh jobs, day and night</h3>
            <p data-i18n="f6Body">Our engine collects new job posts throughout the day, including opportunities shared outside traditional job boards.</p>
          </article>
          <article className="card reveal">
            <div className="card-icon violet"><svg viewBox="0 0 24 24"><path d="M9 6h11M9 12h11M9 18h11M3.5 6l1 1 2-2M3.5 12l1 1 2-2M3.5 18l1 1 2-2" /></svg></div>
            <h3 data-i18n="f7Title">Know exactly where you applied</h3>
            <p data-i18n="f7Body">Every application lands in Applied with its status: sent, sending, or why it failed. No double applications, no lost track.</p>
          </article>
        </div>
      </div>
    </section>
    <WorkflowStory lang={lang} />
    <section className="section" id="how">
      <div className="container">
        <header className="section-head reveal">
          <p className="eyebrow" data-i18n="howEyebrow">How it works</p>
          <h2 data-i18n="howTitle">From download to applications in 4 steps</h2>
        </header>
        <ol className="steps">
          <li className="step reveal"><span className="step-n">1</span><h3 data-i18n="h1Title">Download &amp; sign in</h3><p data-i18n="h1Body">Install the app and continue with Google in seconds.</p></li>
          <li className="step reveal"><span className="step-n">2</span><h3 data-i18n="h2Title">Upload your CV</h3><p data-i18n="h2Body">PDF or Word. AI reads your skills, title and experience.</p></li>
          <li className="step reveal"><span className="step-n">3</span><h3 data-i18n="h3Title">Connect Gmail once</h3><p data-i18n="h3Body">A quick two-minute setup, only if you want email applications.</p></li>
          <li className="step reveal"><span className="step-n">4</span><h3 data-i18n="h4Title">Turn on Auto Apply</h3><p data-i18n="h4Body">Watch matches roll in and applications go out.</p></li>
        </ol>
      </div>
    </section>
    <section className="section" id="pricing">
      <div className="container">
        <header className="section-head reveal">
          <p className="eyebrow" data-i18n="prEyebrow">Pricing</p>
          <h2 data-i18n="prTitle">Start free. Upgrade when you're ready.</h2>
        </header>
        <div className="plans">
          <article className="plan reveal">
            <p className="plan-name" data-i18n="pFree">Free</p>
            <p className="plan-big">20</p>
            <p className="plan-unit" data-i18n="pFreeUnit">email applications in total, on us</p>
            <ul className="checks">
              <li data-i18n="pf1">AI job matching with reasons</li>
              <li data-i18n="pf2">Every job and every way to apply</li>
              <li data-i18n="pf3">Auto Apply and AI cover letters</li>
              <li data-i18n="pf4">Applied tracker and notifications</li>
            </ul>
            <a className="btn btn-primary btn-block" {...downloadLinkProps}>
              <svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 4v12m0 0-5-5m5 5 5-5M5 20h14" /></svg>
              <span data-i18n="pFreeCta">Download free</span>
            </a>
          </article>
          <article className="plan plan-pro reveal">
            <p className="plan-name"><span data-i18n="pPro">Pro</span><span className="plan-badge" data-i18n="pPopular">Recommended</span></p>
            <p className="plan-big" data-i18n="pProBig">Unlimited</p>
            <p className="plan-unit" data-i18n="pProUnit">email applications while Pro is active, subject to sending limits</p>
            <ul className="checks">
              <li data-i18n="pp1">Everything in Free</li>
              <li data-i18n="pp2">Unlimited applications by email</li>
              <li data-i18n="pp3">Auto Apply that never stops at 20</li>
              <li data-i18n="pp4">Upgrade with one WhatsApp message</li>
            </ul>
            <a className="btn btn-whatsapp btn-block" data-wa="plans" href="#" target="_blank" rel="noopener">
              <WhatsAppIcon />
              <span data-i18n="pProCta">Ask about plans</span>
            </a>
          </article>
        </div>
      </div>
    </section>
    <section className="section" id="faq">
      <div className="container narrow">
        <header className="section-head reveal">
          <p className="eyebrow" data-i18n="faqEyebrow">FAQ</p>
          <h2 data-i18n="faqTitle">Questions, answered</h2>
        </header>
        <div className="faq">
          <details className="reveal"><summary data-i18n="q1">Is Autolinky free?</summary><p data-i18n="a1">Yes. Matching, browsing jobs, and your first 20 email applications in total are free. Ask us on WhatsApp about the current Pro plan.</p></details>
          <details className="reveal"><summary data-i18n="q2">How do I install the app?</summary><p data-i18n="a2">Tap the download button, open the file when it finishes, and allow installing from your browser if Android asks. Then continue with Google and upload your CV.</p></details>
          <details className="reveal"><summary data-i18n="q3">Is my email account safe?</summary><p data-i18n="a3">Autolinky never asks for your normal Google password. Email sending uses a separate, revocable access key that is stored encrypted, and you can disconnect it any time. See the Privacy page for details.</p></details>
          <details className="reveal"><summary data-i18n="q4">Will Auto Apply spam recruiters?</summary><p data-i18n="a4">No. It only sends to jobs that match you, one at a time, never to the same recruiter twice in a month, and within Gmail's safe sending limits.</p></details>
          <details className="reveal"><summary data-i18n="q5">How do I get updates?</summary><p data-i18n="a5">Automatically. Improvements download in the background and apply the next time you open the app. And this page always gives you the newest version.</p></details>
          <details className="reveal"><summary data-i18n="q6">Is there an iPhone version?</summary><p data-i18n="a6">Autolinky is on Android today. Message us on WhatsApp and we'll let you know as soon as the iPhone version is ready.</p></details>
        </div>
      </div>
    </section>
    <section className="section final">
      <div className="container">
        <div className="final-card reveal">
          <div className="final-glow" aria-hidden="true" />
          <img src="/assets/logo.svg" alt="" width={64} height={64} />
          <h2 data-i18n="finalTitle">Your next job is already posted.<br />Let Autolinky find it.</h2>
          <p data-i18n="finalSub">Download free, upload your CV, and let AI do the searching and the applying.</p>
          <div className="final-actions">
            <a className="btn-download btn-download-sm" {...downloadLinkProps}>
              <span className="btn-download-icon" aria-hidden="true"><svg viewBox="0 0 24 24"><use href="#i-android" /></svg></span>
              <span className="btn-download-text"><small data-i18n="dlSmall">Free download for</small><strong data-i18n="dlBig">Android</strong></span>
            </a>
            <a className="btn btn-ghost" data-wa="contact" href="#" target="_blank" rel="noopener">
              <WhatsAppIcon />
              <span data-i18n="contact">Contact us</span>
            </a>
          </div>
        </div>
      </div>
    </section>
  </main>
  <footer className="footer">
    <div className="container footer-inner">
      <div className="footer-brand">
        <a className="brand" href={lang === 'ar' ? '/ar/' : '/'}><img src="/assets/logo.svg" alt="" width={28} height={28} /><span>Autolinky</span></a>
        <p data-i18n="footTag">The AI job assistant that applies for you.</p>
      </div>
      <div className="footer-nav-groups">
        <nav className="footer-links" aria-label={lang === 'ar' ? 'روابط الموقع' : 'Site links'}>
          <a href="/features/" data-page-link="features" data-i18n="navFeatures">Features</a>
          <a href="/pricing/" data-page-link="pricing" data-i18n="navPricing">Pricing</a>
          <a href="/faq/" data-page-link="faq" data-i18n="navFaq">FAQ</a>
          <a data-wa="contact" href="#" target="_blank" rel="noopener" data-i18n="contact">Contact us</a>
        </nav>
        <nav className="footer-links footer-legal" aria-label={lang === 'ar' ? 'السياسات والشروط' : 'Policies and terms'}>
          {LEGAL_NAV.map(([key, en, ar]) => <a href={`${lang === 'ar' ? '/ar' : ''}/${key}/`} key={key}>{lang === 'ar' ? ar : en}</a>)}
        </nav>
      </div>
    </div>
    <div className="container footer-bottom">
      <p>© <span data-year>2026</span> Autolinky. <span data-i18n="rights">All rights reserved. The content, design, and software of this site and app are protected by copyright. Third-party names and trademarks belong to their respective owners.</span></p>
      <p className="muted" data-i18n="disclaimer">Autolinky is not affiliated with Google or any job platform.</p>
    </div>
  </footer>
  <div className="sticky-cta" data-sticky-cta>
    <img src="/assets/logo.svg" alt="" width={36} height={36} />
    <div><b>Autolinky</b><small data-i18n="stickySub">Free · Android</small></div>
    <a className="btn btn-primary btn-sm" {...downloadLinkProps} data-i18n="stickyCta">Download</a>
  </div>
  <a className="wa-float" data-wa="contact" href="#" target="_blank" rel="noopener" aria-label="WhatsApp" data-i18n-attr="aria-label:waAria">
    <WhatsAppIcon />
  </a>
  <dialog className="modal" data-modal="started">
    <button className="modal-x" type="button" data-close aria-label="Close">×</button>
    <div className="modal-icon mint"><svg viewBox="0 0 24 24"><path d="M12 4v12m0 0-5-5m5 5 5-5M5 20h14" /></svg></div>
    <h3 data-i18n="mdTitle">Your download has started</h3>
    <p className="muted" data-release-name />
    <ol className="modal-steps">
      <li data-i18n="mdStep1">Open the Autolinky file from your notifications or Downloads.</li>
      <li data-i18n="mdStep2">If Android asks, allow installing from your browser.</li>
      <li data-i18n="mdStep3">Open Autolinky, continue with Google and upload your CV.</li>
    </ol>
    <div className="modal-qr" data-desktop-only>
      <img src="/assets/qr-download.svg" alt={lang === 'ar' ? 'رمز تحميل Autolinky لأندرويد' : 'QR code to download Autolinky for Android'} width={132} height={132} />
      <p data-i18n="mdQr">On a computer? Scan this with your Android phone to download it there.</p>
    </div>
    <p className="modal-foot"><span data-i18n="mdRetry">Didn't start?</span> <a {...downloadLinkProps} data-i18n="mdRetryLink">Try again</a></p>
  </dialog>
  <dialog className="modal" data-modal="ios">
    <button className="modal-x" type="button" data-close aria-label="Close">×</button>
    <div className="modal-icon blue"><svg viewBox="0 0 24 24"><rect x={6} y="2.5" width={12} height={19} rx="2.5" /><path d="M10.5 18.5h3" /></svg></div>
    <h3 data-i18n="iosTitle">Autolinky is on Android for now</h3>
    <p className="muted" data-i18n="iosBody">The iPhone version is on its way. Message us and we'll tell you the moment it's ready, or download the Android app on an Android phone.</p>
    <div className="modal-actions">
      <a className="btn btn-whatsapp btn-block" data-wa="ios" href="#" target="_blank" rel="noopener"><WhatsAppIcon /><span data-i18n="iosCta">Notify me on WhatsApp</span></a>
      <a className="btn btn-ghost btn-block" {...downloadLinkProps} data-i18n="iosAnyway">Download the Android file anyway</a>
    </div>
  </dialog>
</div>, { lang, release, sticky })

  );
}
