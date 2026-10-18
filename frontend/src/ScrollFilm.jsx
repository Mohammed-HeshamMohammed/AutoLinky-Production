import {useEffect,useRef,useState} from 'react';
import {FILM_CHAPTERS,FILM_DURATION,clampProgress,filmChapter} from './brandFilm';
import {accountHref} from './SiteHeader';
import './scroll-film.css';

export default function ScrollFilm({lang='en'}){
  const ar=lang==='ar',t=(en,arabic)=>ar?arabic:en,chapters=FILM_CHAPTERS[lang];
  const section=useRef(null),video=useRef(null),controller=useRef(null),currentProgress=useRef(0);
  const [progress,setProgress]=useState(0),[playing,setPlaying]=useState(false),[reduced,setReduced]=useState(false),[failed,setFailed]=useState(false),[preload,setPreload]=useState('metadata');
  const active=filmChapter(progress),chapter=chapters[active];

  useEffect(()=>{
    const preference=matchMedia('(prefers-reduced-motion: reduce), (max-height: 500px)');
    const connection=navigator.connection;
    const update=()=>{setReduced(preference.matches);setPreload(preference.matches||connection?.saveData||['slow-2g','2g','3g'].includes(connection?.effectiveType)?'metadata':'auto');};
    update();preference.addEventListener('change',update);connection?.addEventListener('change',update);
    return()=>{preference.removeEventListener('change',update);connection?.removeEventListener('change',update);};
  },[]);

  useEffect(()=>{
    const el=section.current,media=video.current;
    setPlaying(false);
    let frame=0,scrubFrame=0,scrubTime=0,wanted=currentProgress.current*FILM_DURATION,playhead=wanted,watching=false,lastScroll=scrollY,disposed=false;
    const header=()=>document.querySelector('.site-header')?.getBoundingClientRect().height||0;
    const duration=()=>Number.isFinite(media.duration)?media.duration:FILM_DURATION;
    const seek=()=>{
      if(!watching&&media.readyState>=1&&!media.seeking&&Math.abs(media.currentTime-playhead)>1/120){
        try{media.currentTime=playhead;}catch{ /* The poster remains available until the browser can seek. */ }
      }
    };
    const scrub=timestamp=>{
      scrubFrame=0;if(disposed||watching||media.readyState<1)return;
      const elapsed=scrubTime?Math.min(50,timestamp-scrubTime):1000/60;scrubTime=timestamp;
      playhead+=(wanted-playhead)*(1-Math.exp(-elapsed/70));
      if(Math.abs(wanted-playhead)<1/120)playhead=wanted;
      seek();
      if(playhead!==wanted)scrubFrame=requestAnimationFrame(scrub);
    };
    const scheduleScrub=()=>{if(!disposed&&!watching&&!scrubFrame){scrubTime=0;scrubFrame=requestAnimationFrame(scrub);}};
    const show=(p,snap=false)=>{
      p=clampProgress(p);currentProgress.current=p;wanted=p*Math.max(0,duration()-.05);setProgress(p);
      if(snap){playhead=wanted;seek();}scheduleScrub();
    };
    const measure=()=>{
      frame=0;if(disposed)return;
      const top=header();el.style.setProperty('--film-header',`${top}px`);
      if(watching){if(Math.abs(scrollY-lastScroll)>12){media.pause();watching=false;}else return;}
      if(!reduced&&!failed){const travel=el.offsetHeight-el.querySelector('.film-stage').offsetHeight;show((top-el.getBoundingClientRect().top)/Math.max(1,travel));}
      else scheduleScrub();
      lastScroll=scrollY;
    };
    const schedule=()=>{if(!frame)frame=requestAnimationFrame(measure);};
    const stop=()=>{if(watching)wanted=playhead=media.currentTime;watching=false;setPlaying(false);};
    const start=()=>{watching=true;cancelAnimationFrame(scrubFrame);scrubFrame=0;lastScroll=scrollY;setPlaying(true);};
    const time=()=>{if(watching){currentProgress.current=clampProgress(media.currentTime/duration());setProgress(currentProgress.current);}};
    const ready=()=>{schedule();scheduleScrub();};
    const unavailable=()=>setFailed(true);
    controller.current={go(p){
      media.pause();watching=false;show(p,true);
      if(!reduced&&!failed){const travel=el.offsetHeight-el.querySelector('.film-stage').offsetHeight;window.scrollTo({top:el.getBoundingClientRect().top+scrollY-header()+travel*clampProgress(p),behavior:'instant'});}
      lastScroll=scrollY;
    }};
    addEventListener('scroll',schedule,{passive:true});addEventListener('resize',schedule);
    media.addEventListener('loadedmetadata',ready);media.addEventListener('seeked',scheduleScrub);
    media.addEventListener('error',unavailable);if(media.error)unavailable();
    media.addEventListener('play',start);media.addEventListener('pause',stop);media.addEventListener('ended',stop);media.addEventListener('timeupdate',time);
    const observer=new ResizeObserver(schedule);observer.observe(el);schedule();
    return()=>{
      disposed=true;cancelAnimationFrame(frame);cancelAnimationFrame(scrubFrame);observer.disconnect();controller.current=null;
      removeEventListener('scroll',schedule);removeEventListener('resize',schedule);
      media.removeEventListener('loadedmetadata',ready);media.removeEventListener('seeked',scheduleScrub);
      media.removeEventListener('error',unavailable);
      media.removeEventListener('play',start);media.removeEventListener('pause',stop);media.removeEventListener('ended',stop);media.removeEventListener('timeupdate',time);media.pause();
    };
  },[reduced,failed]);

  function togglePlayback(){
    const media=video.current;
    if(playing){media.pause();return;}
    if(media.ended||progress>=.995)media.currentTime=0;
    media.play().catch(()=>{setPlaying(false);if(media.error)setFailed(true);});
  }
  function skip(){video.current.pause();document.getElementById('after-film')?.focus({preventScroll:true});}
  const seconds=Math.min(FILM_DURATION,Math.floor(progress*FILM_DURATION));
  return <><noscript><style>{'.scroll-film{height:auto}.film-stage{position:relative;top:0;height:auto;min-height:650px}.film-transport,.film-progress,.film-chapters{display:none}'}</style></noscript><section id="how" ref={section} className={`scroll-film${reduced?' film-reduced':''}${failed?' film-error':''}`} aria-label={t('The AutoLinky story','قصة AutoLinky')}>
    <div className="film-stage">
      <div className="film-topline"><p>{t('THE SEARCH, RECONSIDERED','نظرة جديدة للبحث عن وظيفة')}<span> / AUTOLINKY</span></p><a href="#after-film" onClick={skip}>{t('Skip the film','تخطى الفيلم')}</a></div>
      <div className="film-composition">
        <div className="film-copy">
          <h1 className="film-sr-only">{t('AutoLinky. Your next job, with less busywork.','AutoLinky. وظيفتك القادمة، بتفاصيل متكررة أقل.')}</h1>
          <p className="film-scene-label"><span>0{active+1}</span> / {chapter.label}</p>
          <div className="film-words"><h2>{chapter.title.split('\n').map((line,i)=><span key={line} className={i?'film-heading-secondary':undefined}>{line}</span>)}</h2><p className="film-description">{chapter.body}</p></div>
          <div className="film-actions"><a className="film-primary" href={accountHref('signup',lang)}>{t('Start your next move','ابدأ خطوتك القادمة')}<span aria-hidden="true">↗</span></a><span className="film-platforms">{t('Free to start · Web & Android','ابدأ مجانًا · الويب وأندرويد')}</span></div>
        </div>
        <figure className="film-picture"><video ref={video} src="/assets/film/autolinky-story.mp4?v=complete-card-1" poster="/assets/film/autolinky-story-poster.webp?v=complete-card-1" width="1080" height="1080" muted playsInline preload={preload} aria-hidden="true" tabIndex={-1} disablePictureInPicture onError={()=>setFailed(true)}/><figcaption>{active>=2?t('Actual app screens · sample data','شاشات التطبيق · بيانات توضيحية'):t('Sample documents · motion study','مستندات توضيحية · فيلم قصير')}</figcaption></figure>
      </div>
      <div className="film-bottom">
        <div className="film-transport"><span className="film-instruction">{failed?t('Read the story below','اقرأ القصة بالأسفل'):reduced?t('Explore at your own pace','استكشف بالوتيرة المناسبة لك'):playing?t('Scroll to take control','مرّر للتحكم بالفيلم'):t('Scroll to move the story','مرّر لتتابع القصة')}</span><span className="film-time" dir="ltr">00:{String(seconds).padStart(2,'0')} <span>/ 00:24</span></span>{!failed&&<button type="button" onClick={togglePlayback} aria-pressed={playing}>{playing?t('Pause film','أوقف الفيلم'):t('Play film','شغّل الفيلم')}</button>}</div>
        <label className="film-sr-only" htmlFor="film-progress">{t('Film progress','تقدم الفيلم')}</label><input id="film-progress" className="film-progress" type="range" min="0" max="1000" step="1" value={Math.round(progress*1000)} aria-valuetext={`${chapter.label}, ${seconds} / ${FILM_DURATION} ${t('seconds','ثانية')}`} onChange={event=>controller.current?.go(Number(event.target.value)/1000)} style={{'--film-progress':`${progress*100}%`}}/>
        <nav className="film-chapters" aria-label={t('Film chapters','فصول الفيلم')}>{chapters.map((item,index)=><button type="button" key={item.label} aria-current={active===index?'step':undefined} onClick={()=>controller.current?.go(index===0?0:index/6+.03)}><span>0{index+1}</span>{item.label}</button>)}</nav>
      </div>
    </div>
  </section><details className="film-transcript" open={failed||reduced||undefined}><summary>{t('Read the story','اقرأ القصة')}</summary><ol>{chapters.map(item=><li key={item.label}><h2>{item.title.replace('\n',' ')}</h2><p>{item.body}</p><p>{item.detail}</p></li>)}</ol></details></>;
}
