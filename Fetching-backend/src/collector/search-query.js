export const MAX_OPERATORS=5,CEILING=360,PLACES_PER_SEARCH=4;
const pluralWords={engineer:'engineers',developer:'developers',analyst:'analysts',designer:'designers',specialist:'specialists',
  administrator:'administrators',technician:'technicians',consultant:'consultants',architect:'architects',accountant:'accountants',
  manager:'managers',representative:'representatives',agent:'agents',officer:'officers',scientist:'scientists',tester:'testers',
  programmer:'programmers',executive:'executives',coordinator:'coordinators',assistant:'assistants',supervisor:'supervisors',
  operator:'operators',lead:'leads',intern:'interns',trainee:'trainees'};
// Python's Unicode whitespace set includes the four information separators,
// and does not include JavaScript's additional FEFF whitespace character.
const spaces=/[\p{White_Space}\u001c-\u001f]+/gu;
export function clean(text) {return (text||'').replace(/["()]/g,' ').replace(spaces,' ').replace(/^ +| +$/g,'').toLowerCase();}
export function plural(title) {
  const words=clean(title).split(' '),last=words.at(-1);
  return Object.hasOwn(pluralWords,last)?[...words.slice(0,-1),pluralWords[last]].join(' '):null;
}
export function phrasesFor(title,synonyms=[]) {
  title=clean(title);
  const output=[title],many=plural(title);
  if(many)output.push(many);
  for(const synonym of synonyms) {
    const value=clean(synonym);
    if(value.split(' ').length>=2 && /^[a-z0-9 .+#/&'-]+$/.test(value) && !output.includes(value) && !output.some(phrase=>value.includes(phrase)))output.push(value);
  }
  return output;
}
function group(items,quoteAll) {
  const values=items.map(item=>quoteAll||item.includes(' ')?`"${item}"`:item);
  return values.length===1?values[0]:`(${values.join(' OR ')})`;
}
export function build(phrases,places=[]) {
  const text=group(phrases,true),values=places.map(clean).filter(Boolean);
  return values.length?`${text} ${group(values,false)}`:text;
}
export function operators(query) {
  return query.replace(/"[^"]*"/g,' ').replace(/[()]/g,' ').split(/[\p{White_Space}\u001c-\u001f]+/u).filter(word=>['OR','AND','NOT'].includes(word)).length;
}
export function placeGroups(locations) {
  const groups=new Map(),alone=[];
  for(const location of locations) {
    const keyword=clean(location.keyword||''),country=location.country;
    if(!country)alone.push([keyword?[keyword]:[],null]);
    else {
      if(!groups.has(country))groups.set(country,[]);
      const keywords=groups.get(country);if(!keywords.includes(keyword))keywords.push(keyword);
    }
  }
  const output=[];
  for(const [country,keywords] of groups)for(let i=0;i<keywords.length;i+=PLACES_PER_SEARCH)output.push([keywords.slice(i,i+PLACES_PER_SEARCH),country]);
  return [...output,...alone];
}
export function searches(title,locations,synonyms=[]) {
  const phrases=phrasesFor(title,synonyms),output=[];
  for(const [places,country] of placeGroups(locations)) {
    const room=MAX_OPERATORS+2-Math.max(places.length,1),query=build(phrases.slice(0,Math.max(room,1)),places);
    if(operators(query)>MAX_OPERATORS)throw Error('Search exceeds the recorded source operator budget');
    output.push([query,places.join(' | '),country]);
  }
  return output;
}
