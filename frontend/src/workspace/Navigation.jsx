import React,{useEffect,useRef} from 'react';
import {Brand} from './ui.jsx';

export function Sidebar({open,onClose,ar,children,footer,label}){
  const panel=useRef(null);
  useEffect(()=>{
    const desktop=matchMedia('(min-width: 901px)');
    function resize(){if(desktop.matches)onClose();}
    desktop.addEventListener('change',resize);
    return()=>desktop.removeEventListener('change',resize);
  },[onClose]);
  useEffect(()=>{
    if(!open)return;
    const previous=document.activeElement,overflow=document.body.style.overflow;
    document.body.style.overflow='hidden';
    panel.current?.querySelector('button,a[href]')?.focus();
    function keys(event){
      if(event.key==='Escape'){event.preventDefault();onClose();}
      if(event.key==='Tab'){
        const items=[...panel.current.querySelectorAll('a[href],button:not([disabled]),input')],first=items[0],last=items.at(-1);
        if(event.shiftKey&&document.activeElement===first){event.preventDefault();last?.focus();}
        else if(!event.shiftKey&&document.activeElement===last){event.preventDefault();first?.focus();}
      }
    }
    document.addEventListener('keydown',keys);
    return()=>{document.body.style.overflow=overflow;document.removeEventListener('keydown',keys);previous?.focus();};
  },[open,onClose]);
  return <>
    {open&&<button className="ws-sidebar-scrim" tabIndex={-1} aria-label={ar?'إغلاق القائمة':'Close navigation'} onClick={onClose}/>}
    <aside id="workspace-navigation" className={`ws-sidebar ${open?'open':''}`} ref={panel} role={open?'dialog':undefined} aria-modal={open||undefined} aria-label={label}>
      <div className="ws-sidebar-brand"><Brand animate={false}/><button className="ws-text-button ws-menu-close" onClick={onClose}>{ar?'إغلاق':'Close'}</button></div>
      <span className="ws-workspace-name">{label}</span>
      <nav aria-label={label}>{children}</nav>
      <div className="ws-sidebar-bottom">{footer}</div>
    </aside>
  </>;
}

export function NavGroup({label,children}){return <div className="ws-nav-group"><span className="ws-space-label">{label}</span>{children}</div>;}

export function AppearanceButton({dark,onClick,ar}){
  useEffect(()=>{
    const theme=document.querySelector('meta[name="theme-color"]');
    const scheme=document.querySelector('meta[name="color-scheme"]');
    theme?.setAttribute('content','#171c19');
    scheme?.setAttribute('content',dark?'dark':'light');
    document.documentElement.style.colorScheme=dark?'dark':'light';
    return()=>{
      theme?.setAttribute('content','#f7f6f0');
      scheme?.setAttribute('content','light');
      document.documentElement.style.removeProperty('color-scheme');
    };
  },[dark]);
  return <button className="ws-appearance" aria-pressed={dark} aria-label={ar?'تبديل المظهر':'Toggle color theme'} onClick={onClick}>{dark?(ar?'مظهر فاتح':'Light mode'):(ar?'مظهر داكن':'Dark mode')}</button>;
}
