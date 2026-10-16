export function fold(text='') {
  return String(text).toLowerCase().normalize('NFKD').replace(/\p{M}/gu,'').replaceAll('\u0640','').replaceAll('ة','ه').replaceAll('ى','ي').replaceAll('ٱ','ا');
}
export function normalize(text='') {
  return fold(text).replaceAll('&',' and ').replace(/[^\p{L}\p{N}_\s]/gu,' ').replaceAll('_',' ')
    .replace(/(?<![\p{L}\p{N}_])(?:وال|فال|بال|كال|لل|ال)(?=[\u0621-\u064A]{2,})/gu,'').trim().replace(/\s+/gu,' ');
}
export const unique=values=>[...new Set(values)];
export function uniqueText(values){const result=new Map();for(const value of values)if(!result.has(value.toLowerCase()))result.set(value.toLowerCase(),value);return [...result.values()];}
