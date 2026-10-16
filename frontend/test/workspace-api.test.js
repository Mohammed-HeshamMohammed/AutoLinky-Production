import { test } from 'node:test';
import assert from 'node:assert/strict';
import { createClient,safeExternal } from '../src/workspace/api.js';
import { applicationChannels } from '../src/workspace/job-actions.js';
test('desktop API preserves binary uploads and never retries uncertain mutations',async()=>{
  let calls=0,last;
  const client=createClient({getToken:async()=>'fixture-token',getAdminSession:async()=>'fixture-assurance',fetcher:async(path,options)=>{calls++;last={path,...options};return new Response(JSON.stringify({ok:true}),{status:200});}});
  const cv=new Uint8Array([1,2,3]);await client('/v1/cv',{method:'POST',body:cv,headers:{'Content-Type':'application/pdf'}});
  assert.equal(last.body,cv);assert.equal(last.credentials,'omit');assert.equal(last.redirect,'error');assert.equal(last.headers.Authorization,'Bearer fixture-token');
  assert.equal(last.headers['X-Admin-Session'],'fixture-assurance');
  await assert.rejects(client('https://untrusted.invalid/v1/me'));assert.equal(calls,1);
  const offline=createClient({fetcher:async()=>{calls++;throw Error('lost connection');}});
  await assert.rejects(offline('/v1/applications',{method:'POST',body:{}}),error=>error.uncertain===true);assert.equal(calls,2);
  await assert.rejects(offline('/v1/me'),error=>error.uncertain===false);assert.equal(calls,3);
  assert.equal(safeExternal('javascript:alert(1)'),null);assert.equal(safeExternal('https://name:secret@example.com'),null);assert.equal(safeExternal('https://example.com/job'),'https://example.com/job');
  const channels=applicationChannels({title:'Engineer',apply_methods:['email','phone','whatsapp','link','dm'],contacts:[{type:'phone',value:'+201000000000'},{type:'link',value:'javascript:alert(1)'}],author_url:'https://example.com/recruiter'});
  assert.deepEqual(channels.map(item=>item.method),['whatsapp','dm']);assert.match(channels[0].href,/^https:\/\/wa.me\/201000000000\?text=/);
  assert.deepEqual(applicationChannels({apply_methods:['whatsapp'],contacts:[{type:'whatsapp',value:'12'}]}),[]);
});
