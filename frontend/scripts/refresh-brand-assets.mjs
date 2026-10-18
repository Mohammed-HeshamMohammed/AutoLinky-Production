import { createHash } from 'node:crypto';
import { readFile, writeFile, mkdir, readdir, unlink } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const root = fileURLToPath(new URL('../', import.meta.url));

export function revisionFor(files, manifest) {
  const digest = createHash('sha256');
  for (const [name, bytes] of Object.entries(files).sort(([a], [b]) => a.localeCompare(b))) {
    digest.update(name).update('\0').update(bytes).update('\0');
  }
  return digest.update(JSON.stringify(manifest)).digest('hex').slice(0, 16);
}

// Reuse the approved ICO's PNG frame; never redraw or substitute a different mark.
function iconFrame(ico, size) {
  if (ico.readUInt16LE(0) !== 0 || ico.readUInt16LE(2) !== 1) throw new Error('Invalid approved favicon ICO');
  for (let i = 0; i < ico.readUInt16LE(4); i++) {
    const offset = 6 + i * 16;
    if ((ico[offset] || 256) !== size || (ico[offset + 1] || 256) !== size) continue;
    const frame = ico.subarray(ico.readUInt32LE(offset + 12), ico.readUInt32LE(offset + 12) + ico.readUInt32LE(offset + 8));
    if (!frame.subarray(0, 8).equals(Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]))) break;
    return frame;
  }
  throw new Error(`Approved favicon is missing its ${size}px PNG frame`);
}

export async function refreshBrandAssets() {
  const assets = path.join(root, 'public/assets');
  const read = name => readFile(path.join(assets, name));
  const [light, dark, ico, manifestText] = await Promise.all([
    read('logo-light.svg'), read('logo-dark.svg'), read('favicon.ico'), readFile(path.join(root, 'public/site.webmanifest'), 'utf8'),
  ]);
  const adaptive = light.toString().replace('<rect', '<style>:root{--tile:#EEEFE6;--ink:#252A29;--link:#5F7253}@media(prefers-color-scheme:dark){:root{--tile:#171C19;--ink:#EEEADE;--link:#BED2A8}}</style><rect')
    .replace(/(<rect\b[^>]*\bfill=)"#[^"]+"/i, '$1"var(--tile)"').replace(/fill="#252A29"/gi, 'fill="var(--ink)"').replace(/fill="#5F7253"/gi, 'fill="var(--link)"');
  const files = {
    'favicon.svg': Buffer.from(adaptive), 'favicon-light.svg': light, 'favicon-dark.svg': dark,
    'favicon.ico': ico, 'icon-48.png': iconFrame(ico, 48),
    'apple-touch-icon.png': await read('apple-touch-icon.png'),
    'icon-192.png': await read('icon-192.png'), 'icon-512.png': await read('icon-512.png'),
    'og.png': await read('og.png'), 'logo.svg': await read('logo.svg'),
    'logo-full-light.svg': await read('logo-full-light.svg'), 'logo-full-dark.svg': await read('logo-full-dark.svg'),
  };
  const manifest = JSON.parse(manifestText);
  // The previous implicit identity was the absolute start_url '/'. Keep it explicit
  // when moving the manifest to a hashed filename, so existing installs retain it.
  manifest.id ??= manifest.start_url;
  manifest.icons = [192, 512].map(size => ({ src: `/assets/icon-${size}.png`, sizes: `${size}x${size}`, type: 'image/png' }));
  const revision = revisionFor(files, manifest);
  const urls = Object.fromEntries(Object.keys(files).map(name => [name, `/assets/brand/${path.parse(name).name}.${revision}${path.extname(name)}`]));
  const output = path.join(assets, 'brand');
  await mkdir(output, { recursive: true });
  // This dedicated directory contains generated aliases only. Remove obsolete
  // revisions without touching any original artwork or unrelated public files.
  for (const name of await readdir(output)) {
    if (/^(?:favicon(?:-light|-dark)?|icon-(?:48|192|512)|apple-touch-icon|og|logo(?:-full-(?:light|dark))?|site)\.[a-f0-9]{16}\.(?:svg|ico|png|webmanifest)$/.test(name) && !name.includes(`.${revision}.`)) await unlink(path.join(output, name));
  }
  await Promise.all(Object.entries(files).map(([name, bytes]) => writeFile(path.join(root, 'public', urls[name]), bytes)));
  // Canonical browser/OS fallbacks must also contain the approved mark.
  await Promise.all([
    writeFile(path.join(root, 'public/favicon.ico'), ico),
    writeFile(path.join(root, 'public/favicon.svg'), files['favicon.svg']),
    writeFile(path.join(root, 'public/apple-touch-icon.png'), files['apple-touch-icon.png']),
    writeFile(path.join(assets, 'icon-48.png'), files['icon-48.png']),
    writeFile(path.join(assets, 'favicon-light.svg'), light), writeFile(path.join(assets, 'favicon-dark.svg'), dark),
  ]);
  manifest.icons = [192, 512].map(size => ({ src: urls[`icon-${size}.png`], sizes: `${size}x${size}`, type: 'image/png' }));
  const manifestJSON = JSON.stringify(manifest, null, 2) + '\n';
  const manifestURL = `/assets/brand/site.${revision}.webmanifest`;
  await Promise.all([
    writeFile(path.join(root, 'public/site.webmanifest'), manifestJSON),
    writeFile(path.join(root, 'public', manifestURL), manifestJSON),
  ]);
  const brand = { revision, assets: { favicon: urls['favicon.svg'], faviconLight: urls['favicon-light.svg'], faviconDark: urls['favicon-dark.svg'], faviconIco: urls['favicon.ico'], touchIcon: urls['apple-touch-icon.png'], icon48: urls['icon-48.png'], pwa192: urls['icon-192.png'], pwa512: urls['icon-512.png'], social: urls['og.png'], organizationLogo: urls['logo.svg'], fullLogoLight: urls['logo-full-light.svg'], fullLogoDark: urls['logo-full-dark.svg'], manifest: manifestURL } };
  await writeFile(path.join(root, 'brand-assets.json'), JSON.stringify(brand, null, 2) + '\n');
  const links = `    <!-- BRAND_ICONS -->\n    <link rel="icon" href="${brand.assets.favicon}" type="image/svg+xml" />\n    <link rel="icon" href="${brand.assets.faviconLight}" type="image/svg+xml" media="(prefers-color-scheme: light)" />\n    <link rel="icon" href="${brand.assets.faviconDark}" type="image/svg+xml" media="(prefers-color-scheme: dark)" />\n    <link rel="alternate icon" href="${brand.assets.faviconIco}" type="image/x-icon" />\n    <link rel="apple-touch-icon" href="${brand.assets.touchIcon}" sizes="180x180" />\n    <link rel="manifest" href="${brand.assets.manifest}" />\n    <!-- /BRAND_ICONS -->`;
  let html = await readFile(path.join(root, 'index.html'), 'utf8');
  if (html.includes('<!-- BRAND_ICONS -->')) html = html.replace(/    <!-- BRAND_ICONS -->[\s\S]*?<!-- \/BRAND_ICONS -->/, links);
  else {
    html = html.replace(/\s*<link rel="(?:icon|alternate icon|apple-touch-icon|manifest)"[^>]*>/g, '');
    html = html.replace('    <meta property="og:type"', links + '\n    <meta property="og:type"');
  }
  html = html.replace(/(<meta property="og:image" content=")[^"]*("\s*\/>)/, `$1${brand.assets.social}$2`);
  await writeFile(path.join(root, 'index.html'), html);
  return brand;
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const brand = await refreshBrandAssets();
  console.log(`Refreshed browser branding ${brand.revision}: approved themed icons, stable manifest identity, and social previews.`);
}
