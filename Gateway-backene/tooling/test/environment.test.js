import { test } from 'node:test';
import assert from 'node:assert/strict';
import { AIClient } from '../../../App-backend/lib/ai/client.js';
import { AIClient as LetterAI } from '../../../Notify-backend/lib/ai/client.js';
import { gmailTransport,smtpSettings } from '../../../Notify-backend/src/email/gmail.js';
import { gatewayTargets } from '../../src/app.js';
import { loadConfig } from '../../../App-backend/lib/config.js';

test('AI credentials require explicit provider/model and never follow redirects or insecure URLs',async()=>{
  const config=loadConfig({AI_API_KEY:'private-test-ai'});assert.equal(config.aiBaseUrl,'');assert.equal(config.cvModel,'');
  for(const Client of [AIClient,LetterAI]){
    let calls=0;
    const fetcher=async(url,options)=>{calls++;assert.equal(url,'https://provider.fixture.invalid/v1/chat/completions');assert.equal(options.redirect,'error');assert.equal(options.headers.Authorization,'Bearer private-test-ai');return Response.json({choices:[{message:{content:'{"ok":true}'}}]});};
    for(const aiBaseUrl of ['', 'http://provider.invalid','https://user:secret@provider.invalid','https://provider.invalid/?key=secret'])await assert.rejects(new Client({...config,aiBaseUrl},{fetcher}).ask({model:'fixture-model',messages:[]}));
    assert.equal(calls,0);
    const client=new Client({...config,aiBaseUrl:'https://provider.fixture.invalid/v1'},{fetcher});
    await assert.rejects(client.ask({model:'',messages:[]}));assert.equal(calls,0);
    assert.deepEqual((await client.ask({model:'fixture-model',messages:[]})).data,{ok:true});assert.equal(calls,1);
  }
});

test('SMTP deployment settings preserve TLS verification and fail before any unconfigured transmission',async()=>{
  assert.throws(()=>smtpSettings({}),{kind:'smtp_configuration'});
  for(const env of [{SMTP_HOST:'host;injection',SMTP_PORT:'465',SMTP_SECURE:'true'},{SMTP_HOST:'smtp.invalid',SMTP_PORT:'0',SMTP_SECURE:'true'},{SMTP_HOST:'smtp.invalid',SMTP_PORT:'465',SMTP_SECURE:'perhaps'}])assert.throws(()=>smtpSettings(env));
  let calls=0,options,closed=false;
  const transportFactory=value=>{calls++;options=value;return {verify:async()=>true,close:()=>{closed=true;}};};
  await assert.rejects(gmailTransport({env:{},transportFactory}).verify('fixture@gmail.com','private-test-password'),{kind:'smtp_configuration'});assert.equal(calls,0);
  await gmailTransport({env:{SMTP_HOST:'smtp.fixture.invalid',SMTP_PORT:'587',SMTP_SECURE:'false'},transportFactory}).verify('fixture@gmail.com','private-test-password');
  assert.equal(options.host,'smtp.fixture.invalid');assert.equal(options.port,587);assert.equal(options.secure,false);assert.equal(options.requireTLS,true);assert.equal(options.tls.rejectUnauthorized,true);assert.equal(options.tls.minVersion,'TLSv1.2');assert.equal(options.debug,false);assert(closed);
});

test('gateway targets require configured service origins instead of silently using another environment',()=>{
  assert.throws(()=>gatewayTargets({NODE_ENV:'production',AUTH_SERVICE_KEY:'x'.repeat(40)}),/AUTH_SERVICE_URL is required/);
});
