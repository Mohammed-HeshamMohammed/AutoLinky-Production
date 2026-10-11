import { useEffect, useRef, useState } from 'react';

const COPY = {
  en: {
    demo: 'INTERACTIVE PREVIEW', tabs: ['Match', 'Prepare', 'Send'],
    title: 'Your next opportunity, in focus.', subtitle: 'A preview of your job search with Autolinky',
    role: 'Flutter Developer', location: 'Cairo · Hybrid', score: 'CV match', skills: ['Flutter', 'Dart', 'Firebase'],
    reasons: ['Your skills match the role', 'The experience level fits', 'An email application is available'],
    letter: 'A letter that sounds like you.', letterSub: 'Based on your CV and this job',
    paragraphs: ['Hello, I’m interested in the Flutter Developer role.', 'My experience building Flutter applications and working with Firebase aligns with your team’s requirements.', 'I’ve attached my CV and would welcome a conversation.'],
    review: 'Review and edit before a manual send', file: 'Your CV.pdf',
    sent: 'An application, accounted for.', sentSub: 'Track email delivery status in Applied',
    timeline: ['CV matched to the job', 'Cover letter prepared', 'Sent from your Gmail'],
    note: 'Illustrative preview · results and sending limits vary', flow: ['Your CV', 'AI match', 'Your Gmail'],
    eyebrow: 'A JOB SEARCH THAT MOVES WITH YOU', heading: 'From a good match\nto your next application.',
    intro: 'Three connected steps. Less repetitive work. More control over where your CV goes.',
    steps: [
      ['Find your fit.', 'Your CV becomes a clearer starting point. See a match score, the skills that align, and the original job details before deciding.'],
      ['Make it personal.', 'A cover letter connects your experience with the role. Review and edit it for a manual application, or let Auto Apply use the prepared letter.'],
      ['Keep it moving.', 'Enable Auto Apply for eligible email jobs. Choose your minimum match and daily limit; the server sends one at a time and records what happened.'],
    ],
    cta: 'Explore Auto Apply', methods: 'Email, WhatsApp, and application links. One place to start.',
  },
  ar: {
    demo: 'معاينة تفاعلية', tabs: ['المطابقة', 'التحضير', 'الإرسال'],
    title: 'فرصتك المقبلة، بصورة أوضح.', subtitle: 'معاينة لرحلة البحث عن وظيفة مع Autolinky',
    role: 'مطور Flutter', location: 'القاهرة · هجين', score: 'مطابقة السيرة', skills: ['Flutter', 'Dart', 'Firebase'],
    reasons: ['مهاراتك تناسب الدور', 'مستوى الخبرة مناسب', 'التقديم بالبريد متاح'],
    letter: 'خطاب يعبر عنك.', letterSub: 'يعتمد على سيرتك وهذه الوظيفة',
    paragraphs: ['مرحبًا، أرغب في التقديم لوظيفة مطور Flutter.', 'تتوافق خبرتي في تطوير تطبيقات Flutter والعمل مع Firebase مع متطلبات فريقكم.', 'أرفقت سيرتي الذاتية ويسعدني التواصل معكم.'],
    review: 'راجع الخطاب وعدّله قبل الإرسال اليدوي', file: 'سيرتك الذاتية.pdf',
    sent: 'طلب تقديم يمكنك متابعته.', sentSub: 'تابع حالة إرسال البريد في صفحة تم التقديم',
    timeline: ['مطابقة السيرة مع الوظيفة', 'تجهيز خطاب التقديم', 'الإرسال من Gmail الخاص بك'],
    note: 'معاينة توضيحية · تختلف النتائج وحدود الإرسال', flow: ['سيرتك', 'مطابقة ذكية', 'Gmail الخاص بك'],
    eyebrow: 'بحث عن وظيفة يتحرك معك', heading: 'من فرصة مناسبة\nإلى طلبك المقبل.',
    intro: 'ثلاث خطوات مترابطة. عمل متكرر أقل، وتحكم أكبر في الجهات التي تستقبل سيرتك.',
    steps: [
      ['اعرف ما يناسبك.', 'تصبح سيرتك نقطة بداية أوضح. راجع درجة المطابقة والمهارات المناسبة وتفاصيل الإعلان الأصلي قبل اتخاذ القرار.'],
      ['اجعل التقديم شخصيًا.', 'يربط خطاب التقديم خبرتك بالدور. راجعه وعدّله عند التقديم اليدوي، أو دع التقديم التلقائي يستخدم الخطاب الجاهز.'],
      ['واصل التقديم.', 'فعّل التقديم التلقائي لوظائف البريد المؤهلة. اختر أقل درجة مطابقة والحد اليومي؛ يرسل الخادم طلبًا في كل مرة ويسجل النتيجة.'],
    ],
    cta: 'اكتشف التقديم التلقائي', methods: 'البريد وواتساب وروابط التقديم. نقطة بداية واحدة.',
  },
};

export function ProductIcon({ name, ...props }) {
  const paths = {
    spark: <><path d="m12 3 2.3 6.7L21 12l-6.7 2.3L12 21l-2.3-6.7L3 12l6.7-2.3L12 3Z" /><path d="m20 2 .7 2.3L23 5l-2.3.7L20 8l-.7-2.3L17 5l2.3-.7L20 2Z" /></>,
    check: <path d="m5 12 4.5 4.5L19 7" />,
    file: <><path d="M14 3H6v18h12V7l-4-4Zm0 0v4h4M9 12h6m-6 4h6" /></>,
    mail: <><rect x="3" y="5" width="18" height="14" rx="3" /><path d="m3 7 9 6 9-6" /></>,
    arrow: <path d="M5 12h14m-5-5 5 5-5 5" />,
    link: <><path d="m10 14 4-4m-6 6-2 2a4 4 0 0 1-6-6l4-4a4 4 0 0 1 6 0m4 0 2-2a4 4 0 0 1 6 6l-4 4a4 4 0 0 1-6 0" /></>,
  };
  return <svg viewBox="0 0 24 24" aria-hidden="true" focusable="false" {...props}>{paths[name] || paths.spark}</svg>;
}

export function ProductPreview({ lang = 'en', active: controlled, onChange, id = 'hero-product' }) {
  const [selected, setSelected] = useState(0);
  const active = controlled ?? selected;
  const t = COPY[lang];
  const choose = value => onChange ? onChange(value) : setSelected(value);
  function onKey(event, index) {
    const direction = lang === 'ar' ? -1 : 1;
    let next;
    if (event.key === 'ArrowRight') next = (index + direction + 3) % 3;
    if (event.key === 'ArrowLeft') next = (index - direction + 3) % 3;
    if (event.key === 'Home') next = 0;
    if (event.key === 'End') next = 2;
    if (next === undefined) return;
    event.preventDefault(); choose(next);
    event.currentTarget.parentElement.querySelectorAll('button')[next].focus();
  }
  return <div className="product-frame" data-spotlight>
    <div className="product-chrome"><span className="product-window-dots" aria-hidden="true"><i /><i /><i /></span><span>{t.demo}</span><img src="/assets/logo.svg" width="20" height="20" alt="" /></div>
    <div className="product-tabs" role="tablist" aria-label={lang === 'ar' ? 'مراحل التقديم' : 'Application stages'}>{t.tabs.map((tab, i) => <button type="button" role="tab" key={tab} id={`${id}-tab-${i}`} aria-controls={`${id}-panel`} aria-selected={i === active} tabIndex={i === active ? 0 : -1} onClick={() => choose(i)} onKeyDown={event => onKey(event, i)}><ProductIcon name={['spark', 'file', 'mail'][i]} />{tab}</button>)}</div>
    <div className="product-panel" role="tabpanel" id={`${id}-panel`} aria-labelledby={`${id}-tab-${active}`} tabIndex="0">
      {[0, 1, 2].map(stage => <div className={`product-panel-layer${stage === active ? ' is-active' : ''}`} key={stage} aria-hidden={stage !== active} inert={stage !== active}>
        {stage === 0 && <><div className="product-panel-heading"><p>{t.title}</p><span>{t.subtitle}</span></div><div className="product-job"><span className="product-company">F</span><div><strong>{t.role}</strong><small>{t.location}</small></div><span className="product-email-tag"><ProductIcon name="mail" />{lang === 'ar' ? 'بريد' : 'Email'}</span></div><div className="product-match"><div className="product-gauge"><svg viewBox="0 0 120 120" aria-hidden="true"><circle cx="60" cy="60" r="50" className="gauge-track" /><circle cx="60" cy="60" r="50" className="gauge-value" /></svg><strong>92<span>%</span></strong></div><div><small>{t.score}</small><div className="product-skill-tags">{t.skills.map(skill => <span key={skill}>{skill}</span>)}</div><p>{lang === 'ar' ? 'خبرة تتوافق مع المطلوب.' : 'Experience that lines up.'}</p></div></div><ul className="product-reasons">{t.reasons.map((reason, i) => <li key={reason} style={{ '--item': i }}><ProductIcon name="check" />{reason}</li>)}</ul></>}
        {stage === 1 && <><div className="product-panel-heading"><p>{t.letter}</p><span>{t.letterSub}</span></div><div className="product-letter"><div><ProductIcon name="mail" /><span>{lang === 'ar' ? 'إلى: فريق التوظيف' : 'To: hiring team'}</span><i /></div>{t.paragraphs.map((text, i) => <p key={text} style={{ '--item': i }}>{text}</p>)}<span className="product-attachment"><ProductIcon name="file" />{t.file}<ProductIcon name="check" /></span></div><p className="product-review"><ProductIcon name="check" />{t.review}</p></>}
        {stage === 2 && <><div className="product-panel-heading"><p>{t.sent}</p><span>{t.sentSub}</span></div><div className="product-delivered"><span><ProductIcon name="check" /></span><strong>{lang === 'ar' ? 'تم الإرسال' : 'Sent from your Gmail'}</strong><small>{lang === 'ar' ? 'مثال على طلب بريد مكتمل' : 'A sample completed email application'}</small></div><ol className="product-send-log">{t.timeline.map((text, i) => <li key={text} style={{ '--item': i }}><span>0{i + 1}</span>{text}<ProductIcon name="check" /></li>)}</ol></>}
      </div>)}
    </div>
    <div className="product-frame-foot"><span className="product-status-dot" />{t.note}</div>
  </div>;
}

export function HeroExperience({ lang }) {
  const t = COPY[lang];
  return <div className="hero-experience reveal"><div className="hero-orbit" aria-hidden="true"><i /><i /><i /></div><ProductPreview lang={lang} /><div className="hero-flow" aria-label={lang === 'ar' ? 'رحلة التقديم' : 'Application flow'}>{t.flow.map((item, i) => <span key={item}><ProductIcon name={['file', 'spark', 'mail'][i]} />{item}{i < 2 && <ProductIcon name="arrow" />}</span>)}</div></div>;
}

export function WorkflowStory({ lang }) {
  const t = COPY[lang];
  const [active, setActive] = useState(0);
  const root = useRef(null);
  const activeStage = useRef(0);
  const manualScrollPosition = useRef(null);
  function chooseStage(value) {
    activeStage.current = value;
    manualScrollPosition.current = window.scrollY;
    setActive(value);
  }
  useEffect(() => {
    const section = root.current;
    const desktop = window.matchMedia('(min-width: 940px)');
    if (!section || !('IntersectionObserver' in window)) return;
    let frame = 0, visible = false;
    const update = () => {
      frame = 0;
      if (!visible || !desktop.matches) return;
      const anchors = [...section.querySelectorAll('.journey-step > div')].map(step => step.getBoundingClientRect().top);
      const target = window.innerHeight * .48;
      const progress = Math.min(1, Math.max(0, (target - anchors[0]) / (anchors[2] - anchors[0])));
      section.style.setProperty('--journey-progress', progress);
      // Keep a manual selection until the user deliberately continues scrolling.
      if (manualScrollPosition.current !== null) {
        if (Math.abs(window.scrollY - manualScrollPosition.current) < 60) return;
        manualScrollPosition.current = null;
      }
      let next = 0;
      anchors.forEach((top, index) => { if (top <= target) next = index; });
      const current = activeStage.current;
      // A small dead zone prevents flicker when scrolling around a stage boundary.
      if (next > current && anchors[next] > target - 24) return;
      if (next < current && anchors[current] < target + 24) return;
      if (next !== current) { activeStage.current = next; setActive(next); }
    };
    const schedule = () => { if (visible && desktop.matches && !frame) frame = requestAnimationFrame(update); };
    const observer = new IntersectionObserver(([entry]) => { visible = entry.isIntersecting; if (visible) schedule(); });
    observer.observe(section);
    window.addEventListener('scroll', schedule, { passive: true });
    window.addEventListener('resize', schedule, { passive: true });
    return () => { observer.disconnect(); cancelAnimationFrame(frame); window.removeEventListener('scroll', schedule); window.removeEventListener('resize', schedule); };
  }, []);
  return <section className="journey section" id="auto-apply" ref={root}>
    <div className="container"><header className="journey-heading reveal"><p className="eyebrow">{t.eyebrow}</p><h2>{t.heading.split('\n').map((line, i) => <span key={line}>{line}{i === 0 ? ' ' : ''}</span>)}</h2><p>{t.intro}</p></header><div className="journey-layout"><div className="journey-board"><ProductPreview lang={lang} active={active} onChange={chooseStage} id="journey-product" /><div className="journey-board-meta"><span>0{active + 1} / 03</span><span>{t.methods}</span></div></div><div className="journey-steps">{t.steps.map(([heading, body], i) => <article className={`journey-step${active === i ? ' is-active' : ''}`} key={heading}><span className="journey-number">0{i + 1}</span><div><span className="journey-step-label">{t.tabs[i]}</span><h3>{heading}</h3><p>{body}</p>{i === 2 && <a className="link-arrow" href={`${lang === 'ar' ? '/ar' : ''}/auto-apply/`}>{t.cta}<ProductIcon name="arrow" /></a>}</div></article>)}</div></div></div>
  </section>;
}
