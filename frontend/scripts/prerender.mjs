import fs from 'node:fs/promises';
import path from 'node:path';
import React from 'react';
import { renderToString } from 'react-dom/server';
import { createServer } from 'vite';
import QRCode from 'qrcode';

const dist = path.resolve('dist');
const branding = JSON.parse(await fs.readFile(new URL('../brand-assets.json', import.meta.url), 'utf8'));
const shell = await fs.readFile(path.join(dist, 'index.html'), 'utf8');
const server = await createServer({ mode: 'production', server: { middlewareMode: true, hmr: false }, appType: 'custom', logLevel: 'error' });
const [{ default: PageMarkup }, { default: ContentPage }, { META }, { SITE_URL: site, PAGES, pagePath }, { schemaFor }] = await Promise.all([
  server.ssrLoadModule('/src/PageMarkup.jsx'),
  server.ssrLoadModule('/src/ContentPage.jsx'),
  server.ssrLoadModule('/src/content.js'),
  server.ssrLoadModule('/src/pageContent.js'),
  server.ssrLoadModule('/src/pageMetadata.js'),
]);
const { DOWNLOAD_URL } = await server.ssrLoadModule('/src/config.js');
await fs.writeFile(path.join(dist, 'assets', 'qr-download.svg'), await QRCode.toString(new URL(DOWNLOAD_URL, site).href, { type: 'svg', margin: 2 }));

function esc(value) {
  return String(value).replace(/[&<>"']/g, char => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[char]);
}

function headFor(slug, lang, page, url, noindex = false) {
  const pair = [
    ['en', site + pagePath(slug, 'en')],
    ['ar', site + pagePath(slug, 'ar')],
  ];
  const alt = noindex ? '' : `${pair.map(([language, href]) => `<link rel="alternate" hreflang="${language}" href="${esc(href)}" />`).join('\n    ')}\n    <link rel="alternate" hreflang="x-default" href="${esc(pair[0][1])}" />`;
  const canonical = noindex ? '' : `<link rel="canonical" href="${esc(url)}" />`;
  const graph = noindex ? '' : `<script type="application/ld+json">${JSON.stringify(schemaFor(slug, lang, page, url)).replace(/</g, '\\u003c')}</script>`;
  return `${canonical}\n    ${alt}\n    <meta property="og:url" content="${esc(url)}" />\n    <meta property="og:locale" content="${lang === 'ar' ? 'ar_EG' : 'en_US'}" />\n    <meta property="og:locale:alternate" content="${lang === 'ar' ? 'en_US' : 'ar_EG'}" />\n    <meta name="twitter:title" content="${esc(page.title)}" />\n    <meta name="twitter:description" content="${esc(page.description)}" />\n    <meta name="twitter:image" content="${site}${branding.assets.social}" />\n    ${graph}`;
}

function documentFor(slug, lang, page, body, noindex = false) {
  const url = site + pagePath(slug, lang);
  return shell
    .replace('<html lang="en" dir="ltr">', `<html lang="${lang}" dir="${lang === 'ar' ? 'rtl' : 'ltr'}">`)
    .replace(/<title>[^<]*<\/title>/, `<title>${esc(page.title)}</title>`)
    .replace(/(<meta name="description" content=")[^"]*(" \/>)/, `$1${esc(page.description)}$2`)
    .replace(/(<meta name="theme-color" content=")[^"]*(" \/>)/, `$1${!slug ? '#171c19' : '#fbfbf9'}$2`)
    .replace(/(<meta name="robots" content=")[^"]*(" \/>)/, `$1${noindex ? 'noindex, follow' : 'index, follow, max-image-preview:large'}$2`)
    .replace(/(<meta property="og:title" content=")[^"]*(" \/>)/, `$1${esc(page.title)}$2`)
    .replace(/(<meta property="og:description" content=")[^"]*(" \/>)/, `$1${esc(page.description)}$2`)
    .replace(/(<meta property="og:image" content=")[^"]*(" \/>)/, `$1${site}${branding.assets.social}$2`)
    .replace('<!-- SEO_HEAD -->', headFor(slug, lang, page, url, noindex))
    .replace('<div id="root"></div>', `<div id="root">${body}</div>`);
}

async function writePage(route, html) {
  const directory = path.join(dist, route);
  await fs.mkdir(directory, { recursive: true });
  await fs.writeFile(path.join(directory, 'index.html'), html);
}

const sitemapUrls = [];
for (const lang of ['en', 'ar']) {
  const home = META[lang];
  const homeRoute = lang === 'ar' ? 'ar' : '';
  const homeBody = renderToString(React.createElement(PageMarkup, { lang, release: null, sticky: false }));
  await writePage(homeRoute, documentFor('', lang, home, homeBody));
  sitemapUrls.push({ slug: '', lang });
  for (const [slug, copy] of Object.entries(PAGES)) {
    const route = path.join(lang === 'ar' ? 'ar' : '', slug);
    const body = renderToString(React.createElement(ContentPage, { slug, lang }));
    await writePage(route, documentFor(slug, lang, copy[lang], body));
    sitemapUrls.push({ slug, lang });
  }
}
await writePage('open', documentFor('open', 'en', { title: 'Open AutoLinky in your browser', description: 'Instructions for downloading AutoLinky from an in-app browser.' }, '', true));
await writePage('workspace',documentFor('workspace','en',{title:'AutoLinky workspace',description:'Your job search workspace.'},'',true));
await fs.writeFile(path.join(dist, '404.html'), `<!doctype html>
<html lang="en" dir="ltr">
<head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><meta name="robots" content="noindex"><meta name="theme-color" content="#fbfbf9"><meta name="color-scheme" content="light"><title>Page not found | AutoLinky</title><link rel="icon" href="${branding.assets.favicon}" type="image/svg+xml"><link rel="icon" href="${branding.assets.faviconLight}" type="image/svg+xml" media="(prefers-color-scheme: light)"><link rel="icon" href="${branding.assets.faviconDark}" type="image/svg+xml" media="(prefers-color-scheme: dark)"><link rel="alternate icon" href="${branding.assets.faviconIco}" type="image/x-icon"><link rel="apple-touch-icon" href="${branding.assets.touchIcon}" sizes="180x180"><link rel="manifest" href="${branding.assets.manifest}"><meta property="og:image" content="${site}${branding.assets.social}"><style>
@font-face{font-family:Manrope;src:url('/assets/workspace-fonts/Manrope-Variable.ttf') format('truetype');font-weight:200 800;font-display:swap}
:root{color-scheme:light}
*{box-sizing:border-box}body{margin:0;background:#fbfbf9;color:#252a29;font:400 16px/1.65 Manrope,system-ui,sans-serif;min-height:100vh;display:grid;place-items:center;padding:32px}main{width:100%;max-width:580px}.brand{display:inline-flex;margin-bottom:64px}.brand img{display:block;width:auto;height:34px;max-width:100%}.eyebrow{font-size:11px;letter-spacing:.12em;color:#696f6c}h1{font-size:clamp(32px,7vw,48px);letter-spacing:-.04em;line-height:1.15;font-weight:600;margin:16px 0}p{color:#696f6c;margin:0 0 32px}.home{display:inline-flex;align-items:center;min-height:48px;padding:12px 20px;background:#171c19;color:#eeeade;border-radius:6px;text-decoration:none;font-size:13px;font-weight:600}.home:hover{background:#29342c}a:focus-visible{outline:2px solid #5f7253;outline-offset:5px}
</style></head><body><main><a class="brand" href="/" aria-label="AutoLinky home"><img src="${branding.assets.fullLogoLight}" alt="AutoLinky"></a><div class="eyebrow">404 / PAGE NOT FOUND</div><h1>Let’s find your way back.</h1><p>This page may have moved, or the address may be incomplete.</p><a class="home" href="/">Go to the homepage</a></main></body></html>`);

const sitemap = `<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" xmlns:xhtml="http://www.w3.org/1999/xhtml">\n${sitemapUrls.map(({ slug, lang }) => `  <url><loc>${site}${pagePath(slug, lang)}</loc><xhtml:link rel="alternate" hreflang="en" href="${site}${pagePath(slug, 'en')}"/><xhtml:link rel="alternate" hreflang="ar" href="${site}${pagePath(slug, 'ar')}"/><xhtml:link rel="alternate" hreflang="x-default" href="${site}${pagePath(slug, 'en')}"/></url>`).join('\n')}\n</urlset>\n`;
await fs.writeFile(path.join(dist, 'sitemap.xml'), sitemap);
await fs.writeFile(path.join(dist, 'robots.txt'), `User-agent: *\nAllow: /\nDisallow: /app/\nDisallow: /admin/\nDisallow: /ar/admin/\nDisallow: /workspace/\nSitemap: ${site}/sitemap.xml\n`);
await fs.writeFile(path.join(dist, 'llms.txt'), `# AutoLinky\n\nAutoLinky is a job assistant available on the web and Android. It matches collected jobs to a user's CV and helps the user apply by email, WhatsApp, and application links. Auto Apply sends eligible email applications from the user's connected Gmail when enabled. The free plan includes 20 email applications total; Pro removes that plan allowance while active, subject to sending limits.\n\nOfficial site: ${site}/\nFeatures: ${site}/features/\nAuto Apply: ${site}/auto-apply/\nHow it works: ${site}/how-it-works/\nPricing: ${site}/pricing/\nFAQ: ${site}/faq/\nPrivacy: ${site}/privacy/\nTerms: ${site}/terms/\nBilling and refunds: ${site}/billing/\nWebsite storage: ${site}/website-storage/\nData requests: ${site}/data-requests/\nArabic: ${site}/ar/\n`);
await server.close();
console.log(`Prerendered ${sitemapUrls.length} indexable pages, /open/, sitemap.xml, robots.txt, and llms.txt`);
