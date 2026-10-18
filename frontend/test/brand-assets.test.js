import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import { revisionFor } from '../scripts/refresh-brand-assets.mjs';

const branding = JSON.parse(await readFile(new URL('../brand-assets.json', import.meta.url), 'utf8'));
const asset = url => readFile(new URL('../public' + url, import.meta.url));
const hash = bytes => createHash('sha256').update(bytes).digest('hex');

test('browser branding has fresh content addresses and retains the approved linked-A geometry', async () => {
  for (const url of Object.values(branding.assets)) {
    assert.match(url, new RegExp(`^/assets/brand/[^/]+\\.${branding.revision}\\.(svg|ico|png|webmanifest)$`));
    assert.ok((await asset(url)).length > 0, url);
  }
  const paths = svg => [...svg.matchAll(/<path\b[^>]*\bd="([^"]+)"/g)].map(match => match[1]);
  const approved = (await asset('/assets/logo-light.svg')).toString();
  for (const key of ['favicon', 'faviconLight', 'faviconDark']) assert.deepEqual(paths((await asset(branding.assets[key])).toString()), paths(approved));
  const adaptive = (await asset(branding.assets.favicon)).toString();
  assert.match(adaptive, /prefers-color-scheme:dark/);
  assert.match(adaptive, /fill="var\(--tile\)"/);
  const legacy48 = await asset('/assets/icon-48.png');
  assert.equal(legacy48.readUInt32BE(16), 48);
  assert.equal(legacy48.readUInt32BE(20), 48);
  assert.notEqual(hash(legacy48), 'e9c570a833c156756fbbaa8e7f6a9817c22aaf95e40e6f4c4a097314ce46c780', 'The retired blue 48px icon must not survive');
  assert.deepEqual(legacy48, await asset(branding.assets.icon48));
  assert.deepEqual(await asset('/favicon.ico'), await asset('/assets/favicon.ico'));
  assert.deepEqual(await asset('/favicon.svg'), await asset(branding.assets.favicon));
  assert.deepEqual(await asset('/apple-touch-icon.png'), await asset(branding.assets.touchIcon));
});

test('hashed manifest and document metadata preserve the installed app identity', async () => {
  const manifest = JSON.parse((await asset(branding.assets.manifest)).toString());
  assert.deepEqual(manifest, JSON.parse((await asset('/site.webmanifest')).toString()));
  assert.equal(new URL(manifest.id, 'https://auto-linky.com' + branding.assets.manifest).href, 'https://auto-linky.com/');
  assert.equal(manifest.start_url, '/');
  assert.equal(manifest.name, 'AutoLinky');
  assert.equal(manifest.short_name, 'AutoLinky');
  assert.deepEqual(manifest.icons.map(icon => icon.src), [branding.assets.pwa192, branding.assets.pwa512]);
  const html = await readFile(new URL('../index.html', import.meta.url), 'utf8');
  for (const key of ['favicon', 'faviconLight', 'faviconDark', 'faviconIco', 'touchIcon', 'manifest', 'social']) assert.ok(html.includes(branding.assets[key]), key);
  assert.match(html, /media="\(prefers-color-scheme: light\)"/);
  assert.match(html, /media="\(prefers-color-scheme: dark\)"/);
  assert.doesNotMatch(html, /(?:href|content)="\/(?:assets\/(?:favicon\.(?:svg|ico)|apple-touch-icon\.png|og\.png)|site\.webmanifest)"/);
});

test('asset or install-metadata changes invalidate the shared browser branding revision', () => {
  const files = { 'favicon.svg': Buffer.from('approved mark'), 'icon.png': Buffer.from([1, 2, 3]) };
  const identity = { id: '/', start_url: '/', name: 'AutoLinky' };
  const revision = revisionFor(files, identity);
  assert.equal(revisionFor({ 'icon.png': files['icon.png'], 'favicon.svg': files['favicon.svg'] }, identity), revision);
  assert.notEqual(revisionFor({ ...files, 'icon.png': Buffer.from([1, 2, 4]) }, identity), revision);
  assert.notEqual(revisionFor(files, { ...identity, theme_color: '#171c19' }), revision);
});
