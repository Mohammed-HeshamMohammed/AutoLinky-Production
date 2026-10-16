// GET /download (rewritten here by vercel.json): sends the visitor straight to the newest APK, so the download
// starts at once. One link that never changes, whatever the version.
//
//   /download                  the newest APK. Visitors from another app's built-in browser (LinkedIn, Facebook,
//                              Instagram...) go to /open first: those browsers often cannot download an APK
//   /download?direct=1         the APK, whatever the browser (the "download anyway" button of /open)
//   /download?src=linkedin     the same, and "linkedin" is stored with the count: one link per post or campaign
//
// Each download is counted through the private API when API_BASE_URL / STATS_KEY / STATS_SALT are set (see _stats.js). A counted
// answer must not be cached by the CDN (a cached redirect never reaches this function), so it is "no-store" then.
import { latestRelease, fixedAssetUrl, releasesPage } from './_release.js';
import * as stats from './_stats.js';

export default async function handler(req, res) {
  if (!['GET', 'HEAD'].includes(req.method || 'GET')) { res.statusCode = 405; res.setHeader('Allow', 'GET, HEAD'); res.end(); return; }
  const query = new URL(req.url || '/', 'https://autolinky.local').searchParams;
  const source = String(query.get('src') || '').replace(/[^\w.-]/g, '').slice(0, 40);
  const { device, inApp } = stats.describe(req.headers['user-agent']);
  const counted = stats.enabled();
  const isGet = req.method !== 'HEAD';

  if (inApp && device === 'android' && query.get('direct') !== '1') {
    if (isGet) await stats.record(req, { kind: 'in_app_prompt', source });
    res.statusCode = 302;
    res.setHeader('Location', '/open');
    res.setHeader('Cache-Control', 'no-store');
    res.end();
    return;
  }

  // With a fixed asset name (APK_FIXED_NAME) there is nothing to look up: GitHub's own "latest" link answers
  const fixed = fixedAssetUrl();
  const release = fixed ? await latestRelease({ cachedOnly: true }) : await latestRelease();
  const target = fixed || (release ? release.url : releasesPage);

  if (isGet && (fixed || release)) await stats.record(req, { kind: 'download', release, source });

  res.statusCode = 302;
  res.setHeader('Location', target);
  res.setHeader(
    'Cache-Control',
    !release && !fixed
      ? 'no-store'
      : counted
        ? 'no-store'
        : // Browsers ask again every time; the CDN may keep the answer a few minutes (a new release shows within that)
          'public, max-age=0, s-maxage=300, stale-while-revalidate=600',
  );
  res.end();
};
