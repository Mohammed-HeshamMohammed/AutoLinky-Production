import { fold,normalize,unique } from './text.js';
const escape=text=>text.replace(/[.*+?^${}()|[\]\\]/g,'\\$&');
export function skillText(text){return fold(text).trim().replace(/\s+/gu,' ').replace(/(?<![\p{L}\p{N}_])(?:وال|فال|بال|كال|لل|ال)(?=[\u0621-\u064A]{2,})/gu,'');}
const first=(map,key,value)=>{if(!map.has(key))map.set(key,value);};
export class SkillMatcher{
  constructor(skills,learned={}){
    this.folded=new Map();this.exact=new Map();this.names=new Map();this.learned=new Map(Object.entries(learned).map(([name,slug])=>[skillText(name),slug]));
    for(const [slug,aliases] of skills){for(const name of aliases){if(name.startsWith('='))first(this.exact,name.slice(1),slug);else if(name.trim().length>1)first(this.folded,skillText(name),slug);}if(aliases.length)first(this.names,skillText(aliases[0].replace(/^=/,'')),slug);}
    const pattern=map=>map.size?new RegExp(`(?<![\\p{L}\\p{N}_])(?:${[...map.keys()].sort((a,b)=>b.length-a.length).map(escape).join('|')})(?![\\p{L}\\p{N}_])`,'gu'):null;
    this.foldedRE=pattern(this.folded);this.exactRE=pattern(this.exact);
  }
  extract(text,limit=40){const found=[];for(const [pattern,body,map] of [[this.foldedRE,skillText(text),this.folded],[this.exactRE,text.normalize('NFKC').trim().replace(/\s+/gu,' '),this.exact]]){if(pattern)for(const match of body.matchAll(pattern))found.push(map.get(match[0]));}return unique(found.filter(Boolean)).slice(0,limit);}
  lookup(name){const key=skillText(name);return this.exact.get(name)||this.folded.get(key)||this.names.get(key)||this.learned.get(key)||null;}
}
export class RoleMatcher{
  constructor(roles){this.keywords=new Map();for(const [slug,words] of roles)for(const word of words){const key=normalize(word);if(key)first(this.keywords,key,slug);}this.max=Math.max(1,...[...this.keywords.keys()].map(k=>k.split(' ').length));}
  match(text){const words=normalize(text).split(' ');let best=null;for(let i=0;i<words.length;i++)for(let n=Math.min(this.max,words.length-i);n>0;n--){const role=this.keywords.get(words.slice(i,i+n).join(' '));if(role){if(!best||n>best.n||(n===best.n&&i+n>best.end))best={n,end:i+n,role};break;}}return best?.role||null;}
}
