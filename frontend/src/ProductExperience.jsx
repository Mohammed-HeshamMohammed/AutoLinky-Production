import {useEffect,useRef,useState} from 'react';
import IPhoneMockup from './IPhoneMockup';

const SCREENS=['for-you','profile','auto-apply'];
const COPY={
  en:{
    tabs:['Match','Prepare','Send'],
    headings:['See why a role fits.','Put your experience first.','Apply on your terms.'],
    descriptions:['Match scores and job details in the app.','Your CV and preferences shape your search.','Choose the match threshold, daily limit and pace.'],
    alts:['AutoLinky matched jobs screen','AutoLinky profile and CV screen','AutoLinky Auto Apply settings screen'],
    note:'App screens · sample data shown',
    eyebrow:'A little less busywork',heading:'From your experience.\nTo your next opportunity.',
    intro:'One connected search, from the first match to the application you choose to send.',
    steps:[
      ['Find a fit worth your time.','Your CV and preferences help sort opportunities around your skills, experience and location. See why a role fits before you decide.'],
      ['Make the application yours.','Keep your profile and CV up to date. Email applications include a letter prepared for the role, which you can review and edit before a manual send.'],
      ['Keep moving, at your pace.','Apply through the route the job provides. For eligible email jobs, Auto Apply works from your Gmail within the preferences you set.'],
    ],
    cta:'More about Auto Apply',methods:'Your CV. Your preferences. Your decision.',
  },
  ar:{
    tabs:['المطابقة','التحضير','الإرسال'],
    headings:['اعرف لماذا تناسبك الوظيفة.','خبراتك هي نقطة البداية.','قدّم وفق اختياراتك.'],
    descriptions:['درجات المطابقة وتفاصيل الوظائف داخل التطبيق.','سيرتك وتفضيلاتك تحددان مسار بحثك.','حدد نسبة المطابقة والحد اليومي ووتيرة الإرسال.'],
    alts:['شاشة الوظائف المطابقة في AutoLinky','شاشة الملف الشخصي والسيرة الذاتية في AutoLinky','شاشة إعدادات التقديم التلقائي في AutoLinky'],
    note:'شاشات التطبيق · بيانات توضيحية',
    eyebrow:'جهد أقل في التفاصيل المتكررة',heading:'من خبراتك.\nإلى فرصتك القادمة.',
    intro:'رحلة بحث مترابطة، من أول مطابقة إلى الطلب الذي تختار إرساله.',
    steps:[
      ['فرص تستحق وقتك.','تساعد سيرتك وتفضيلاتك على ترتيب الفرص حسب مهاراتك وخبراتك وموقعك. اعرف سبب ملاءمة الوظيفة قبل أن تقرر.'],
      ['طلب يعبر عنك.','حافظ على تحديث ملفك وسيرتك. يتضمن التقديم بالبريد خطابًا مخصصًا للوظيفة، يمكنك مراجعته وتعديله قبل الإرسال اليدوي.'],
      ['تقدّم بالوتيرة المناسبة لك.','استخدم طريقة التقديم المتاحة في الإعلان. للوظائف المؤهلة، يعمل التقديم التلقائي من Gmail وفق تفضيلاتك.'],
    ],
    cta:'المزيد عن التقديم التلقائي',methods:'سيرتك. تفضيلاتك. قرارك.',
  },
};

export function ProductPreview({lang='en',active:controlled,onChange,id='hero-product'}){
  const [selected,setSelected]=useState(0),active=controlled??selected,t=COPY[lang];
  const choose=value=>onChange?onChange(value):setSelected(value);
  function onKey(event,index){
    const direction=lang==='ar'?-1:1;
    let next;
    if(event.key==='ArrowRight')next=(index+direction+3)%3;
    if(event.key==='ArrowLeft')next=(index-direction+3)%3;
    if(event.key==='Home')next=0;
    if(event.key==='End')next=2;
    if(next===undefined)return;
    event.preventDefault();choose(next);
    event.currentTarget.parentElement.querySelectorAll('button')[next].focus();
  }
  return <div className="product-frame real-product-preview">
    <div className="product-tabs" role="tablist" aria-label={lang==='ar'?'مراحل التقديم':'Application stages'}>{t.tabs.map((label,index)=><button type="button" role="tab" key={label} id={`${id}-tab-${index}`} aria-controls={`${id}-panel`} aria-selected={active===index} tabIndex={active===index?0:-1} onClick={()=>choose(index)} onKeyDown={event=>onKey(event,index)}><span aria-hidden="true">0{index+1}</span>{label}</button>)}</div>
    <div className="product-panel" role="tabpanel" id={`${id}-panel`} aria-labelledby={`${id}-tab-${active}`} tabIndex={0}>
      {SCREENS.map((screen,index)=><figure key={screen} className={`product-panel-layer${active===index?' is-active':''}`} aria-hidden={active!==index} inert={active!==index}><div className="product-screen-stage"><IPhoneMockup src={`/assets/app/iphone/${screen}.webp`} alt={t.alts[index]}/></div><figcaption><strong>{t.headings[index]}</strong><span>{t.descriptions[index]}</span></figcaption></figure>)}
    </div><p className="product-frame-foot">{t.note}</p>
  </div>;
}

export function HeroExperience({lang='en'}){
  const ar=lang==='ar';
  return <figure className="landing-product-art">
    <div className="landing-product-label"><span>{ar?'نظرة من الداخل':'A look inside'}</span><span>AutoLinky / 01</span></div>
    <div className="landing-product-phones"><div className="landing-phone primary"><IPhoneMockup src="/assets/app/iphone/for-you.webp" loading="eager" fetchPriority="high" alt={ar?'شاشة الوظائف المطابقة في AutoLinky':'AutoLinky matched jobs screen'}/></div><div className="landing-phone secondary"><IPhoneMockup src="/assets/app/iphone/auto-apply.webp" alt={ar?'إعدادات التقديم التلقائي في AutoLinky':'AutoLinky Auto Apply settings screen'}/></div></div>
    <figcaption>{ar?'شاشات التطبيق · بيانات توضيحية':'App screens · sample data shown'}</figcaption>
  </figure>;
}

export function WorkflowStory({lang='en'}){
  const t=COPY[lang];
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
    if (!section) return;
    let frame = 0;
    const update = () => {
      frame = 0;
      if (!desktop.matches) return;
      // Read visibility with the current scroll position. An asynchronous observer
      // must not decide whether a scroll update is allowed to run.
      const bounds = section.getBoundingClientRect();
      if (bounds.bottom < 0 || bounds.top > window.innerHeight) return;
      const anchors = [...section.querySelectorAll('.journey-step > div')].map(step => step.getBoundingClientRect().top);
      const target = window.innerHeight * .45;
      const progress = Math.min(1, Math.max(0, (target - anchors[0]) / (anchors[2] - anchors[0])));
      section.style.setProperty('--journey-progress', progress);
      // Keep a manual selection until the user deliberately continues scrolling.
      if (manualScrollPosition.current !== null) {
        if (Math.abs(window.scrollY - manualScrollPosition.current) < 60) return;
        manualScrollPosition.current = null;
      }
      // Follow the nearest narrative step, including one approaching the center.
      // Waiting for its top to cross the center leaves the previous preview on
      // screen while the next heading is already the main visible content.
      const distances = anchors.map(top => Math.abs(top - target));
      const next = distances.indexOf(Math.min(...distances));
      const current = activeStage.current;
      // Require a clear lead to avoid flicker when two steps are equally close.
      if (next !== current && distances[current] - distances[next] < 24) return;
      if (next !== current) { activeStage.current = next; setActive(next); }
    };
    const schedule = () => { if (!frame) frame = requestAnimationFrame(update); };
    schedule();
    window.addEventListener('scroll', schedule, { passive: true });
    window.addEventListener('resize', schedule, { passive: true });
    window.addEventListener('pageshow', schedule);
    desktop.addEventListener('change', schedule);
    return () => { cancelAnimationFrame(frame); window.removeEventListener('scroll', schedule); window.removeEventListener('resize', schedule); window.removeEventListener('pageshow', schedule); desktop.removeEventListener('change', schedule); };
  }, []);
  return <section className="journey section" id="how" ref={root}>
    <div className="container"><header className="journey-heading"><p className="eyebrow">{t.eyebrow}</p><h2>{t.heading.split('\n').map(line=><span key={line}>{line}</span>)}</h2><p>{t.intro}</p></header><div className="journey-layout" id="auto-apply"><div className="journey-board"><ProductPreview lang={lang} active={active} onChange={chooseStage} id="journey-product"/><div className="journey-board-meta"><span>0{active+1} / 03</span><span>{t.methods}</span></div></div><div className="journey-steps">{t.steps.map(([heading,body],index)=><article className={`journey-step${active===index?' is-active':''}`} key={heading}><span className="journey-number">0{index+1}</span><div><span className="journey-step-label">{t.tabs[index]}</span><h3>{heading}</h3><p>{body}</p>{index===2&&<a className="link-arrow" href={`${lang==='ar'?'/ar':''}/auto-apply/`}>{t.cta}</a>}</div></article>)}</div></div></div>
  </section>;
}
