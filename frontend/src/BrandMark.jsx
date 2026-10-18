import {useEffect,useId,useRef,useState} from 'react';
import {brandFormation} from './brandFormation';
import './brandFormation.css';

export default function BrandMark({size=30}){
  return <span className="brand-mark" aria-hidden="true" style={{display:'inline-flex',width:size,height:size,flex:'none'}}><img className="brand-mark-light" src="/assets/logo-light.svg" width={size} height={size} alt=""/><img className="brand-mark-dark" src="/assets/logo-dark.svg" width={size} height={size} alt=""/></span>;
}

const timing=({delay,duration,easing})=>({'--form-delay':`${delay}s`,'--form-duration':`${duration}s`,...(easing?{'--form-easing':easing}:{})});

function Formation({prefix}){
  return <svg className="brand-formation" viewBox={brandFormation.viewBox} aria-hidden="true" focusable="false" style={{'--form-settle':`${brandFormation.settle}s`}}>
    {brandFormation.groups.map(group=>{
      const clipId=`${prefix}-${group.id}`;
      return <g key={group.id} data-letter={group.letter} clipPath={group.reveal?`url(#${clipId})`:undefined}>
        {group.reveal&&<defs><clipPath id={clipId} clipPathUnits="userSpaceOnUse"><rect className="brand-form-wipe" x={group.reveal.x} y={group.reveal.y} width={group.reveal.width} height={group.reveal.height} style={timing(group.reveal)}/></clipPath></defs>}
          {group.paths.map((path,index)=>{
            const maskId=`${clipId}-${index}`;
            return <g key={index}><g data-part={path.part} className={path.bounce?'brand-form-dot':undefined} style={path.bounce?timing(path.bounce):undefined}><g transform={group.transform}>
              {path.draw&&<defs><mask id={maskId} maskUnits="userSpaceOnUse" maskContentUnits="userSpaceOnUse" {...group.bounds} style={{maskType:'luminance'}}>
                {(path.draw.parts||[path.draw]).map((part,partIndex)=>{
                  const partId=`${maskId}-part-${partIndex}`;
                  return <g key={partIndex} clipPath={part.clip?`url(#${partId})`:undefined}>
                    {part.clip&&<defs><clipPath id={partId} clipPathUnits="userSpaceOnUse"><path d={part.clip}/></clipPath></defs>}
                    <path className="brand-form-trace" d={part.d} fill="none" stroke="white" strokeWidth={part.strokeWidth} strokeLinecap="round" strokeLinejoin="round" pathLength="1" style={timing(part)}/>
                  </g>;
                })}
                <rect className="brand-form-settle" {...group.bounds} fill="white"/>
              </mask></defs>}
              <path d={path.d} fill={`var(--brand-${path.role})`} mask={path.draw?`url(#${maskId})`:undefined}/>
            </g></g>{path.bounce&&<g className="brand-form-dot-rest" data-part="dot-rest"><g transform={group.transform}><path d={path.d} fill={`var(--brand-${path.role})`}/></g></g>}</g>;
          })}
      </g>;
    })}
  </svg>;
}

export function BrandWordmark({height=30,animate=true,onComplete}){
  const element=useRef(null),played=useRef(false),[phase,setPhase]=useState('static');
  const completion=useRef(onComplete),notified=useRef(false);
  const prefix=`brand-${useId().replace(/[^a-zA-Z0-9_-]/g,'')}`;
  useEffect(()=>{completion.current=onComplete;},[onComplete]);
  useEffect(()=>{
    const finish=()=>{if(!notified.current){notified.current=true;completion.current?.();}};
    if(!animate){setPhase('static');finish();return;}
    const preference=matchMedia('(prefers-reduced-motion: reduce)');
    let timer,observer;
    const start=()=>{
      if(played.current||preference.matches)return;
      played.current=true;observer?.disconnect();setPhase('forming');
      timer=setTimeout(()=>{setPhase('formed');finish();},brandFormation.duration*1000);
    };
    const update=()=>{if(preference.matches){played.current=true;clearTimeout(timer);observer?.disconnect();setPhase('static');finish();}};
    if(preference.matches){played.current=true;finish();}
    else if('IntersectionObserver' in window){
      observer=new IntersectionObserver(entries=>{if(entries.some(entry=>entry.isIntersecting&&entry.intersectionRatio>.1))start();},{threshold:.1});
      observer.observe(element.current);
    }else start();
    preference.addEventListener('change',update);
    return()=>{clearTimeout(timer);observer?.disconnect();preference.removeEventListener('change',update);};
  },[animate]);
  return <span ref={element} className={`brand-wordmark is-${phase}`} role="img" aria-label="AutoLinky" style={{'--brand-wordmark-size':`${height}px`,'--brand-aspect':brandFormation.width/brandFormation.height}}>
    <img className="brand-wordmark-light" src="/assets/logo-full-light.svg" alt=""/>
    <img className="brand-wordmark-dark" src="/assets/logo-full-dark.svg" alt=""/>
    <Formation prefix={prefix}/>
  </span>;
}
