import { execFile } from 'node:child_process';
import { createHash } from 'node:crypto';
import { fileURLToPath } from 'node:url';
import { HttpError,unavailable } from '../lib/http/errors.js';

const worker=fileURLToPath(new URL('../extractor/worker.py',import.meta.url));
const errors={cv_empty:400,cv_too_large:413,cv_bad_type:415,cv_unreadable:422,cv_encrypted:422,cv_no_text:422};
const allowedEnvironment=new Set(['PATH','SYSTEMROOT','WINDIR','TEMP','TMP','HOME','USERPROFILE','APPDATA','LOCALAPPDATA','LANG','LC_ALL','LC_CTYPE']);

export function createCVExtractor({run=execFile,python=process.platform==='win32'?'python':'python3',timeoutMs=10000}={}){
  let active=false;
  return async(bytes,config)=>{
    if(!bytes.length)throw new HttpError(400,'cv_empty');
    if(bytes.length>Math.min(config.cvMaxBytes,4*1024*1024))throw new HttpError(413,'cv_too_large');
    const type=bytes.subarray(0,5).equals(Buffer.from('%PDF-'))?'pdf':bytes.subarray(0,4).equals(Buffer.from([80,75,3,4]))?'docx':null;
    if(!type)throw new HttpError(415,'cv_bad_type');
    // One parser at a time per App process, without a background server or queue.
    if(active)throw unavailable();
    active=true;
    try{
      const env=Object.fromEntries(Object.entries(process.env).filter(([name])=>allowedEnvironment.has(name.toUpperCase())));
      const output=await new Promise((resolve,reject)=>{
        const child=run(python,['-E','-B',worker],{env,encoding:'utf8',windowsHide:true,timeout:timeoutMs,killSignal:'SIGKILL',maxBuffer:300000},(error,stdout)=>error?reject(unavailable()):resolve(stdout));
        child.stdin?.on('error',()=>{});
        child.stdin?.end(bytes);
      });
      let payload;try{payload=JSON.parse(output);}catch{throw unavailable();}
      if(!payload||typeof payload!=='object')throw unavailable();
      if(Object.hasOwn(errors,payload.error)&&errors[payload.error]===payload.status)throw new HttpError(payload.status,payload.error);
      const data=payload.result;
      if(!data||data.file_type!==type||typeof data.text!=='string'||data.text.length>40000||data.size!==bytes.length||data.sha256!==createHash('sha256').update(bytes).digest('hex')||!Array.isArray(data.links)||data.links.length>20||data.links.some(link=>typeof link!=='string'||link.length>300||!/^https?:\/\//i.test(link))||!(type==='docx'?data.pages===null:Number.isInteger(data.pages)&&data.pages>0))throw unavailable();
      return data;
    }catch(error){if(error instanceof HttpError)throw error;throw unavailable();}
    finally{active=false;}
  };
}

export const extractCV=createCVExtractor();
