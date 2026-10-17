import {test} from 'node:test';
import assert from 'node:assert/strict';
import {execFile,spawnSync} from 'node:child_process';
import {createHash} from 'node:crypto';
import {createCVExtractor} from '../../../App-backend/src/cv-extractor.js';
import {loadConfig} from '../../../App-backend/lib/config.js';

const config=loadConfig({}),python=process.platform==='win32'?'python':'python3';
function document(code){
  const result=spawnSync(python,['-E','-B','-c',code],{maxBuffer:5*1024*1024,timeout:10000,windowsHide:true});
  assert.equal(result.status,0,String(result.stderr));return result.stdout;
}
const docx=document(`import io,zipfile,sys
out=io.BytesIO()
with zipfile.ZipFile(out,'w',zipfile.ZIP_DEFLATED) as z:
 z.writestr('word/document.xml','<w:document><w:p><w:t>Developer '+('JavaScript experience in web applications. '*10)+'</w:t></w:p></w:document>')
 z.writestr('word/_rels/document.xml.rels','<Relationships><Relationship Target="https://github.com/example" TargetMode="External"/></Relationships>')
sys.stdout.buffer.write(out.getvalue())`);
const valid=bytes=>({result:{file_type:'docx',text:'Developer '.repeat(30),pages:null,size:bytes.length,sha256:createHash('sha256').update(bytes).digest('hex'),links:[]}});

test('CV extraction is idle until a valid upload, then exits after each parse without passing App secrets',async t=>{
  const names=['PG_DATABASE_URL','GOOGLE_APPLICATION_CREDENTIALS','AI_API_KEY','CV_EXTRACTOR_URL','CV_EXTRACTOR_KEY'];
  const previous=names.map(name=>[name,process.env[name]]);
  for(const name of names)process.env[name]='private-on-demand-fixture';
  t.after(()=>{for(const [name,value] of previous)if(value===undefined)delete process.env[name];else process.env[name]=value;});
  const children=[];
  const extract=createCVExtractor({run:(command,args,options,callback)=>{
    for(const name of names)assert(!Object.hasOwn(options.env,name));
    assert(!Object.hasOwn(options.env,'PYTHONPATH'));assert.equal(options.timeout,10000);assert.equal(options.maxBuffer,300000);assert.equal(options.killSignal,'SIGKILL');assert(!options.shell);
    const child=execFile(command,args,options,callback);children.push(child);return child;
  }});
  assert.equal(children.length,0);
  for(const [bytes,status] of [[Buffer.alloc(0),400],[Buffer.from('not a CV'),415],[Buffer.alloc(4194305),413]])await assert.rejects(extract(bytes,config),{status});
  assert.equal(children.length,0);
  for(let index=0;index<2;index++){
    const parsed=await extract(docx,config);assert.equal(parsed.file_type,'docx');assert.match(parsed.text,/Developer JavaScript/);assert.deepEqual(parsed.links,['https://github.com/example']);assert.equal(parsed.sha256,createHash('sha256').update(docx).digest('hex'));
    assert.equal(children.length,index+1);assert.equal(children[index].exitCode,0);
  }
  assert.equal(loadConfig({CV_EXTRACTOR_URL:'https://retired.invalid',CV_EXTRACTOR_KEY:'retired'}).cvExtractorUrl,undefined);
});

test('the App-owned worker parses a real text PDF and preserves malformed/encrypted PDF errors',async()=>{
  const pdf=document(`import sys,io
from pypdf import PdfWriter
from pypdf.generic import DictionaryObject,NameObject,DecodedStreamObject
w=PdfWriter();p=w.add_blank_page(width=612,height=792)
font=DictionaryObject({NameObject('/Type'):NameObject('/Font'),NameObject('/Subtype'):NameObject('/Type1'),NameObject('/BaseFont'):NameObject('/Helvetica')})
p[NameObject('/Resources')]=DictionaryObject({NameObject('/Font'):DictionaryObject({NameObject('/F1'):w._add_object(font)})})
stream=DecodedStreamObject();stream.set_data(('BT /F1 12 Tf 50 700 Td ('+('Developer JavaScript experience. '*12)+') Tj ET').encode())
p[NameObject('/Contents')]=w._add_object(stream)
out=io.BytesIO();w.write(out);sys.stdout.buffer.write(out.getvalue())`);
  const extract=createCVExtractor(),parsed=await extract(pdf,config);
  assert.equal(parsed.file_type,'pdf');assert.equal(parsed.pages,1);assert.match(parsed.text,/Developer JavaScript/);
  await assert.rejects(extract(Buffer.from('%PDF-invalid'),config),{status:422,detail:'cv_unreadable'});
  const encrypted=document(`import io,sys
from pypdf import PdfWriter
w=PdfWriter();w.add_blank_page(width=100,height=100);w.encrypt('private-fixture-password');out=io.BytesIO();w.write(out);sys.stdout.buffer.write(out.getvalue())`);
  await assert.rejects(extract(encrypted,config),{status:422,detail:'cv_encrypted'});
});

test('concurrent parsing is bounded and capacity is released after completion',async()=>{
  let complete,calls=0;
  const extract=createCVExtractor({run:(_command,_args,_options,callback)=>{calls++;complete=callback;return {stdin:{on:()=>{},end:()=>{}}};}});
  const first=extract(docx,config);
  await assert.rejects(extract(docx,config),{status:503});assert.equal(calls,1);
  complete(null,JSON.stringify(valid(docx)));await first;
  const next=extract(docx,config);assert.equal(calls,2);complete(null,JSON.stringify(valid(docx)));await next;
});

test('a timed-out parser is killed, its errors stay private and later uploads can parse',async()=>{
  let calls=0,hung;
  const extract=createCVExtractor({timeoutMs:100,run:(command,args,options,callback)=>{
    if(calls++===0){hung=execFile(command,['-E','-B','-c','import time; time.sleep(30)'],options,callback);return hung;}
    return execFile(command,args,{...options,timeout:10000},callback);
  }});
  await assert.rejects(extract(docx,config),{status:503,detail:'Service temporarily unavailable'});assert(hung.killed);
  assert.equal((await extract(docx,config)).file_type,'docx');
});

test('missing Python, excessive output and corrupt parser DTOs fail without exposing document content',async()=>{
  await assert.rejects(createCVExtractor({python:'autolinky-missing-python-fixture'})(docx,config),{status:503});
  const noisy=createCVExtractor({run:(command,_args,options,callback)=>execFile(command,['-E','-B','-c',"print('private-fixture-'*30000)"],options,callback)});
  await assert.rejects(noisy(docx,config),error=>error.status===503&&!error.message.includes('private-fixture'));
  const payloads=['private-fixture-invalid-json',JSON.stringify({error:'private-fixture-error',status:422}),JSON.stringify({result:{...valid(docx).result,sha256:'incorrect'}})];
  const extract=createCVExtractor({run:(_command,_args,_options,callback)=>({stdin:{on:()=>{},end:()=>callback(null,payloads.shift())}})});
  for(let index=0;index<3;index++)await assert.rejects(extract(docx,config),{status:503,detail:'Service temporarily unavailable'});
});
