import { useEffect, useLayoutEffect, useState } from 'react';
import { createRoot, hydrateRoot } from 'react-dom/client';
import PageMarkup from './PageMarkup';
import ContentPage from './ContentPage';
import { META } from './content';
import { PAGES } from './pageContent';
import './styles.css';
import './experience.css';
import { useSiteMotion } from './useSiteMotion';
import { usePageNavigation } from './usePageNavigation';
import { RELEASE_API_URL, DOWNLOAD_ENABLED, directDownloadUrl } from './config';
import DesktopApp from './workspace/DesktopApp.jsx';
import { workspaceRoute } from '../workspace-routes.js';

function initialLanguage() {
  const asked = new URLSearchParams(location.search).get('lang');
  if (asked === 'ar' || asked === 'en') return asked;
  try {
    const saved = localStorage.getItem('autolinky.lang');
    if (saved === 'ar' || saved === 'en') return saved;
  } catch { /* Storage may be disabled. */ }
  return /^ar\b/i.test(navigator.languages?.[0] || navigator.language || '') ? 'ar' : 'en';
}

// Public release metadata comes from the same-origin server. Every download
// continues through /download so in-app handling and statistics work consistently.
let releasePromise = null;
function loadRelease() {
  if (!DOWNLOAD_ENABLED) return Promise.resolve(null);
  releasePromise ||= fetch(RELEASE_API_URL, { headers: { Accept: 'application/json' }, signal: AbortSignal.timeout(10000) })
    .then(response => response.ok ? response.json() : null)
    .then(data => data?.version ? { version: data.version, size: data.size || null, publishedAt: data.publishedAt || null, url: '/download' } : null)
    .catch(() => null);
  return releasePromise;
}
if (typeof document !== 'undefined'&&!workspaceRoute(new URL(location.href))) loadRelease();

function platform() {
  if (/android/i.test(navigator.userAgent)) return 'android';
  if (/iPad|iPhone|iPod/.test(navigator.userAgent) || (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1)) return 'ios';
  return 'desktop';
}

function LandingPage() {
  const lang = location.pathname.startsWith('/ar/') ? 'ar' : 'en';
  const [release, setRelease] = useState(null);
  const [sticky, setSticky] = useState(false);
  const device = platform();
  useSiteMotion(lang);

  useLayoutEffect(() => {
    document.documentElement.lang = lang;
    document.documentElement.dir = lang === 'ar' ? 'rtl' : 'ltr';
    document.title = META[lang].title;
    document.querySelector('meta[name="description"]')?.setAttribute('content', META[lang].description);
    try { localStorage.setItem('autolinky.lang', lang); } catch { /* Storage may be disabled. */ }
  }, [lang]);

  useEffect(() => {
    let alive = true;
    loadRelease().then(data => { if (alive && data) setRelease(data); });
    return () => { alive = false; };
  }, []);

  useEffect(() => {
    document.documentElement.classList.add(`on-${device}`);
    const hero = document.querySelector('.hero .btn-download');
    const stickyObserver = hero && 'IntersectionObserver' in window
      ? new IntersectionObserver(([entry]) => setSticky(!entry.isIntersecting && entry.boundingClientRect.top < 0))
      : null;
    if (stickyObserver) stickyObserver.observe(hero);
    return () => {
      stickyObserver?.disconnect();
      document.documentElement.classList.remove(`on-${device}`);
    };
  }, [device]);

  function handleClick(event) {
    const target = event.target;
    if (!(target instanceof Element)) return;
    const dialog = target.closest('dialog.modal');
    if (dialog && (target === dialog || target.closest('[data-close]'))) {
      dialog.close();
      return;
    }
    const link = target.closest('a[data-download]');
    if (!link || event.metaKey || event.ctrlKey || event.shiftKey || event.button === 1) return;
    if (device === 'ios') {
      event.preventDefault();
      document.querySelector('[data-modal="ios"]')?.showModal();
    } else setTimeout(() => document.querySelector('[data-modal="started"]')?.showModal(), 350);
  }

  return <PageMarkup lang={lang} release={release} sticky={sticky} onClick={handleClick} />;
}

const OPEN_TEXT = {
  en: {
    title: 'Open Autolinky in your browser',
    body: "The app you are in can't always download files. Open this page in Chrome and the download starts at once.",
    chrome: 'Open in Chrome', copy: 'Copy the download link', anyway: 'Try downloading here',
    steps: [<>Tap the menu (⋮ or ⋯) at the top of this screen.</>, <>Choose <b>Open in browser</b> or <b>Open in Chrome</b>.</>, <>The download starts. Open the file when it finishes and allow the install if Android asks.</>],
    copied: 'Link copied. Paste it in Chrome.', manual: 'Copy this link and paste it in Chrome:',
  },
  ar: {
    title: 'افتح Autolinky في المتصفح',
    body: 'التطبيق اللي انت فيه مش بيحمّل الملفات دايمًا. افتح الصفحة دي في Chrome والتحميل هيبدأ على طول.',
    chrome: 'افتح في Chrome', copy: 'انسخ لينك التحميل', anyway: 'جرّب التحميل من هنا',
    steps: [<>اضغط على القائمة (⋮ أو ⋯) في أعلى الشاشة.</>, <>اختار <b>فتح في المتصفح</b> أو <b>Open in Chrome</b>.</>, <>التحميل هيبدأ. افتح الملف لما يخلص واسمح بالتثبيت لو أندرويد سأل.</>],
    copied: 'اتنسخ اللينك. الصقه في Chrome.', manual: 'انسخ اللينك ده والصقه في Chrome:',
  },
};

function OpenPage() {
  const [lang] = useState(initialLanguage);
  const [note, setNote] = useState('');
  const t = OPEN_TEXT[lang];
  const directUrl = directDownloadUrl(location.origin);
  const direct = directUrl.href;
  const chrome = `intent://${directUrl.host}${directUrl.pathname}${directUrl.search}#Intent;scheme=${directUrl.protocol.slice(0, -1)};package=com.android.chrome;S.browser_fallback_url=${encodeURIComponent(direct)};end`;
  useLayoutEffect(() => {
    document.documentElement.lang = lang;
    document.documentElement.dir = lang === 'ar' ? 'rtl' : 'ltr';
    document.title = t.title;
    document.querySelector('meta[name="robots"]')?.setAttribute('content', 'noindex');
  }, [lang, t.title]);
  async function copy() {
    try {
      await navigator.clipboard.writeText(direct);
      setNote(t.copied);
    } catch { setNote(`${t.manual} ${direct}`); }
  }
  return <main className="open"><div className="container"><section className="open-card">
    <img src="/assets/logo.svg" alt="" width="56" height="56" />
    <h1>{t.title}</h1><p>{t.body}</p>
    <div className="open-actions">
      <a className="btn btn-primary" href={chrome}>{t.chrome}</a>
      <button className="btn btn-ghost" type="button" onClick={copy}>{t.copy}</button>
      <a className="btn btn-ghost" href={direct}>{t.anyway}</a>
    </div>
    <p className="open-note" role="status">{note}</p>
    <ol className="open-steps">{t.steps.map((step, index) => <li key={index}><b>{lang === 'ar' ? ['١.', '٢.', '٣.'][index] : `${index + 1}.`}</b> {step}</li>)}</ol>
  </section></div></main>;
}

const root = document.getElementById('root');
function App() {
  const url = usePageNavigation();
  if(workspaceRoute(url))return <DesktopApp initialURL={url.pathname+url.search}/>;
  const route = url.pathname.split('/').filter(Boolean);
  const routeLang = route[0] === 'ar' ? 'ar' : 'en';
  const slug = routeLang === 'ar' ? route[1] : route[0];
  const key = url.pathname + url.search;
  return slug === 'open' ? <OpenPage /> : PAGES[slug] ? <ContentPage key={key} slug={slug} lang={routeLang} /> : <LandingPage key={key} />;
}
const app = <App />;
if (root.hasChildNodes()) hydrateRoot(root, app);
else createRoot(root).render(app);
