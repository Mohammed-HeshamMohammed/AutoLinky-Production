import { before,after,test } from 'node:test';
import assert from 'node:assert/strict';
import http from 'node:http';
import download from '../api/download.js';
import latest from '../api/latest.js';
import { describe,record } from '../api/_stats.js';

const android='Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 Chrome/126.0 Mobile Safari/537.36';
const originalFetch=globalThis.fetch,rows=[];
let port,server,failStats=false,githubCalls=0;
function call(handler,{url='/download',method='GET',headers={'user-agent':android}}={}) {
  return new Promise((resolve,reject)=>{
    const res={headers:{},statusCode:200,setHeader(k,v){this.headers[k.toLowerCase()]=v;},end(body){resolve({...this,body});}};
    Promise.resolve(handler({url,method,headers,socket:{remoteAddress:'127.0.0.1'}},res)).catch(reject);
  });
}
before(async()=>{
  process.env.RELEASES_REPO='AMamdouh3/Autolinky-releases';process.env.GITHUB_API_BASE_URL='https://api.github.com';process.env.GITHUB_WEB_BASE_URL='https://github.com';
  server=http.createServer((req,res)=>{
    let body='';req.on('data',chunk=>{body+=chunk;});req.on('end',()=>{
      rows.push({path:req.url,key:req.headers['x-internal-key'],authorization:req.headers.authorization,row:JSON.parse(body)});
      res.writeHead(failStats?503:204).end();
    });
  });
  await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));port=server.address().port;
  globalThis.fetch=async(url,options)=>{
    if(String(url).startsWith('https://api.github.com/')) {
      githubCalls++;
      return new Response(JSON.stringify({tag_name:'v1.2.0+5',html_url:'https://github.com/AMamdouh3/Autolinky-releases/releases/tag/v1.2.0',published_at:'2026-10-01T00:00:00Z',assets:[{
        name:'autolinky-1.2.0+5.apk',state:'uploaded',size:123,browser_download_url:'https://github.com/AMamdouh3/Autolinky-releases/releases/download/v1.2.0/autolinky-1.2.0+5.apk',
      }]}),{status:200});
    }
    return originalFetch(url,options);
  };
});
after(async()=>{globalThis.fetch=originalFetch;await new Promise(resolve=>server.close(resolve));});
test('without a salt counting is off and a valid APK redirect still works',async()=>{
  process.env.API_BASE_URL=`http://127.0.0.1:${port}`;process.env.STATS_KEY='x'.repeat(40);delete process.env.STATS_SALT;
  const response=await call(download);
  assert.equal(response.statusCode,302);assert.match(response.headers.location,/\.apk$/);
  assert.match(response.headers['cache-control'],/s-maxage=300/);assert.equal(rows.length,0);
});
test('download statistics use the private API key and a daily hash, never a raw IP or an auth provider credential',async()=>{
  process.env.STATS_SALT='s'.repeat(40);
  const response=await call(download,{url:'/download?src=li_post-1',headers:{'user-agent':android,'x-forwarded-for':'9.9.9.9, 1.1.1.1','x-vercel-ip-country':'EG',referer:'https://www.linkedin.com/feed/?secret=x'}});
  assert.equal(response.headers['cache-control'],'no-store');
  const saved=rows.at(-1);assert.equal(saved.path,'/internal/v1/downloads');assert.equal(saved.key,'x'.repeat(40));
  assert.equal(saved.authorization,undefined);assert.equal(saved.row.source,'li_post-1');assert.equal(saved.row.country,'EG');
  assert.equal(saved.row.referrer,'www.linkedin.com');assert.match(saved.row.visitor,/^[a-f0-9]{16}$/);
  assert(!JSON.stringify(saved.row).includes('9.9.9.9'));assert(!JSON.stringify(saved.row).includes('secret=x'));
});
test('in-app Android browsers use the help page; direct bypass and HEAD preserve the original behavior',async()=>{
  const before=rows.length;
  const headers={'user-agent':android+' LinkedInApp'};
  assert.equal((await call(download,{headers})).headers.location,'/open');
  assert.equal(rows.at(-1).row.kind,'in_app_prompt');
  assert.match((await call(download,{url:'/download?direct=1',headers})).headers.location,/\.apk$/);
  await call(download,{method:'HEAD',headers});
  assert.equal(rows.length,before+2);
});
test('the release DTO is shared and cached; dependency failure never prevents downloads',async()=>{
  const dto=await call(latest);assert.equal(JSON.parse(dto.body).version,'1.2.0');assert.equal(JSON.parse(dto.body).download,'/download');
  assert.equal(githubCalls,1);
  failStats=true;
  const response=await call(download);assert.equal(response.statusCode,302);assert.match(response.headers.location,/\.apk$/);
  assert.equal(await record({headers:{}},{kind:'download'}),false);
  failStats=false;
  assert.equal((await call(download,{method:'POST'})).statusCode,405);
});
test('the source browser and device classifications remain compatible',()=>{
  assert.equal(describe(android+' LinkedInApp').inApp,'linkedin');
  assert.equal(describe('curl/8.0').isBot,true);
  assert.equal(describe('Mozilla iPhone').device,'ios');
});
