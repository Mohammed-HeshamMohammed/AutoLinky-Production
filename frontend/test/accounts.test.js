import { test } from 'node:test';
import assert from 'node:assert/strict';
import { createSiteServer } from '../server.js';
import { createDevelopmentServer } from '../scripts/dev-server.mjs';

test('public account links reach the existing sign-in, onboarding and authenticated browser routes',async()=>{
  const server=createSiteServer();await new Promise(done=>server.listen(0,'127.0.0.1',done));
  const origin=`http://127.0.0.1:${server.address().port}`;
  try{
    for(const [path,ua,expected] of [
      ['/login/','Desktop','/app/android/welcome?lang=en'],
      ['/signup/','Android','/app/android/welcome?lang=en'],
      ['/ar/login/','iPhone','/app/ios/welcome?lang=ar'],
      ['/signup/?lang=ar','Desktop','/app/android/welcome?lang=ar'],
      ['/dashboard/','Desktop','/app/android/matches?lang=en'],
      ['/jobs/','iPad','/app/ios/explore?lang=en'],
      ['/ar/profile/','Desktop','/app/android/profile?lang=ar'],
    ]){
      const response=await fetch(origin+path,{headers:{'user-agent':ua},redirect:'manual'});
      assert.equal(response.status,302);assert.equal(response.headers.get('location'),expected);assert.equal(response.headers.get('cache-control'),'no-store');assert.equal(response.headers.get('x-robots-tag'),'noindex');
    }
    const unsafe=await fetch(origin+'/login/?next=https://untrusted.invalid',{redirect:'manual'});
    assert.equal(new URL(unsafe.headers.get('location'),origin).origin,origin);
    assert.equal((await fetch(origin+'/login/',{method:'POST'})).status,405);
  }finally{server.closeAllConnections();await new Promise(done=>server.close(done));}
});

test('source preview renders visible login/account actions on landing and content pages in both languages without a build',async()=>{
  const app=await createDevelopmentServer({port:0});
  const origin=`http://127.0.0.1:${app.server.address().port}`;
  try{
    for(const path of ['/','/features/','/pricing/','/privacy/','/ar/','/ar/features/']){
      const response=await fetch(origin+path);const html=await response.text();
      assert.equal(response.status,200,html);
      const ar=path.startsWith('/ar/');
      assert.match(html,ar?/href="\/ar\/login\/"/:/href="\/login\/"/);
      assert.match(html,ar?/href="\/ar\/signup\/"/:/href="\/signup\/"/);
      assert.match(html,ar?/>تسجيل الدخول</:/>Log in</);
      assert.match(html,/class="nav site-header"/);
      if(path==='/'||path==='/ar/')assert.match(html,/class="web-entry"/);
      assert.match(html,/@vite\/client/);
    }
    assert.equal((await fetch(origin+'/login/',{redirect:'manual'})).status,302);
    assert.equal((await fetch(origin+'/not-a-page')).status,404);
    const source=await fetch(origin+'/src/main.jsx');assert.equal(source.status,200);assert.match(await source.text(),/LandingPage/);
    assert.equal((await fetch(origin+'/.runtime/private.env')).status>=400,true);
  }finally{await app.close();}
});
