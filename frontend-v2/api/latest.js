// GET /api/latest: the newest release as JSON ({ version, tag, name, size, publishedAt, page, download }),
// shown under the download button. 503 when GitHub could not be reached.
import { latestRelease, releasesPage } from './_release.js';

export default async function handler(req, res) {
  if (!['GET', 'HEAD'].includes(req.method || 'GET')) { res.statusCode = 405; res.setHeader('Allow', 'GET, HEAD'); res.end(); return; }
  const release = await latestRelease();
  res.setHeader('Content-Type', 'application/json; charset=utf-8');
  if (!release) {
    res.statusCode = 503;
    res.setHeader('Cache-Control', 'no-store');
    res.end(JSON.stringify({ error: 'unavailable', page: releasesPage }));
    return;
  }
  res.statusCode = 200;
  res.setHeader('Cache-Control', 'public, max-age=60, s-maxage=300, stale-while-revalidate=600');
  const { version, tag, name, size, publishedAt, page } = release;
  res.end(JSON.stringify({ version, tag, name, size, publishedAt, page, download: '/download' }));
};
