import fs from 'node:fs/promises';
import path from 'node:path';
import React from 'react';
import { renderToString } from 'react-dom/server';
import { createServer } from 'vite';
import QRCode from 'qrcode';

const dist = path.resolve('dist');
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
  return `${canonical}\n    ${alt}\n    <meta property="og:url" content="${esc(url)}" />\n    <meta property="og:locale" content="${lang === 'ar' ? 'ar_EG' : 'en_US'}" />\n    <meta property="og:locale:alternate" content="${lang === 'ar' ? 'en_US' : 'ar_EG'}" />\n    <meta name="twitter:title" content="${esc(page.title)}" />\n    <meta name="twitter:description" content="${esc(page.description)}" />\n    <meta name="twitter:image" content="${site}/assets/og.png" />\n    ${graph}`;
}

function documentFor(slug, lang, page, body, noindex = false) {
  const url = site + pagePath(slug, lang);
  return shell
    .replace('<html lang="en" dir="ltr">', `<html lang="${lang}" dir="${lang === 'ar' ? 'rtl' : 'ltr'}">`)
    .replace(/<title>[^<]*<\/title>/, `<title>${esc(page.title)}</title>`)
    .replace(/(<meta name="description" content=")[^"]*(" \/>)/, `$1${esc(page.description)}$2`)
    .replace(/(<meta name="robots" content=")[^"]*(" \/>)/, `$1${noindex ? 'noindex, follow' : 'index, follow, max-image-preview:large'}$2`)
    .replace(/(<meta property="og:title" content=")[^"]*(" \/>)/, `$1${esc(page.title)}$2`)
    .replace(/(<meta property="og:description" content=")[^"]*(" \/>)/, `$1${esc(page.description)}$2`)
    .replace('<meta property="og:image" content="/assets/og.png" />', `<meta property="og:image" content="${site}/assets/og.png" />`)
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
await writePage('open', documentFor('open', 'en', { title: 'Open Autolinky in your browser', description: 'Instructions for downloading Autolinky from an in-app browser.' }, '', true));
await writePage('workspace',documentFor('workspace','en',{title:'AutoLinky workspace',description:'Your job search workspace.'},'',true));
await fs.writeFile(path.join(dist, '404.html'), '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="robots" content="noindex"><title>Page not found | Autolinky</title><link rel="icon" href="/assets/favicon.svg"></head><body style="font:16px system-ui;background:#070b1d;color:#eef1ff;display:grid;place-items:center;min-height:100vh"><main><h1>Page not found</h1><p>That Autolinky page does not exist.</p><a style="color:#3ee0ae" href="/">Go to the homepage</a></main></body></html>');

const sitemap = `<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" xmlns:xhtml="http://www.w3.org/1999/xhtml">\n${sitemapUrls.map(({ slug, lang }) => `  <url><loc>${site}${pagePath(slug, lang)}</loc><xhtml:link rel="alternate" hreflang="en" href="${site}${pagePath(slug, 'en')}"/><xhtml:link rel="alternate" hreflang="ar" href="${site}${pagePath(slug, 'ar')}"/><xhtml:link rel="alternate" hreflang="x-default" href="${site}${pagePath(slug, 'en')}"/></url>`).join('\n')}\n</urlset>\n`;
await fs.writeFile(path.join(dist, 'sitemap.xml'), sitemap);
await fs.writeFile(path.join(dist, 'robots.txt'), `User-agent: *\nAllow: /\nDisallow: /app/\nDisallow: /admin/\nDisallow: /ar/admin/\nDisallow: /workspace/\nSitemap: ${site}/sitemap.xml\n`);
await fs.writeFile(path.join(dist, 'llms.txt'), `# Autolinky\n\nAutolinky is an Android job assistant. It matches collected jobs to a user's CV and helps the user apply by email, WhatsApp, and application links. Auto Apply sends eligible email applications from the user's connected Gmail when enabled. The free plan includes 20 email applications total; Pro removes that plan allowance while active, subject to sending limits.\n\nOfficial site: ${site}/\nFeatures: ${site}/features/\nAuto Apply: ${site}/auto-apply/\nHow it works: ${site}/how-it-works/\nPricing: ${site}/pricing/\nFAQ: ${site}/faq/\nPrivacy: ${site}/privacy/\nTerms: ${site}/terms/\nBilling and refunds: ${site}/billing/\nWebsite storage: ${site}/website-storage/\nData requests: ${site}/data-requests/\nArabic: ${site}/ar/\n`);
await server.close();
console.log(`Prerendered ${sitemapUrls.length} indexable pages, /open/, sitemap.xml, robots.txt, and llms.txt`);
