import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdir,writeFile,rm } from 'node:fs/promises';
import { resolve,sep } from 'node:path';
import { randomBytes } from 'node:crypto';
import { createSiteServer } from '../server.js';

test('React VPS server returns pages, real 404s, HEAD and safe paths',async()=>{
  const base=resolve('.runtime'),directory=resolve(base,'site-test-'+randomBytes(6).toString('hex'));assert(directory.startsWith(base+sep));
  await mkdir(resolve(directory,'privacy'),{recursive:true});await writeFile(resolve(directory,'index.html'),'<title>AutoLinky</title>');await writeFile(resolve(directory,'privacy/index.html'),'<title>Privacy</title>');await writeFile(resolve(directory,'404.html'),'<title>Missing</title>');
  const server=createSiteServer({directory});await new Promise(done=>server.listen(0,'127.0.0.1',done));const origin=`http://127.0.0.1:${server.address().port}`;
  try{
    assert.match(await (await fetch(origin)).text(),/AutoLinky/);
    const redirect=await fetch(origin+'/privacy?source=footer',{redirect:'manual'});assert.equal(redirect.status,308);assert.equal(redirect.headers.get('location'),'/privacy/?source=footer');
    assert.equal((await fetch(origin+'/privacy/')).status,200);
    for(const path of ['/unknown','/missing.js','/%2e%2e%2fpackage.json'])assert.equal((await fetch(origin+path)).status,404);
    assert.equal((await fetch(origin,{method:'HEAD'})).headers.get('x-content-type-options'),'nosniff');assert.equal((await fetch(origin,{method:'POST'})).status,405);
  }finally{server.closeAllConnections();await new Promise(done=>server.close(done));await rm(directory,{recursive:true,force:true});}
});

test('retired browser routes redirect into React and cannot serve stale native bundles',async()=>{
  const base=resolve('.runtime'),directory=resolve(base,'site-test-'+randomBytes(6).toString('hex'));assert(directory.startsWith(base+sep));
  await mkdir(resolve(directory,'workspace'),{recursive:true});await writeFile(resolve(directory,'workspace/index.html'),'<main>React workspace</main>');
  await mkdir(resolve(directory,'app/android'),{recursive:true});await writeFile(resolve(directory,'app/android/main.dart.js'),'stale-bundle');
  const server=createSiteServer({directory});await new Promise(done=>server.listen(0,'127.0.0.1',done));const origin=`http://127.0.0.1:${server.address().port}`;
  try{
    for(const agent of ['iPhone','Android','Desktop'])assert.equal((await fetch(origin+'/app/',{redirect:'manual',headers:{'user-agent':agent}})).headers.get('location'),'/dashboard/');
    for(const [path,target] of [['/app/android/matches','/dashboard/'],['/app/ios/profile/?lang=ar','/ar/profile/?lang=ar'],['/app/android/welcome/email/verify?oobCode=fixture&mode=signIn','/login/?oobCode=fixture&mode=signIn']]){
      const response=await fetch(origin+path,{redirect:'manual'});assert.equal(response.status,302);assert.equal(response.headers.get('location'),target);assert.equal(response.headers.get('cache-control'),'no-store');assert.match(await (await fetch(origin+target)).text(),/React workspace/);
    }
    for(const path of ['/app/android/main.dart.js','/app/ios/flutter_bootstrap.js','/app/android/assets/brand/logo.png','/app/unknown/'])assert.equal((await fetch(origin+path)).status,404);
  }finally{server.closeAllConnections();await new Promise(done=>server.close(done));await rm(directory,{recursive:true,force:true});}
});

test('film playback supports video MIME types and byte ranges for forward and reverse seeking',async()=>{
  const base=resolve('.runtime'),directory=resolve(base,'film-test-'+randomBytes(6).toString('hex'));assert(directory.startsWith(base+sep));
  await mkdir(directory,{recursive:true});const bytes=Buffer.from(Array.from({length:256},(_,i)=>i));await writeFile(resolve(directory,'story.mp4'),bytes);
  const server=createSiteServer({directory});await new Promise(done=>server.listen(0,'127.0.0.1',done));const url=`http://127.0.0.1:${server.address().port}/story.mp4`;
  try{
    const whole=await fetch(url);assert.equal(whole.status,200);assert.equal(whole.headers.get('content-type'),'video/mp4');assert.equal(whole.headers.get('accept-ranges'),'bytes');assert.deepEqual(Buffer.from(await whole.arrayBuffer()),bytes);
    for(const [range,start,end] of [['bytes=180-209',180,209],['bytes=0-19',0,19],['bytes=240-',240,255],['bytes=-8',248,255],['bytes=250-999',250,255]]){
      const response=await fetch(url,{headers:{Range:range}});assert.equal(response.status,206);assert.equal(response.headers.get('content-range'),`bytes ${start}-${end}/256`);assert.equal(Number(response.headers.get('content-length')),end-start+1);assert.deepEqual(Buffer.from(await response.arrayBuffer()),bytes.subarray(start,end+1));
    }
    for(const range of ['bytes=256-','bytes=100-80','bytes=-0','bytes=-','bytes=0-1,10-11']){const response=await fetch(url,{headers:{Range:range}});assert.equal(response.status,416);assert.equal(response.headers.get('content-range'),'bytes */256');assert.equal((await response.arrayBuffer()).byteLength,0);}
    const head=await fetch(url,{method:'HEAD',headers:{Range:'bytes=10-20'}});assert.equal(head.status,200);assert.equal(head.headers.get('content-length'),'256');assert.equal((await head.arrayBuffer()).byteLength,0);
  }finally{server.closeAllConnections();await new Promise(done=>server.close(done));await rm(directory,{recursive:true,force:true});}
});
