import { useEffect, useState } from 'react';
import { flushSync } from 'react-dom';
import { PAGES, pagePath } from './pageContent';
import { updatePageHead } from './pageMetadata';

function routeFor(url) {
  const parts = url.pathname.split('/').filter(Boolean);
  const lang = parts[0] === 'ar' ? 'ar' : 'en';
  if (lang === 'ar') parts.shift();
  const slug = parts[0] || '';
  return parts.length <= 1 && (!slug || Object.hasOwn(PAGES, slug)) ? { slug, lang } : null;
}

// Ordinary anchors still work before hydration, with JavaScript disabled, and in new tabs.
export function usePageNavigation() {
  const [url, setUrl] = useState(() => new URL(location.href));
  useEffect(() => {
    if (!routeFor(new URL(location.href))) return;
    const root = document.getElementById('root');
    const reduced = window.matchMedia('(prefers-reduced-motion: reduce)');
    const scrollPositions = new Map();
    const previousRestoration = history.scrollRestoration;
    let entry = history.state?.autolinkyEntry || crypto.randomUUID();
    let currentUrl = new URL(location.href);
    let generation = 0, nativeTransition, fallbackAnimation, suppressHash = false;
    history.replaceState({ ...history.state, autolinkyEntry: entry }, '', location.href);
    history.scrollRestoration = 'manual';
    updatePageHead(routeFor(currentUrl));

    function savePosition() { scrollPositions.set(entry, [window.scrollX, window.scrollY]); }
    savePosition();
    function positionPage(destination, position, focus) {
      const main = document.getElementById('main');
      if (focus && main) {
        main.setAttribute('tabindex', '-1');
        main.focus({ preventScroll: true });
      }
      if (position) window.scrollTo({ left: position[0], top: position[1], behavior: 'instant' });
      else {
        let anchor;
        try { anchor = destination.hash && document.getElementById(decodeURIComponent(destination.hash.slice(1))); } catch { /* Malformed fragment. */ }
        if (anchor) anchor.scrollIntoView({ behavior: 'instant' });
        else window.scrollTo({ top: 0, left: 0, behavior: 'instant' });
      }
      savePosition();
    }
    async function navigate(destination, { pop = false, position } = {}) {
      const route = routeFor(destination);
      if (!route) { location.assign(destination.href); return; }
      const ticket = ++generation;
      nativeTransition?.skipTransition();
      fallbackAnimation?.cancel();
      const commit = () => {
        if (ticket !== generation) return;
        if (!pop) {
          savePosition();
          entry = crypto.randomUUID();
          history.pushState({ autolinkyEntry: entry }, '', destination.href);
        } else entry = history.state?.autolinkyEntry || crypto.randomUUID();
        currentUrl = destination;
        flushSync(() => setUrl(destination));
        updatePageHead(route);
        positionPage(destination, position, true);
      };
      if (reduced.matches) { commit(); return; }
      if (document.startViewTransition) {
        nativeTransition = document.startViewTransition(commit);
        // Skip/replacement and background tabs can reject ready; the update still runs.
        nativeTransition.ready.catch(() => {});
        await nativeTransition.finished.catch(() => {});
      } else {
        try {
          fallbackAnimation = root.animate([{ opacity: 1, transform: 'translateY(0)' }, { opacity: 0, transform: 'translateY(-5px)' }], { duration: 110, easing: 'ease-in', fill: 'forwards' });
          await fallbackAnimation.finished;
          commit();
          fallbackAnimation.cancel();
          if (reduced.matches) return;
          fallbackAnimation = root.animate([{ opacity: 0, transform: 'translateY(12px)' }, { opacity: 1, transform: 'translateY(0)' }], { duration: 340, easing: 'cubic-bezier(.22,1,.36,1)' });
          await fallbackAnimation.finished;
        } catch { /* A newer navigation or reduced-motion preference cancelled this animation. */ }
      }
    }
    function onClick(event) {
      if (event.defaultPrevented || event.button !== 0 || event.metaKey || event.ctrlKey || event.shiftKey || event.altKey || !(event.target instanceof Element)) return;
      const link = event.target.closest('a[href]');
      if (!link || link.hasAttribute('download') || (link.target && link.target !== '_self') || link.relList.contains('external')) return;
      const destination = new URL(link.href, location.href);
      if (destination.origin !== location.origin || !routeFor(destination)) return;
      // Let the browser handle local section links and skip links normally.
      if (destination.pathname === currentUrl.pathname && destination.search === currentUrl.search && destination.hash) return;
      event.preventDefault();
      if (destination.href === currentUrl.href) return;
      destination.pathname = pagePath(routeFor(destination).slug, routeFor(destination).lang);
      void navigate(destination);
    }
    function onPop() {
      const destination = new URL(location.href);
      suppressHash = destination.hash !== currentUrl.hash;
      if (destination.pathname === currentUrl.pathname && destination.search === currentUrl.search) {
        entry = history.state?.autolinkyEntry || crypto.randomUUID();
        currentUrl = destination;
        positionPage(destination, scrollPositions.get(entry), false);
        return;
      }
      void navigate(destination, { pop: true, position: scrollPositions.get(history.state?.autolinkyEntry) });
    }
    function onHash() {
      if (suppressHash) { suppressHash = false; return; }
      if (location.pathname !== currentUrl.pathname) return;
      currentUrl = new URL(location.href);
      entry = crypto.randomUUID();
      history.replaceState({ ...history.state, autolinkyEntry: entry }, '', location.href);
      savePosition();
    }
    function onPreference() {
      if (!reduced.matches) return;
      nativeTransition?.skipTransition();
      // Finish an in-flight fallback instead of abandoning its pending navigation.
      fallbackAnimation?.finish();
    }
    document.addEventListener('click', onClick);
    window.addEventListener('popstate', onPop);
    window.addEventListener('hashchange', onHash);
    window.addEventListener('scroll', savePosition, { passive: true });
    reduced.addEventListener('change', onPreference);
    return () => {
      generation++;
      nativeTransition?.skipTransition(); fallbackAnimation?.cancel();
      history.scrollRestoration = previousRestoration;
      document.removeEventListener('click', onClick);
      window.removeEventListener('popstate', onPop);
      window.removeEventListener('hashchange', onHash);
      window.removeEventListener('scroll', savePosition);
      reduced.removeEventListener('change', onPreference);
    };
  }, []);
  return url;
}
