import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdir,writeFile,rm } from 'node:fs/promises';
import { resolve,sep } from 'node:path';
import { randomBytes } from 'node:crypto';
import { createSiteServer } from '../server.js';
import { createDevelopmentServer } from '../scripts/dev-server.mjs';
import { workspaceRoute,safeWorkspaceNext } from '../workspace-routes.js';

test('desktop routes preserve public product pages, mobile copies and safe post-login navigation',()=>{
  assert.deepEqual(workspaceRoute('/ar/jobs/'),{admin:false,screen:'jobs',lang:'ar'});
  assert.deepEqual(workspaceRoute('/admin/'),{admin:true,screen:'overview',lang:'en'});
  for(const screen of ['collector','accounts','search-titles','sender'])assert.deepEqual(workspaceRoute('/ar/admin/'+screen+'/'),{admin:true,screen,lang:'ar'});
  assert.equal(workspaceRoute('/app/android/matches'),null);assert.equal(workspaceRoute('/auto-apply/'),null);assert.equal(workspaceRoute('/admin/api/overview'),null);
  assert.equal(workspaceRoute('/automation/').screen,'auto-apply');
  for(const value of ['https://untrusted.invalid','//untrusted.invalid','/\\untrusted.invalid','/admin/','/login/','/unknown'])assert.equal(safeWorkspaceNext(value),'/dashboard/');
  assert.equal(safeWorkspaceNext('/jobs/?q=engineer'),'/jobs/?q=engineer');
});

test('production serves private desktop shells and restricted admin CSP',async()=>{
  const base=resolve('.runtime'),directory=resolve(base,'desktop-test-'+randomBytes(6).toString('hex'));assert(directory.startsWith(base+sep));
  await mkdir(resolve(directory,'workspace'),{recursive:true});await writeFile(resolve(directory,'workspace/index.html'),'<main>Workspace shell</main>');
  const server=createSiteServer({directory});await new Promise(done=>server.listen(0,'127.0.0.1',done));const origin=`http://127.0.0.1:${server.address().port}`;
  try{
    for(const path of ['/login/','/signup/','/dashboard/','/jobs/','/ar/profile/','/admin/','/admin/users/','/admin/collector/','/admin/search-titles/','/ar/admin/sender/']){
      const response=await fetch(origin+path,{redirect:'manual'});assert.equal(response.status,200);assert.match(await response.text(),/Workspace shell/);assert.equal(response.headers.get('cache-control'),'no-store');assert.match(response.headers.get('x-robots-tag'),/noindex/);assert.equal(response.headers.get('x-frame-options'),'DENY');
      const csp=response.headers.get('content-security-policy');assert.match(csp,/frame-ancestors 'none'/);if(path.startsWith('/admin'))assert(!csp.split(';')[1].includes('gstatic.com'));
    }
    assert.equal((await fetch(origin+'/login/',{method:'POST'})).status,405);
    assert.equal((await fetch(origin+'/app/',{redirect:'manual'})).headers.get('location'),'/app/android/');
  }finally{server.closeAllConnections();await new Promise(done=>server.close(done));assert(directory.startsWith(base+sep));await rm(directory,{recursive:true,force:true});}
});

test('source renders web login, protected shells, admin entry and marketing links without building',async()=>{
  const app=await createDevelopmentServer({port:0}),origin=`http://127.0.0.1:${app.server.address().port}`;
  try{
    for(const path of ['/','/features/','/auto-apply/','/pricing/','/privacy/','/ar/','/ar/features/']){
      const response=await fetch(origin+path),html=await response.text();assert.equal(response.status,200,html);assert.match(html,path.startsWith('/ar/')?/href="\/ar\/login\/"/:/href="\/login\/"/);assert.match(html,/class="nav site-header"/);
    }
    for(const path of ['/login/','/signup/','/ar/login/','/admin/','/dashboard/','/jobs/']){
      const response=await fetch(origin+path),html=await response.text();assert.equal(response.status,200,html);assert.equal(response.headers.get('cache-control'),'no-store');assert.match(response.headers.get('x-robots-tag'),/noindex/);
      if(path==='/admin/'){assert.match(html,/Administrator sign-in/);assert.match(html,/type="password"/);}
      else if(path==='/login/'||path==='/signup/'){assert.match(html,/Continue with Google/);assert.match(html,/type="email"/);assert.match(html,/ws-app ws-login/);}
      else if(path==='/ar/login/')assert.match(html,/<html lang="ar" dir="rtl">/);
      else{assert.match(html,/Opening your workspace/);assert.doesNotMatch(html,/Gmail app password/);}
    }
    const source=await fetch(origin+'/src/main.jsx');assert.equal(source.status,200);assert.match(await source.text(),/DesktopApp/);
    assert.equal((await fetch(origin+'/not-a-page')).status,404);assert((await fetch(origin+'/.runtime/private.env')).status>=400);
  }finally{await app.close();}
});
