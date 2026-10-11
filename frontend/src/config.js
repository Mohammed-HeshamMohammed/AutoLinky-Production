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
function endpoint(name, optional = false) {
  const value = optional ? env[name]?.trim() || '' : required(name);
  if (!value && optional) return '';
  const url = new URL(value, SITE_URL);
  if (!['http:', 'https:'].includes(url.protocol) || url.username || url.password || url.hash || (!value.startsWith('/') && !/^https?:\/\//.test(value)) || value.startsWith('//')) {
    throw new Error(`${name} must be a root-relative path or an HTTP(S) URL without credentials or a fragment.`);
  }
  return value;
}
export const DOWNLOAD_URL = endpoint('VITE_DOWNLOAD_URL');
export const RELEASE_API_URL = endpoint('VITE_RELEASE_API_URL', true);

export function directDownloadUrl(origin) {
  const url = new URL(DOWNLOAD_URL, origin);
  url.searchParams.set('direct', '1');
  return url;
}
