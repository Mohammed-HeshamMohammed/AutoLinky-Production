import React,{useEffect,useRef,useState} from 'react';
import {Loading,ErrorState,useResource} from './ui.jsx';
import './admin-editorial.css';
export const adminWhen=(value,ar=false)=>value?new Intl.DateTimeFormat(ar?'ar-EG':'en-GB',{dateStyle:'medium',timeStyle:'short',timeZone:'Africa/Cairo'}).format(new Date(value)):'—';
export function Facts({rows}){return <dl className="ac-facts">{rows.map(([label,value])=><React.Fragment key={label}><dt>{label}</dt><dd>{value??'—'}</dd></React.Fragment>)}</dl>;}
export function MiniChart({points,measure='emails',label,ar=false}){
  const max=Math.max(1,...points.map(row=>Number(row[measure]||0))),step=Math.max(1,Math.ceil(max/4)),ceiling=step*4;
  const [selected,setSelected]=useState(null),[ticks,setTicks]=useState(4),chart=useRef(null);
  useEffect(()=>{
    const observer=new ResizeObserver(([entry])=>setTicks(Math.max(3,Math.min(8,Math.floor(entry.contentRect.width/85)))));
    observer.observe(chart.current);
    return()=>observer.disconnect();
  },[]);
  return <div className="ac-chart" ref={chart}><div className="ac-chart-plot"><div className="ac-y-axis">{[4,3,2,1,0].map(n=><span key={n}>{(step*n).toLocaleString(ar?'ar':'en')}</span>)}</div><div className="ac-chart-bars" role="group" aria-label={label}>{points.map((row,index)=><button type="button" key={row.day} title={`${row.day}: ${row[measure]||0}`} aria-label={`${row.day}: ${row[measure]||0} ${label}`} tabIndex={selected===null?(index===0?0:-1):(selected===index?0:-1)} onKeyDown={event=>{if(!['ArrowLeft','ArrowRight'].includes(event.key))return;event.preventDefault();const next=Math.max(0,Math.min(points.length-1,index+(event.key==='ArrowRight'?1:-1)*(ar?-1:1)));setSelected(next);event.currentTarget.parentElement.children[next].focus();}} onFocus={()=>setSelected(index)} onMouseEnter={()=>setSelected(index)} onMouseLeave={()=>setSelected(null)} onClick={()=>setSelected(index)}><span className={selected===index?'on':''} style={{height:`${Number(row[measure]||0)/ceiling*100}%`}}/>{index%Math.ceil(points.length/ticks)===0&&<small>{new Date(row.day+'T12:00:00Z').toLocaleDateString(ar?'ar-EG':'en-GB',{day:'numeric',month:'short',timeZone:'UTC'})}</small>}</button>)}</div></div><p className="ac-chart-readout" aria-live="polite">{selected===null?(ar?'اختر يومًا لعرض العدد. الأيام بلا نشاط مسجلة بصفر.':'Choose a day to inspect its count. Days with no activity are included as zero.'):`${points[selected].day} · ${points[selected][measure]||0} ${label}`}</p></div>;
}
export function AdminNumbers({client,t,ar}){
  const [days,setDays]=useState(30),[measure,setMeasure]=useState('downloads'),[table,setTable]=useState(false);
  const resource=useResource(signal=>client('/admin/api/overview?days='+days,{signal}),days);
  if(resource.loading)return <Loading/>;if(resource.error)return <ErrorState error={resource.error} ar={ar} onRetry={resource.reload}/>;
  const o=resource.data,measureLabels={downloads:t('Downloads','التنزيلات'),signups:t('New users','مستخدمون جدد'),emails:t('Emails sent','رسائل مرسلة')},userLink=(filter,value,sort='new')=><a href={`${ar?'/ar':''}/admin/users/?filter=${filter}&sort=${sort}`}>{value}</a>;
  const metrics=[
    [t('Downloads','التنزيلات'),o.downloads.total,[[t('Today','اليوم'),o.downloads.today],[t('Last 7 days','آخر ٧ أيام'),o.downloads.last_7d]]],
    [t('Users','المستخدمون'),o.users.total,[[t('New today','الجدد اليوم'),o.users.today],[t('New in 7 days','الجدد خلال ٧ أيام'),o.users.last_7d]]],
    [t('Active in 7 days','النشطون خلال ٧ أيام'),o.users.active_7d,[[t('Last 24 hours','آخر ٢٤ ساعة'),o.users.active_24h],[t('Last 30 days','آخر ٣٠ يومًا'),o.users.active_30d]]],
    [t('Emails sent','رسائل مرسلة'),o.emails.total,[[t('Today','اليوم'),o.emails.today],[t('Last 7 days','آخر ٧ أيام'),o.emails.last_7d]]],
  ];
  const watch=[
    [t('Failed emails · 30 days','رسائل فاشلة · ٣٠ يومًا'),o.emails.failed_30d,'sender'],
    [t('Gmail connections refused','اتصالات Gmail مرفوضة'),o.auto_apply.gmail_invalid,'users/?filter=auto'],
    [t('Pro ending · next 7 days','Pro ينتهي · ٧ أيام'),o.plans.pro_ending_7d,'users/?filter=pro'],
  ];
  return <div className="ac-editorial-overview">
    <div className="ac-heading ac-editorial-heading">
      <div><span className="ac-editorial-overline">{t('AUTOLINKY / ADMINISTRATION','AUTOLINKY / الإدارة')}</span><h1>{t('Platform overview','نظرة عامة على المنصة')}</h1><p>{t('The people, activity and connections behind AutoLinky.','المستخدمون والنشاط والاتصالات في AutoLinky.')}</p></div>
      <button className="ws-button secondary" onClick={resource.reload}>{t('Refresh data','تحديث البيانات')}</button>
    </div>
    <section className="ac-kpis" aria-label={t('Platform totals','إجماليات المنصة')}>
      {metrics.map(([label,total,rows],index)=><div key={label}>
        <span className="ac-metric-label"><small aria-hidden="true">{String(index+1).padStart(2,'0')}</small>{label}</span>
        <strong>{Number(total).toLocaleString(ar?'ar':'en')}</strong><Facts rows={rows}/>
      </div>)}
    </section>
    <div className="ac-overview-main">
      <section className="ac-editorial-section ac-activity-panel">
        <div className="ac-editorial-section-head"><div><span className="ac-editorial-overline"><small aria-hidden="true">01</small>{t('ACTIVITY','النشاط')}</span><h2>{t('A closer look at growth','نظرة أقرب إلى النمو')}</h2></div><div className="ac-segmented" role="group" aria-label={t('Chart period','فترة الرسم')}>{[14,30,90].map(value=><button key={value} aria-pressed={days===value} onClick={()=>setDays(value)}>{value}{t('d',' يومًا')}</button>)}</div></div>
        <div className="ac-chart-meta"><div className="ac-chart-total"><b>{o.series.reduce((sum,row)=>sum+Number(row[measure]||0),0).toLocaleString(ar?'ar':'en')}</b><span>{measureLabels[measure]} · {days} {t('days','يومًا')}</span></div><button className="ws-text-button" aria-pressed={table} onClick={()=>setTable(!table)}>{table?t('Chart view','عرض الرسم'):t('Table view','عرض الجدول')}</button></div>
        <div className="ac-measure-tabs" role="group" aria-label={t('Chart measure','مقياس الرسم')}>{Object.entries(measureLabels).map(([key,label])=><button key={key} aria-pressed={measure===key} onClick={()=>setMeasure(key)}>{label}</button>)}</div>
        {table?<div className="ws-table-wrap ac-series-table"><table className="ws-table"><caption className="ws-sr-only">{measureLabels[measure]}</caption><thead><tr><th>{t('Day','اليوم')}</th><th>{measureLabels[measure]}</th></tr></thead><tbody>{[...o.series].reverse().map(row=><tr key={row.day}><td>{row.day}</td><td>{row[measure]}</td></tr>)}</tbody></table></div>:<MiniChart points={o.series} measure={measure} label={measureLabels[measure]} ar={ar}/>}
      </section>
      <section className="ac-editorial-section ac-readiness">
        <div className="ac-editorial-section-head"><div><span className="ac-editorial-overline"><small aria-hidden="true">02</small>AUTO APPLY</span><h2>{t('From signup to sending','من التسجيل إلى الإرسال')}</h2></div></div>
        <p className="ac-panel-description">{t('Setup milestones across all users.','خطوات الإعداد لدى جميع المستخدمين.')}</p>
        <div className="ac-funnel">{[[t('Signed up','تم التسجيل'),o.users.total],[t('CV uploaded','السيرة مرفوعة'),o.auto_apply.with_cv],[t('Gmail connected','Gmail متصل'),o.auto_apply.gmail_ok],[t('Auto Apply enabled','التلقائي مفعّل'),o.auto_apply.on]].map(([label,count],index)=><div key={label}><span><small aria-hidden="true">{String(index+1).padStart(2,'0')}</small>{label}<b>{Number(count).toLocaleString(ar?'ar':'en')}</b></span><div aria-hidden="true"><i style={{width:`${o.users.total?Math.min(100,count/o.users.total*100):0}%`}}/></div></div>)}</div>
        <a className="ws-text-button" href={(ar?'/ar':'')+'/admin/users/?filter=auto'}>{t('Explore users','استعرض المستخدمين')}</a>
      </section>
    </div>
    <div className="ac-overview-bottom">
      <section className="ac-editorial-section"><div className="ac-editorial-section-head"><div><span className="ac-editorial-overline"><small aria-hidden="true">03</small>{t('SENDING','الإرسال')}</span><h2>{t('The last 30 days','آخر ٣٠ يومًا')}</h2></div></div><Facts rows={[[t('Emails sent','رسائل مرسلة'),o.emails.last_30d],[t('Sent by Auto Apply','أُرسلت تلقائيًا'),o.emails.auto_30d],[t('Users who sent','مستخدمون أرسلوا'),userLink('sending',o.emails.senders_30d,'sent')]]}/><a className="ws-text-button" href={ar?'/ar/admin/sender/':'/admin/sender/'}>{t('Open sender','فتح المرسل')}</a></section>
      <section className="ac-editorial-section"><div className="ac-editorial-section-head"><div><span className="ac-editorial-overline"><small aria-hidden="true">04</small>{t('SUBSCRIPTIONS','الاشتراكات')}</span><h2>{t('Plans & allowances','الخطط والأرصدة')}</h2></div></div><Facts rows={[[t('Pro members','مستخدمو Pro'),userLink('pro',o.plans.pro)],[t('Unlimited allowance','رصيد غير محدود'),o.plans.unlimited],[t('Custom limits','حدود مخصصة'),userLink('custom',o.plans.custom)]]}/><a className="ws-text-button" href={ar?'/ar/admin/subscriptions/':'/admin/subscriptions/'}>{t('Manage subscriptions','إدارة الاشتراكات')}</a></section>
      <section className="ac-editorial-section ac-attention"><div className="ac-editorial-section-head"><div><span className="ac-editorial-overline"><small aria-hidden="true">05</small>{t('WORTH A LOOK','تستحق المراجعة')}</span><h2>{t('Keep things on track','كل شيء تحت المتابعة')}</h2></div></div><div className="ac-watch-list">{watch.map(([label,count,path])=><a key={label} href={(ar?'/ar':'')+'/admin/'+path+(path.includes('?')?'':'/')}><span>{label}</span><b className={Number(count)>0?'has-count':''}>{Number(count).toLocaleString(ar?'ar':'en')}</b></a>)}</div></section>
    </div>
    <section className="ac-operating-strip" aria-label={t('Operations summary','ملخص التشغيل')}>
      <span className="ac-editorial-overline"><small aria-hidden="true">06</small>{t('OPERATIONS SUMMARY','ملخص التشغيل')}</span>
      <div className="ac-operating-grid"><div><span>{t('Jobs collected today','وظائف جُمعت اليوم')}</span><b>{Number(o.jobs.today).toLocaleString(ar?'ar':'en')}</b></div><div><span>{t('Newest job','أحدث وظيفة')}</span><b>{adminWhen(o.jobs.last_at,ar)}</b></div><div><span>{t('Download visitors · 30 days','زوار التنزيل · ٣٠ يومًا')}</span><b>{Number(o.downloads.visitors_30d).toLocaleString(ar?'ar':'en')}</b></div><div><span>{t('Blocked accounts','حسابات محظورة')}</span><b>{userLink('blocked',o.users.blocked)}</b></div><div><span>{t('Last download','آخر تنزيل')}</span><b>{adminWhen(o.downloads.last_at,ar)}</b></div></div>
    </section>
  </div>;
}
