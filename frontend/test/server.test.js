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
