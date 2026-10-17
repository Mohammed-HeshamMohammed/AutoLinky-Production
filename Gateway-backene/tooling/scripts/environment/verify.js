import assert from 'node:assert/strict';
import { writeFile } from 'node:fs/promises';
import { resolve } from 'node:path';
import { readSettings,runtime } from './config.js';
import './status.js';
import { extractCV } from '../../../../App-backend/src/cv-extractor.js';
const settings=await readSettings();
const api=`http://127.0.0.1:${settings.ports.api}`,client=`http://localhost:${settings.ports.website}`;
const response=await fetch(api+'/v1/me',{method:'OPTIONS',headers:{Origin:client,'Access-Control-Request-Method':'GET','Access-Control-Request-Headers':'authorization,x-autolinky-client-version'}});
assert.equal(response.status,204);assert.equal(response.headers.get('access-control-allow-origin'),client);
assert.equal((await fetch(api+'/v1/me')).status,401);
assert.equal((await fetch(api+'/health',{headers:{Origin:'https://untrusted.example.invalid'}})).status,403);
await assert.rejects(extractCV(Buffer.from('%PDF-invalid'),{cvMaxBytes:4*1024*1024}),{status:422,detail:'cv_unreadable'});
for(const platform of ['android','ios']) {
  const redirect=await fetch(client+`/app/${platform}/welcome/email/verify?oobCode=fixture`,{redirect:'manual'});
  assert.equal(redirect.status,302);assert.equal(redirect.headers.get('location'),'/login/?oobCode=fixture');
  assert.equal((await fetch(client+`/app/${platform}/missing.js`)).status,404);
}
assert.equal((await fetch(client+'/')).status,200);
assert.equal((await fetch(client+'/login/')).status,200);
for(const name of ['auth','app','messaging'])assert.equal((await fetch(`http://127.0.0.1:${settings.ports[name]}/v1/me`)).status,401);
assert.equal((await fetch(api+'/internal/v1/session',{method:'POST',headers:{'Content-Type':'application/json'},body:'{}'})).status,404);
for(const name of ['fetching','data'])assert.equal((await fetch(`http://127.0.0.1:${settings.ports[name]}/internal/v1/data/status`)).status,401);
const report={checked_at:new Date().toISOString(),result:'passed',checks:['service readiness','native database connectivity','client CORS','private API authorization','untrusted origin refusal','on-demand local CV worker','React routes and compatibility redirects','missing asset 404'],production_data_imported:false};
await writeFile(resolve(runtime,'verification.json'),JSON.stringify(report,null,2)+'\n');
console.log('Live local environment checks passed.');
