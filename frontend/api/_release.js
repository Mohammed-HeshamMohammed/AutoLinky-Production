// The newest Autolinky APK published on GitHub, for /download and /api/latest.
//
// Releases live in a public repository (RELEASES_REPO), so anyone can download them. The asset's name carries the
// version (autolinky-1.0.0+1.apk), so GitHub's fixed ".../releases/latest/download/<name>" link cannot work: we ask
// GitHub which release is the latest and take the .apk attached to it. Publishing a new release (marked "latest",
// with an .apk attached) is all it takes: the site follows within CACHE_MS, nothing to change here.
//
// Lookups, in order:
//   1. the REST API: /releases/latest, else the newest published release that has an .apk
//      (60 calls an hour per IP without a token; set GITHUB_TOKEN in Vercel to raise that to 5,000)
//   2. the github.com pages (not counted against the API limit): the "latest" redirect gives the tag, the release's
//      asset list gives the .apk link
//   3. the last answer we had, however old
// When all fail, callers send the visitor to the releases page itself.
//
// Faster and sturdier: attach a second copy of the APK with a FIXED name (say autolinky.apk) to every release and set
// APK_FIXED_NAME=autolinky.apk in Vercel. /download then needs no lookup at all: it redirects to GitHub's own
// ".../releases/latest/download/autolinky.apk", which always points at the newest release (see fixedAssetUrl).

const REPO = process.env.RELEASES_REPO || 'AMamdouh3/Autolinky-releases';
if (!/^[\w.-]+\/[\w.-]+$/.test(REPO)) throw new Error('Invalid RELEASES_REPO');
const CACHE_MS = 5 * 60 * 1000;
const TIMEOUT_MS = 4000;

let cached = null; // { at, release }: kept while the function instance lives

const releasesPage = `https://github.com/${REPO}/releases/latest`;

const isApk = (name) => typeof name === 'string' && name.toLowerCase().endsWith('.apk');

// "v1.0.0+1" -> "1.0.0" (what people call the version; "+1" is the build number)
const versionOf = (tag) => String(tag || '').replace(/^[^0-9]*/, '').split('+')[0] || String(tag || '');

function fromApi(release) {
  // "uploaded" = fully there (an upload still running is "open")
  const asset = (release.assets || []).find((a) => isApk(a.name) && (a.state || 'uploaded') === 'uploaded');
  if (!asset) return null;
  return {
    tag: release.tag_name,
    version: versionOf(release.tag_name),
    name: asset.name,
    url: asset.browser_download_url,
    size: asset.size || null,
    publishedAt: release.published_at || asset.updated_at || null,
    page: release.html_url,
  };
}

async function get(url, options = {}) {
  return fetch(url, { ...options, signal: AbortSignal.timeout(TIMEOUT_MS) });
}

async function viaApi() {
  const headers = {
    Accept: 'application/vnd.github+json',
    'User-Agent': 'autolinky-website',
    'X-GitHub-Api-Version': '2022-11-28',
  };
  if (process.env.GITHUB_TOKEN) headers.Authorization = `Bearer ${process.env.GITHUB_TOKEN}`;

  const latest = await get(`https://api.github.com/repos/${REPO}/releases/latest`, { headers });
  if (latest.ok) {
    const found = fromApi(await latest.json());
    if (found) return found;
  } else if (latest.status !== 404) {
    throw new Error(`GitHub API answered ${latest.status}`);
  }
  // No "latest" release, or one without an .apk: the newest published release that has one
  const list = await get(`https://api.github.com/repos/${REPO}/releases?per_page=20`, { headers });
  if (!list.ok) throw new Error(`GitHub API answered ${list.status}`);
  for (const release of await list.json()) {
    if (release.draft || release.prerelease) continue;
    const found = fromApi(release);
    if (found) return found;
  }
  return null;
}

async function viaPages() {
  const latest = await get(releasesPage, { redirect: 'manual', headers: { 'User-Agent': 'autolinky-website' } });
  const location = latest.headers.get('location') || '';
  const match = location.match(/\/releases\/tag\/([^/?#]+)/);
  if (!match) throw new Error(`no release tag in the latest-release redirect (${latest.status})`);
  const tag = decodeURIComponent(match[1]);

  const assets = await get(`https://github.com/${REPO}/releases/expanded_assets/${encodeURIComponent(tag)}`, {
    headers: { 'User-Agent': 'autolinky-website' },
  });
  if (!assets.ok) throw new Error(`release assets page answered ${assets.status}`);
  const html = await assets.text();
  const href = [...html.matchAll(/href="([^"]+\/releases\/download\/[^"]+)"/g)]
    .map((m) => m[1].replace(/&amp;/g, '&'))
    .find((h) => isApk(decodeURIComponent(h.split('/').pop())));
  if (!href) return null;
  return {
    tag,
    version: versionOf(tag),
    name: decodeURIComponent(href.split('/').pop()),
    url: new URL(href, 'https://github.com').toString(),
    size: null,
    publishedAt: null,
    page: `https://github.com/${REPO}/releases/tag/${encodeURIComponent(tag)}`,
  };
}

// The link GitHub itself keeps pointing at the newest release's asset of that name. '' when APK_FIXED_NAME is not set.
function fixedAssetUrl() {
  const name = String(process.env.APK_FIXED_NAME || '').trim();
  return name ? `https://github.com/${REPO}/releases/latest/download/${encodeURIComponent(name)}` : '';
}

// cachedOnly: what is already known (maybe nothing, maybe old), with no call to GitHub: for the counters
async function latestRelease({ cachedOnly = false } = {}) {
  if (cachedOnly) return cached ? cached.release : null;
  if (cached && Date.now() - cached.at < CACHE_MS) return cached.release;
  for (const lookup of [viaApi, viaPages]) {
    try {
      const release = await lookup();
      if (release) {
        cached = { at: Date.now(), release };
        return release;
      }
    } catch (error) {
      console.warn(`[release] ${lookup.name} failed: ${error.message}`);
    }
  }
  return cached ? cached.release : null;
}

export { latestRelease, fixedAssetUrl, releasesPage, REPO };
