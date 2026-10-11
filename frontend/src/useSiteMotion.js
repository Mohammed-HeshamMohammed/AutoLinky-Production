import { useEffect } from 'react';

// One observer and one scroll update for the page. No permanent JavaScript loop.
export function useSiteMotion(key) {
  useEffect(() => {
    const preference = window.matchMedia('(prefers-reduced-motion: reduce)');
    const finePointer = window.matchMedia('(hover: hover) and (pointer: fine)');
    const items = [...document.querySelectorAll('.reveal, .content-section, .faq-answer, .answer-card, .related-card')];
    let observer, scrollFrame = 0, pointerFrame = 0;
    let pointerTarget;
    function setup() {
      observer?.disconnect();
      if (preference.matches || !('IntersectionObserver' in window)) {
        items.forEach(item => item.classList.add('in', 'motion-in'));
        return;
      }
      observer = new IntersectionObserver(entries => entries.forEach(entry => {
        if (!entry.isIntersecting) return;
        entry.target.classList.add('in', 'motion-in');
        observer.unobserve(entry.target);
      }), { rootMargin: '0px 0px -6% 0px' });
      items.forEach(item => { if (!item.classList.contains('in')) observer.observe(item); });
    }
    function updateScroll() {
      scrollFrame = 0;
      const length = document.documentElement.scrollHeight - window.innerHeight;
      document.documentElement.style.setProperty('--reading-progress', length > 0 ? Math.min(1, window.scrollY / length) : 0);
      document.documentElement.classList.toggle('has-scrolled', window.scrollY > 24);
      const hero = document.querySelector('.hero-experience');
      if (hero) hero.style.setProperty('--hero-travel', preference.matches ? '0px' : `${Math.min(window.scrollY * .08, 60)}px`);
    }
    const onScroll = () => { if (!scrollFrame) scrollFrame = requestAnimationFrame(updateScroll); };
    function onPointer(event) {
      if (preference.matches || !finePointer.matches) return;
      if (!(event.target instanceof Element)) return;
      const target = event.target.closest('.card, .related-card, .plan, [data-spotlight]');
      if (!target) return;
      pointerTarget = target;
      cancelAnimationFrame(pointerFrame);
      pointerFrame = requestAnimationFrame(() => {
        const rect = target.getBoundingClientRect();
        target.style.setProperty('--pointer-x', `${event.clientX - rect.left}px`);
        target.style.setProperty('--pointer-y', `${event.clientY - rect.top}px`);
      });
    }
    setup(); updateScroll();
    preference.addEventListener('change', setup);
    window.addEventListener('scroll', onScroll, { passive: true });
    window.addEventListener('resize', onScroll, { passive: true });
    document.addEventListener('pointermove', onPointer, { passive: true });
    return () => {
      observer?.disconnect(); cancelAnimationFrame(scrollFrame); cancelAnimationFrame(pointerFrame);
      preference.removeEventListener('change', setup);
      window.removeEventListener('scroll', onScroll); window.removeEventListener('resize', onScroll);
      document.removeEventListener('pointermove', onPointer);
      pointerTarget?.style.removeProperty('--pointer-x'); pointerTarget?.style.removeProperty('--pointer-y');
      document.documentElement.style.removeProperty('--reading-progress');
    };
  }, [key]);
}
