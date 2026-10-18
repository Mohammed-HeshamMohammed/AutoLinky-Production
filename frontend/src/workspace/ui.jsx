import React,{useEffect,useState} from 'react';
import { friendlyError } from './api.js';
import { BrandWordmark } from '../BrandMark';
export function Brand(){return <a className="ws-brand" href="/" aria-label="AutoLinky home"><BrandWordmark height={29}/></a>;}
export function Notice({children,tone='info'}){return <div className={`ws-notice ${tone}`} role={tone==='error'?'alert':'status'}>{children}</div>;}
export function Empty({title,children,action}){return <div className="ws-empty"><h3>{title}</h3><p>{children}</p>{action}</div>;}
export function Loading({label='Loading your workspace…'}){return <div className="ws-loading" role="status"><span className="ws-spinner"/>{label}</div>;}
export function ErrorState({error,ar,onRetry}){return <div className="ws-error"><Notice tone="error">{friendlyError(error,ar)}</Notice>{onRetry&&<button className="ws-button secondary" onClick={onRetry}>{ar?'حاول مجددًا':'Try again'}</button>}</div>;}
export function useResource(load,key){
  const [state,setState]=useState({loading:true,data:null,error:null}),[revision,setRevision]=useState(0);
  useEffect(()=>{const controller=new AbortController();setState({loading:true,data:null,error:null});Promise.resolve().then(()=>load(controller.signal)).then(data=>{if(!controller.signal.aborted)setState({loading:false,data,error:null});},error=>{if(!controller.signal.aborted)setState({loading:false,data:null,error});});return()=>controller.abort();},[key,revision]);
  return {...state,reload:()=>setRevision(value=>value+1)};
}
export function dateLabel(value,lang='en'){return value?new Intl.DateTimeFormat(lang==='ar'?'ar-EG':'en',{day:'numeric',month:'short'}).format(new Date(value)):'—';}
export function Field({label,children,hint,...props}){return <label className="ws-field" {...props}><span>{label}</span>{children}{hint&&<small>{hint}</small>}</label>;}
