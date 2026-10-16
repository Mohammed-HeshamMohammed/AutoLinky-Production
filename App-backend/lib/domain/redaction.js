const phone=/(?<![\p{L}\p{N}_+])\+?\(?\d[\d\s().\-/]{6,}\d(?![\p{L}\p{N}_])/gu;
export function redactContacts(text){
  return text.replace(/[\p{L}\p{N}_.+-]+@[\p{L}\p{N}_-]+(?:\.[\p{L}\p{N}_-]+)+/gu,'[email]')
    .replace(/(?:https?:\/\/|www\.)\S+|\b[\w-]+\.(?:com|net|org|io|me|dev)\/\S*/giu,'[link]')
    .replace(phone,s=>{const groups=s.match(/\d+/g)||[],n=groups.join('').length;return n>=9&&n<=15&&!groups.every(g=>/^(19|20)\d{2}$/.test(g))?'[phone]':s;});
}
