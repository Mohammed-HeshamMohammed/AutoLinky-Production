import fs from 'node:fs';
import path from 'node:path';
import { createServer } from 'vite';
import { accountPaths } from '../workspace-routes.js';

const server = await createServer({ mode: 'production', server: { middlewareMode: true, hmr: false }, appType: 'custom', logLevel: 'error' });
const { SITE_URL, PAGES } = await server.ssrLoadModule('/src/pageContent.js');
const { LEGAL_NAV } = await server.ssrLoadModule('/src/legalContent.js');
const { DOWNLOAD_URL, RELEASE_API_URL } = await server.ssrLoadModule('/src/config.js');
await server.close();

const root = path.resolve('dist');
const site = SITE_URL;
const slugs = ['', ...Object.keys(PAGES)];
const pages = [];
const titles = new Set();

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

for (const lang of ['en', 'ar']) for (const slug of slugs) {
  const route = `/${lang === 'ar' ? 'ar/' : ''}${slug ? `${slug}/` : ''}`;
  const file = path.join(root, route.slice(1), 'index.html');
  assert(fs.existsSync(file), `Missing page: ${route}`);
  const html = fs.readFileSync(file, 'utf8');
  const title = html.match(/<title>([^<]+)<\/title>/)?.[1];
  assert(title && !titles.has(title), `Missing or duplicate title: ${route}`);
  titles.add(title);
  assert(html.includes(`<html lang="${lang}"`), `Wrong language: ${route}`);
  assert(html.includes(`<link rel="canonical" href="${site}${route}"`), `Wrong canonical: ${route}`);
  assert(html.includes('<h1') && html.includes('index, follow'), `Missing rendered content: ${route}`);
  assert(html.includes('hreflang="en"') && html.includes('hreflang="ar"'), `Missing language alternates: ${route}`);
  assert(html.includes('application/ld+json'), `Missing schema: ${route}`);
  for (const [legalSlug] of LEGAL_NAV) {
    const legalUrl = `/${lang === 'ar' ? 'ar/' : ''}${legalSlug}/`;
    assert(html.includes(`href="${legalUrl}"`), `Missing legal navigation ${legalUrl} on ${route}`);
  }
  pages.push({ route, html });
}

for (const { route, html } of pages) {
  for (const match of html.matchAll(/(?:href|src)="(\/[^"#?]*)/g)) {
    const value = match[1];
    if(accountPaths.includes(value))continue;
    if ([DOWNLOAD_URL, RELEASE_API_URL].filter(Boolean).some(endpoint => value === endpoint.split(/[?#]/)[0])) continue;
    const target = path.join(root, value.slice(1));
    const exists = fs.existsSync(target) && (fs.statSync(target).isFile() || fs.existsSync(path.join(target, 'index.html')));
    assert(exists, `Broken internal URL ${value} on ${route}`);
  }
}

const open = fs.readFileSync(path.join(root, 'open', 'index.html'), 'utf8');
const workspace=fs.readFileSync(path.join(root,'workspace','index.html'),'utf8');
assert(workspace.includes('noindex')&&!workspace.includes('rel="canonical"'),'Desktop shell must be private and excluded from indexing');
assert(open.includes('noindex') && !open.includes('rel="canonical"'), '/open/ must be noindex');
assert(fs.readFileSync(path.join(root, 'sitemap.xml'), 'utf8').match(/<loc>/g)?.length === pages.length, 'Sitemap count mismatch');
assert(fs.readFileSync(path.join(root, 'robots.txt'), 'utf8').includes(`${site}/sitemap.xml`), 'Sitemap missing from robots.txt');
assert(fs.existsSync(path.join(root, '404.html')), 'Missing 404 page');
for (const variant of ['android', 'ios']) {
  const app = path.join(root, 'app', variant);
  const html = fs.readFileSync(path.join(app, 'index.html'), 'utf8');
  assert(html.includes(`<base href="/app/${variant}/">`), `Wrong app base: ${variant}`);
  assert(fs.existsSync(path.join(app, 'main.dart.js')), `Missing browser app bundle: ${variant}`);
  assert(html.includes('noindex'), `Missing app noindex: ${variant}`);
}
console.log(`Verified ${pages.length} rendered pages, internal links, language alternates, sitemap, and noindex route`);
