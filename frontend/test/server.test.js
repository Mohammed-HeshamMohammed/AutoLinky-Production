import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdir,writeFile,rm } from 'node:fs/promises';
import { resolve,sep } from 'node:path';
import { randomBytes } from 'node:crypto';
import { createSiteServer } from '../server.js';

test('VPS server returns prerendered pages, real 404s, HEAD and safe path handling',async()=>{
  const base=resolve('.runtime'),directory=resolve(base,'site-test-'+randomBytes(6).toString('hex'));
  assert(directory.startsWith(base+sep));
  await mkdir(resolve(directory,'privacy'),{recursive:true});
  await writeFile(resolve(directory,'index.html'),'<title>Autolinky</title>');
  await writeFile(resolve(directory,'privacy/index.html'),'<title>Privacy</title>');
  await writeFile(resolve(directory,'404.html'),'<title>Missing</title>');
  const server=createSiteServer({directory});
  await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));
  const origin=`http://127.0.0.1:${server.address().port}`;
  try {
    const home=await fetch(origin);assert.equal(home.status,200);assert.match(await home.text(),/Autolinky/);
    const directoryRedirect=await fetch(origin+'/privacy?source=footer',{redirect:'manual'});
    assert.equal(directoryRedirect.status,308);assert.equal(directoryRedirect.headers.get('location'),'/privacy/?source=footer');
    assert.equal((await fetch(origin+'/privacy/')).status,200);
    const missing=await fetch(origin+'/unknown');assert.equal(missing.status,404);assert.match(await missing.text(),/Missing/);
    const escaped=await fetch(origin+'/%2e%2e%2fpackage.json');assert.equal(escaped.status,404);
    assert.equal((await fetch(origin+'/index.html',{method:'HEAD'})).headers.get('x-content-type-options'),'nosniff');
    assert.equal((await fetch(origin,{method:'POST'})).status,405);
  } finally {
    await new Promise(resolve=>server.close(resolve));
    assert(directory.startsWith(base+sep)&&/^site-test-[a-f0-9]{12}$/.test(directory.slice(base.length+1)));
    await rm(directory,{recursive:true,force:true});
  }
});

test('the Flutter environment uses route fallback without treating missing scripts as pages',async()=>{
  const base=resolve('.runtime'),directory=resolve(base,'site-test-'+randomBytes(6).toString('hex'));
  assert(directory.startsWith(base+sep));
  await mkdir(directory,{recursive:true});
  await writeFile(resolve(directory,'index.html'),'<title>Flutter fixture</title>');
  await writeFile(resolve(directory,'404.html'),'<title>Missing</title>');
  const server=createSiteServer({directory,spaFallback:true});
  await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));
  const origin=`http://127.0.0.1:${server.address().port}`;
  try {
    assert.equal((await fetch(origin+'/welcome/email/verify')).status,200);
    assert.equal((await fetch(origin+'/missing.js')).status,404);
    assert.equal((await fetch(origin+'/%2e%2e%2fpackage.json')).status,404);
  } finally {
    await new Promise(resolve=>server.close(resolve));
    assert(directory.startsWith(base+sep)&&/^site-test-[a-f0-9]{12}$/.test(directory.slice(base.length+1)));
    await rm(directory,{recursive:true,force:true});
  }
});

test('one origin connects the landing site and both app routes with safe reloads and fresh bundles',async()=>{
  const base=resolve('.runtime'),directory=resolve(base,'site-test-'+randomBytes(6).toString('hex'));
  assert(directory.startsWith(base+sep));
  for(const variant of ['android','ios']) {
    await mkdir(resolve(directory,'app',variant,'assets'),{recursive:true});
    await writeFile(resolve(directory,'app',variant,'index.html'),`<title>${variant} app</title>`);
    await writeFile(resolve(directory,'app',variant,'main.dart.js'),'window.app=true;');
    await writeFile(resolve(directory,'app',variant,'renderer.wasm'),Buffer.from([0,97,115,109]));
  }
  await writeFile(resolve(directory,'index.html'),'<a href="/app/">Open app</a>');
  await writeFile(resolve(directory,'404.html'),'<title>Missing</title>');
  const server=createSiteServer({directory});
  await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));
  const origin=`http://127.0.0.1:${server.address().port}`;
  try {
    assert.match(await (await fetch(origin)).text(),/Open app/);
    for(const variant of ['android','ios']) {
      const launch=await fetch(origin+'/app/?lang=ar',{redirect:'manual',headers:{'user-agent':variant==='ios'?'iPhone':'Android'}});
      assert.equal(launch.headers.get('location'),`/app/${variant}/?lang=ar`);
      const deep=await fetch(origin+`/app/${variant}/welcome/email/verify?oobCode=example`);
      assert.equal(deep.status,200);assert.match(await deep.text(),new RegExp(variant+' app'));
      const bundle=await fetch(origin+`/app/${variant}/main.dart.js`);
      assert.match(bundle.headers.get('cache-control'),/must-revalidate/);
      assert.equal((await fetch(origin+`/app/${variant}/renderer.wasm`)).headers.get('content-type'),'application/wasm');
      assert.equal((await fetch(origin+`/app/${variant}/missing.js`)).status,404);
      assert.equal((await fetch(origin+`/app/${variant}/assets/missing`)).status,404);
    }
    assert.equal((await fetch(origin+'/app/unknown/')).status,404);
    assert.equal((await fetch(origin+'/%2e%2e%2fpackage.json')).status,404);
  } finally {
    await new Promise(resolve=>server.close(resolve));
    assert(directory.startsWith(base+sep)&&/^site-test-[a-f0-9]{12}$/.test(directory.slice(base.length+1)));
    await rm(directory,{recursive:true,force:true});
  }
});
