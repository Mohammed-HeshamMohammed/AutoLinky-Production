// VITE_ variables are public build configuration, never private credentials.
const env = import.meta.env;
function required(name) {
  const value = env[name]?.trim();
  if (!value) throw new Error(`${name} is required. Copy .env.example to .env before building.`);
  return value;
}
const site = new URL(required('VITE_SITE_URL'));
if (!['http:', 'https:'].includes(site.protocol) || site.username || site.password || site.pathname !== '/' || site.search || site.hash) {
  throw new Error('VITE_SITE_URL must be an HTTP(S) origin without a path, query, or credentials.');
}
export const SITE_URL = site.origin;
export const SITE_HOST = site.host;
export const WHATSAPP_NUMBER = required('VITE_WHATSAPP_NUMBER');
if (!/^\d{8,15}$/.test(WHATSAPP_NUMBER)) throw new Error('VITE_WHATSAPP_NUMBER must contain 8–15 digits including the country code, without + or spaces.');
// Releases are published in a public GitHub repository; the browser reads the newest one straight from GitHub.
const repo = env.VITE_RELEASES_REPO?.trim() || 'AMamdouh3/Autolinky-releases';
if (!/^[\w.-]+\/[\w.-]+$/.test(repo)) throw new Error('VITE_RELEASES_REPO must look like owner/repository.');
// Fallback link (the releases page) used until, or unless, the newest APK address is known.
export const DOWNLOAD_URL = `https://github.com/${repo}/releases/latest`;
export const RELEASE_API_URL = `https://api.github.com/repos/${repo}/releases/latest`;

export function directDownloadUrl(origin) {
  const url = new URL(DOWNLOAD_URL, origin);
  url.searchParams.set('direct', '1');
  return url;
}

// Set VITE_DOWNLOAD_ENABLED=false to turn the download buttons off.
export const DOWNLOAD_ENABLED = env.VITE_DOWNLOAD_ENABLED?.trim() !== 'false';
// Spread onto every download link: a live link when enabled, an inert placeholder otherwise.
export const downloadLinkProps = DOWNLOAD_ENABLED
  ? { href: DOWNLOAD_URL, 'data-download': '' }
  : { href: '#download', 'aria-disabled': 'true', tabIndex: -1, 'data-disabled': '' };
