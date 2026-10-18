import { META } from './content';
import { PAGES, SITE_URL as site, pagePath } from './pageContent';
import { DOWNLOAD_URL, DOWNLOAD_ENABLED } from './config';
import branding from '../brand-assets.json';

export function schemaFor(slug, lang, page, url) {
  const home = site + pagePath('', lang);
  const graph = [
    { '@type': 'Organization', '@id': `${site}/#organization`, name: 'AutoLinky', url: site + '/', logo: { '@type': 'ImageObject', url: site + branding.assets.organizationLogo } },
    { '@type': 'WebSite', '@id': `${site}/#website`, name: 'AutoLinky', url: site + '/', inLanguage: ['en', 'ar'] },
    { '@type': 'WebPage', '@id': `${url}#webpage`, url, name: page.title, description: page.description, inLanguage: lang, isPartOf: { '@id': `${site}/#website` } },
  ];
  if (!slug) graph.push({ '@type': 'SoftwareApplication', '@id': `${site}/#app`, name: 'AutoLinky', applicationCategory: 'BusinessApplication', operatingSystem: 'Android', url: site + '/', ...(DOWNLOAD_ENABLED ? { downloadUrl: new URL(DOWNLOAD_URL, site).href } : {}), description: page.description, offers: { '@type': 'Offer', price: '0', priceCurrency: 'USD', description: lang === 'ar' ? 'تتضمن الخطة المجانية 20 طلب تقديم بالبريد.' : 'The free plan includes 20 email applications.' } });
  if (slug) graph.push({ '@type': 'BreadcrumbList', itemListElement: [
    { '@type': 'ListItem', position: 1, name: lang === 'ar' ? 'الرئيسية' : 'Home', item: home },
    { '@type': 'ListItem', position: 2, name: page.eyebrow, item: url },
  ] });
  if (slug === 'faq') graph.push({ '@type': 'FAQPage', mainEntity: page.questions.map(([question, answer]) => ({ '@type': 'Question', name: question, acceptedAnswer: { '@type': 'Answer', text: answer } })) });
  return { '@context': 'https://schema.org', '@graph': graph };
}

export function updatePageHead({ slug, lang }) {
  const page = slug ? PAGES[slug][lang] : META[lang];
  const url = site + pagePath(slug, lang);
  function setTag(selector, tag, attributes) {
    let element = document.head.querySelector(selector);
    if (!element) { element = document.createElement(tag); document.head.append(element); }
    for (const [name, value] of Object.entries(attributes)) element.setAttribute(name, value);
    return element;
  }
  document.title = page.title;
  document.documentElement.lang = lang;
  document.documentElement.dir = lang === 'ar' ? 'rtl' : 'ltr';
  const meta = (name, content, attribute = 'name') => setTag(`meta[${attribute}="${name}"]`, 'meta', { [attribute]: name, content });
  meta('description', page.description);
  meta('theme-color', slug ? '#fbfbf9' : '#171c19');
  meta('color-scheme', 'light');
  meta('robots', 'index, follow, max-image-preview:large');
  for (const [name, content] of Object.entries({ title: page.title, description: page.description, url, image: site + branding.assets.social, locale: lang === 'ar' ? 'ar_EG' : 'en_US', 'locale:alternate': lang === 'ar' ? 'en_US' : 'ar_EG' })) meta(`og:${name}`, content, 'property');
  for (const [name, content] of Object.entries({ title: page.title, description: page.description, image: site + branding.assets.social })) meta(`twitter:${name}`, content);
  setTag('link[rel="canonical"]', 'link', { rel: 'canonical', href: url });
  for (const language of ['en', 'ar', 'x-default']) setTag(`link[rel="alternate"][hreflang="${language}"]`, 'link', { rel: 'alternate', hreflang: language, href: site + pagePath(slug, language === 'ar' ? 'ar' : 'en') });
  const schema = setTag('script[type="application/ld+json"]', 'script', { type: 'application/ld+json' });
  schema.textContent = JSON.stringify(schemaFor(slug, lang, page, url));
}
