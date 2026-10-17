import { test } from 'node:test';
import assert from 'node:assert/strict';
import { createSiteServer } from '../server.js';
import { publicSettings,availablePublicSettings } from '../public-settings.js';
import { workspaceHeaders } from '../workspace-headers.js';

export const publicEnv={PUBLIC_FIREBASE_API_KEY:'public-fixture',PUBLIC_FIREBASE_PROJECT_ID:'fixture-project',PUBLIC_FIREBASE_AUTH_DOMAIN:'auth.fixture.invalid',PUBLIC_FIREBASE_STORAGE_BUCKET:'fixture.storage.invalid',PUBLIC_FIREBASE_MESSAGING_SENDER_ID:'123',PUBLIC_FIREBASE_APP_ID:'1:123:web:fixture',PUBLIC_FIREBASE_SDK_BASE_URL:'https://sdk.fixture.invalid/firebase/'};

test('runtime config exposes only the explicit public allowlist, supports updates and never caches secrets',async()=>{
  const env={...publicEnv,AI_API_KEY:'private-ai-marker',GITHUB_TOKEN:'private-github-marker',GOOGLE_APPLICATION_CREDENTIALS:'private-path-marker',PUBLIC_ADMIN_SECRET:'private-prefix-marker'};
  const server=createSiteServer({env});await new Promise(done=>server.listen(0,'127.0.0.1',done));const origin=`http://127.0.0.1:${server.address().port}`;
  try{
    const response=await fetch(origin+'/api/config');assert.equal(response.status,200);assert.equal(response.headers.get('cache-control'),'no-store');
    const body=await response.text();assert(!body.includes('private-'));assert.deepEqual(JSON.parse(body),publicSettings(publicEnv));
    env.PUBLIC_FIREBASE_PROJECT_ID='next-project';assert.equal((await (await fetch(origin+'/api/config')).json()).firebase.projectId,'next-project');
    assert.equal(await (await fetch(origin+'/api/config',{method:'HEAD'})).text(),'');
    assert.equal((await fetch(origin+'/api/config',{method:'POST'})).status,405);
    delete env.PUBLIC_FIREBASE_API_KEY;
    const missing=await fetch(origin+'/api/config');assert.equal(missing.status,503);assert.deepEqual(await missing.json(),{error:'public_configuration_unavailable'});
  }finally{server.closeAllConnections();await new Promise(done=>server.close(done));}
});

test('public configuration rejects script injection and credential URLs; CSP follows validated runtime origins',()=>{
  for(const changes of [{PUBLIC_FIREBASE_APP_ID:'1:123:ios:fixture'},{PUBLIC_FIREBASE_APP_ID:'1:456:web:fixture'},{PUBLIC_FIREBASE_MEASUREMENT_ID:'private-value'},{PUBLIC_FIREBASE_AUTH_DOMAIN:"auth.invalid; script-src *"},{PUBLIC_FIREBASE_SDK_BASE_URL:'javascript:alert(1)'},{PUBLIC_FIREBASE_SDK_BASE_URL:'https://name:secret@sdk.invalid/'},{PUBLIC_FIREBASE_SDK_BASE_URL:'https://sdk.invalid/?key=private'},{PUBLIC_FIREBASE_SDK_BASE_URL:'http://sdk.invalid/'}])assert.equal(availablePublicSettings({...publicEnv,...changes}),null);
  assert.equal(publicSettings({...publicEnv,PUBLIC_FIREBASE_MEASUREMENT_ID:'G-FIXTURE123'}).firebase.measurementId,'G-FIXTURE123');
  const csp=workspaceHeaders({settings:publicSettings(publicEnv)})['Content-Security-Policy'];
  assert.match(csp,/script-src 'self' https:\/\/apis.google.com https:\/\/sdk.fixture.invalid;/);assert.match(csp,/frame-src https:\/\/accounts.google.com https:\/\/auth.fixture.invalid;/);
  assert(!csp.includes('auto-linky'));assert(!workspaceHeaders()['Content-Security-Policy'].includes('sdk.fixture.invalid'));
});
