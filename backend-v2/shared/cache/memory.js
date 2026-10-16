import { performance } from 'node:perf_hooks';

export class MemoryCache {
  constructor({maxEntries=1000,maxBytes=8*1024*1024,now=()=>performance.now()}={}) {
    this.maxEntries=maxEntries;this.maxBytes=maxBytes;this.now=now;this.entries=new Map();this.inflight=new Map();this.bytes=0;
  }
  get(key) {
    const entry=this.entries.get(key);
    if (!entry) return undefined;
    if (entry.expires<=this.now()) { this.delete(key);return undefined; }
    this.entries.delete(key);this.entries.set(key,entry);
    return structuredClone(entry.value);
  }
  set(key,value,ttlMs) {
    this.delete(key);
    const bytes=Buffer.byteLength(JSON.stringify(value))+Buffer.byteLength(key);
    if (bytes>this.maxBytes || ttlMs<=0) return;
    while (this.entries.size>=this.maxEntries || this.bytes+bytes>this.maxBytes) this.delete(this.entries.keys().next().value);
    this.entries.set(key,{value:structuredClone(value),bytes,expires:this.now()+ttlMs});this.bytes+=bytes;
  }
  delete(key) { const entry=this.entries.get(key);if(entry){this.bytes-=entry.bytes;this.entries.delete(key);} }
  clear() { this.entries.clear();this.bytes=0; }
  async load(key,ttlMs,loader,{cacheIf=()=>true}={}) {
    const value=this.get(key);if(value!==undefined) return value;
    if (!this.inflight.has(key)) {
      if (this.inflight.size>=this.maxEntries) return loader();
      const promise=Promise.resolve().then(loader).then(result=>{if(cacheIf(result))this.set(key,result,ttlMs);return result;}).finally(()=>this.inflight.delete(key));
      this.inflight.set(key,promise);
    }
    return structuredClone(await this.inflight.get(key));
  }
}
