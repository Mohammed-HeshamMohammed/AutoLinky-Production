import { HttpError,invalid } from '../http/errors.js';
export const uuid=/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
export const encodeCursor=value=>Buffer.from(JSON.stringify(value)).toString('base64url');
export function decodeCursor(text){
  try{if(text.length>200 || !/^[a-zA-Z0-9_=-]+$/.test(text))throw Error();const value=JSON.parse(Buffer.from(text,'base64url').toString('utf8'));if(!value || Array.isArray(value)||typeof value!=='object')throw Error();return value;}
  catch{throw new HttpError(400,'Invalid cursor');}
}
export function number(query,name,fallback,min,max){const value=query.get(name);const n=value===null?fallback:Number(value);if(!Number.isInteger(n)||n<min||n>max)throw invalid(`Invalid '${name}'`);return n;}
export function filter(query,name,allowed,pattern){const values=query.getAll(name);if(values.length>10 || values.some(v=>allowed?!allowed.includes(v):!pattern.test(v)))throw invalid(`Invalid '${name}' filter`);return values.length?[...new Set(values)]:null;}
export function time(value,name){if(!value || !/^\d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}/.test(value) || !Number.isFinite(Date.parse(value)))throw invalid(`Invalid '${name}'`);return new Date(/[zZ]|[+-]\d{2}:?\d{2}$/.test(value)?value:`${value}Z`);}
export const queryOf=request=>new URL(request.raw.url,'http://localhost').searchParams;
export const workModes=['onsite','remote','hybrid'];
export const applyMethods=['email','phone','whatsapp','link','dm','comment','easy_apply','external'];
export const sources=['post','linkedin_job'];
