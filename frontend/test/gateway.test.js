import { test } from 'node:test';
import assert from 'node:assert/strict';
import http from 'node:http';
import { createSiteServer } from '../server.js';

test('landing origin proxies app API bytes and auth without exposing private operations',async()=>{
  const calls=[];
  const gateway=http.createServer(async(req,res)=>{
    const chunks=[];for await(const part of req)chunks.push(part);
    calls.push({url:req.url,headers:req.headers,body:Buffer.concat(chunks)});
    res.writeHead(201,{'Content-Type':'application/json','X-Request-ID':'test-gateway'}).end(JSON.stringify({ok:true}));
  });
  await new Promise(done=>gateway.listen(0,'127.0.0.1',done));
  const site=createSiteServer({apiOrigin:`http://127.0.0.1:${gateway.address().port}`});
  await new Promise(done=>site.listen(0,'127.0.0.1',done));
  const origin=`http://127.0.0.1:${site.address().port}`;
  try{
    const bytes=Buffer.from([0,255,2,3]);
    const response=await fetch(origin+'/v1/cv?name=test.pdf',{method:'POST',body:bytes,headers:{'content-type':'application/pdf',authorization:'Bearer example','x-service-key':'must-not-forward'}});
    assert.equal(response.status,201);assert.equal(response.headers.get('cache-control'),'no-store');assert.equal(response.headers.get('x-request-id'),'test-gateway');
    assert.equal(calls[0].url,'/v1/cv?name=test.pdf');assert.deepEqual(calls[0].body,bytes);assert.equal(calls[0].headers.authorization,'Bearer example');assert.equal(calls[0].headers['x-service-key'],undefined);
    const before=calls.length;assert.equal((await fetch(origin+'/internal/v1/session',{method:'POST',body:'{}'})).status,405);assert.equal(calls.length,before);
    assert.equal((await fetch(origin+'/health')).status,201);
    const admin=await fetch(origin+'/admin/api/users/fixture',{method:'PUT',headers:{authorization:'Bearer admin-fixture','x-admin-elevation':'confirmed-fixture','content-type':'application/json','x-service-key':'forged','cookie':'do-not-forward=1'},body:'{"patch":{"status":"blocked"}}'});
    assert.equal(admin.status,201);assert.match(admin.headers.get('x-robots-tag'),/noindex/);
    const forwarded=calls.at(-1);assert.equal(forwarded.url,'/admin/api/users/fixture');assert.equal(forwarded.headers.authorization,'Bearer admin-fixture');assert.equal(forwarded.headers['x-admin-elevation'],'confirmed-fixture');assert.equal(forwarded.headers.cookie,undefined);assert.equal(forwarded.headers['x-service-key'],undefined);
  }finally{await Promise.all([new Promise(done=>site.close(done)),new Promise(done=>gateway.close(done))]);}
});
