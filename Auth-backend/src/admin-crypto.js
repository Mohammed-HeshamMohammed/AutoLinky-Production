import { scrypt as scryptCallback,randomBytes,createCipheriv,createDecipheriv,createHmac,timingSafeEqual,createHash } from 'node:crypto';
import { promisify } from 'node:util';
const scrypt=promisify(scryptCallback),options={N:32768,r:8,p:1,maxmem:64*1024*1024};
export async function hashPassword(password){
  if(typeof password!=='string'||password.length<12||password.length>128)throw Error('Admin passwords must contain 12 to 128 characters');
  const salt=randomBytes(16),hash=await scrypt(password,salt,32,options);
  return `scrypt:32768:8:1:${salt.toString('base64url')}:${hash.toString('base64url')}`;
}
export async function verifyPassword(password,encoded){
  const parts=String(encoded||'').split(':');
  if(parts.length!==6||parts.slice(0,4).join(':')!=='scrypt:32768:8:1'||typeof password!=='string'||password.length>128)return false;
  const salt=Buffer.from(parts[4],'base64url'),expected=Buffer.from(parts[5],'base64url');if(salt.length!==16||expected.length!==32)return false;
  const actual=await scrypt(password,salt,32,options);return timingSafeEqual(actual,expected);
}
const alphabet='ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
export function base32(bytes){let output='',buffer=0,bits=0;for(const byte of bytes){buffer=(buffer<<8)|byte;bits+=8;while(bits>=5){bits-=5;output+=alphabet[(buffer>>>bits)&31];}}if(bits)output+=alphabet[(buffer<<(5-bits))&31];return output;}
function decodeBase32(value){let buffer=0,bits=0;const bytes=[];for(const char of String(value).toUpperCase().replace(/=+$/,'')){const index=alphabet.indexOf(char);if(index<0)throw Error('Invalid TOTP secret');buffer=(buffer<<5)|index;bits+=5;if(bits>=8){bits-=8;bytes.push((buffer>>>bits)&255);}}return Buffer.from(bytes);}
export function totp(secret,step){const counter=Buffer.alloc(8);counter.writeBigUInt64BE(BigInt(step));const hash=createHmac('sha1',decodeBase32(secret)).update(counter).digest(),offset=hash.at(-1)&15;return String((hash.readUInt32BE(offset)&0x7fffffff)%1000000).padStart(6,'0');}
export function totpStep(secret,code,last=-1,now=Date.now()){
  if(!/^\d{6}$/.test(String(code)))return null;
  const current=Math.floor(now/30000),actual=Buffer.from(code);let found=null;
  for(const step of [current-1,current,current+1])if(step>Number(last)&&timingSafeEqual(Buffer.from(totp(secret,step)),actual))found=step;
  return found;
}
export const tokenHash=value=>createHash('sha256').update(value).digest('hex');
export function encryptionKey(value){const key=Buffer.from(value||'','base64url');if(key.length!==32)throw Error('ADMIN_TOTP_KEY must be a 32-byte base64url key');return key;}
export function encryptTotp(secret,key){const nonce=randomBytes(12),cipher=createCipheriv('aes-256-gcm',key,nonce),encrypted=Buffer.concat([cipher.update(secret,'utf8'),cipher.final()]);return ['v1',nonce.toString('base64url'),encrypted.toString('base64url'),cipher.getAuthTag().toString('base64url')].join(':');}
export function decryptTotp(encoded,key){const [version,nonce,body,tag]=String(encoded).split(':');if(version!=='v1')throw Error('Invalid TOTP envelope');const decipher=createDecipheriv('aes-256-gcm',key,Buffer.from(nonce,'base64url'));decipher.setAuthTag(Buffer.from(tag,'base64url'));return Buffer.concat([decipher.update(Buffer.from(body,'base64url')),decipher.final()]).toString('utf8');}
export function signedToken(secret,payload){const body=Buffer.from(JSON.stringify(payload)).toString('base64url');return body+'.'+createHmac('sha256',secret).update(body).digest('base64url');}
export function readToken(secret,token,purpose,now=Date.now()){
  try{if(typeof token!=='string'||token.length>2048)return null;const [body,signature,...extra]=token.split('.');if(extra.length)return null;const actual=Buffer.from(signature||'','base64url'),expected=createHmac('sha256',secret).update(body).digest();if(actual.length!==expected.length||!timingSafeEqual(actual,expected))return null;const payload=JSON.parse(Buffer.from(body,'base64url'));if(payload.purpose!==purpose||!Number.isSafeInteger(payload.exp)||payload.exp<=Math.floor(now/1000))return null;return payload;}catch{return null;}
}
