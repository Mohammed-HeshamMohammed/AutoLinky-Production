import { createCipheriv,createDecipheriv,createHmac,randomBytes,timingSafeEqual } from 'node:crypto';
function keys(value){const list=value.split(',').map(v=>v.trim()).filter(Boolean).map(v=>{if(!/^[A-Za-z0-9_-]+={0,2}$/.test(v))throw Error('Invalid Fernet key');const bytes=Buffer.from(v,'base64url');if(bytes.length!==32)throw Error('Invalid Fernet key');return bytes;});if(!list.length)throw Error('Mail secret is not configured');return list;}
export function encryptSecret(value,configuration){const key=keys(configuration)[0],stamp=Buffer.alloc(8);stamp.writeBigUInt64BE(BigInt(Math.floor(Date.now()/1000)));const iv=randomBytes(16),cipher=createCipheriv('aes-128-cbc',key.subarray(16),iv);const ciphertext=Buffer.concat([cipher.update(value,'utf8'),cipher.final()]);const signed=Buffer.concat([Buffer.from([128]),stamp,iv,ciphertext]);return Buffer.concat([signed,createHmac('sha256',key.subarray(0,16)).update(signed).digest()]).toString('base64').replaceAll('+','-').replaceAll('/','_');}
export function decryptSecret(value,configuration){
  if(typeof value!=='string'||value.length>8192||!/^[A-Za-z0-9_-]+={0,2}$/.test(value))throw Error('Invalid encrypted mail secret');
  const bytes=Buffer.from(value,'base64url');if(bytes.length<73||bytes[0]!==128||(bytes.length-57)%16!==0)throw Error('Invalid encrypted mail secret');
  const signed=bytes.subarray(0,-32),tag=bytes.subarray(-32);
  for(const key of keys(configuration)){const actual=createHmac('sha256',key.subarray(0,16)).update(signed).digest();if(timingSafeEqual(actual,tag)){const cipher=createDecipheriv('aes-128-cbc',key.subarray(16),bytes.subarray(9,25));return Buffer.concat([cipher.update(bytes.subarray(25,-32)),cipher.final()]).toString('utf8');}}
  throw Error('Mail secret cannot be decrypted');
}
export function secretAvailable(configuration){try{keys(configuration);return true;}catch{return false;}}
