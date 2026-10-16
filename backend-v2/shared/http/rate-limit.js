import { HttpError } from './errors.js';
export class MemoryLimiter {
  constructor({maxEntries=20000,now=()=>Date.now()}={}){this.entries=new Map();this.maxEntries=maxEntries;this.now=now;}
  enforce(key,max,seconds) {
    const now=this.now(),start=Math.floor(now/(seconds*1000))*seconds*1000;
    let entry=this.entries.get(key);
    if(!entry || entry.start!==start){
      if(this.entries.size>=this.maxEntries){for(const [k,e] of this.entries) if(e.expires<=now)this.entries.delete(k);}
      if(this.entries.size>=this.maxEntries) throw new HttpError(503,'Service temporarily unavailable');
      entry={start,expires:start+seconds*1000,hits:0};this.entries.set(key,entry);
    }
    entry.hits++;
    if(entry.hits>max) throw new HttpError(429,'Too many requests',{'Retry-After':String(Math.max(1,Math.ceil((entry.expires-now)/1000)))});
  }
}
export async function durableLimit(db,bucket,max,seconds) {
  const {rows}=await db.query('SELECT public.api_hit($1,$2,$3) retry',[bucket,seconds,max]);
  if(rows[0].retry>0) throw new HttpError(429,'Too many requests',{'Retry-After':String(rows[0].retry)});
}
