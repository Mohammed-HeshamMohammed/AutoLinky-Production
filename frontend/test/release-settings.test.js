import { test } from 'node:test';
import assert from 'node:assert/strict';
import { releaseSettings,latestRelease,fixedAssetUrl } from '../api/_release.js';
import download from '../api/download.js';

test('release config requires explicit secure provider URLs and repository',()=>{
  const env={RELEASES_REPO:'fixture/releases',GITHUB_API_BASE_URL:'https://api.fixture.invalid/v3',GITHUB_WEB_BASE_URL:'https://web.fixture.invalid'};
  assert.equal(releaseSettings(env).api,'https://api.fixture.invalid/v3');assert.equal(releaseSettings({}),null);
  for(const url of ['http://api.invalid','https://user:secret@api.invalid','https://api.invalid/?token=private'])assert.equal(releaseSettings({...env,GITHUB_API_BASE_URL:url}),null);
});

test('release tokens reach only the configured API, redirects are blocked and cache is scoped to configuration',async()=>{
  Object.assign(process.env,{RELEASES_REPO:'fixture/first',GITHUB_API_BASE_URL:'https://api.fixture.invalid',GITHUB_WEB_BASE_URL:'https://web.fixture.invalid',GITHUB_TOKEN:'private-test-token'});
  const original=globalThis.fetch,calls=[];
  globalThis.fetch=async(url,options)=>{
    calls.push({url,...options});
    if(String(url).startsWith('https://api.fixture.invalid')){assert.equal(options.headers.Authorization,'Bearer private-test-token');assert.equal(options.redirect,'error');return new Response('',{status:503});}
    assert.equal(options.headers.Authorization,undefined);
    if(String(url).endsWith('/latest'))return new Response('',{status:302,headers:{location:'https://web.fixture.invalid/fixture/first/releases/tag/v1'}});
    return new Response('<a href="/fixture/first/releases/download/v1/app.apk">APK</a>');
  };
  try{
    assert.equal((await latestRelease()).url,'https://web.fixture.invalid/fixture/first/releases/download/v1/app.apk');
    const count=calls.length;await latestRelease();assert.equal(calls.length,count);
    process.env.RELEASES_REPO='fixture/second';assert.equal(await latestRelease({cachedOnly:true}),null);
    process.env.APK_FIXED_NAME='installer.apk';assert.equal(fixedAssetUrl(),'https://web.fixture.invalid/fixture/second/releases/latest/download/installer.apk');
    delete process.env.GITHUB_API_BASE_URL;
    let status=200;const headers={};await download({method:'GET',url:'/download',headers:{},socket:{}},{set statusCode(value){status=value;},setHeader(key,value){headers[key]=value;},end(){}});
    assert.equal(status,503);assert.equal(headers.Location,undefined);assert.equal(await latestRelease({cachedOnly:true}),null);
  }finally{globalThis.fetch=original;}
});
