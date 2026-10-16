import assert from 'node:assert/strict';
import { readFile,writeFile } from 'node:fs/promises';
import { parseEnv } from 'node:util';
import { resolve } from 'node:path';
import { readSettings,runtime } from './config.js';
import './status.js';
const settings=await readSettings(),env=parseEnv(await readFile(resolve(runtime,'backend.env'),'utf8'));
const api=`http://127.0.0.1:${settings.ports.api}`,client=`http://localhost:${settings.ports.website}`;
const response=await fetch(api+'/v1/me',{method:'OPTIONS',headers:{Origin:client,'Access-Control-Request-Method':'GET','Access-Control-Request-Headers':'authorization,x-autolinky-client-version'}});
assert.equal(response.status,204);assert.equal(response.headers.get('access-control-allow-origin'),client);
assert.equal((await fetch(api+'/v1/me')).status,401);
assert.equal((await fetch(api+'/health',{headers:{Origin:'https://untrusted.example.invalid'}})).status,403);
const cv=await fetch(`http://127.0.0.1:${settings.ports.extractor}/extract`,{method:'POST',headers:{'X-Extractor-Key':env.CV_EXTRACTOR_KEY},body:Buffer.alloc(0)});
assert.equal(cv.status,400);assert.deepEqual(await cv.json(),{detail:'cv_empty'});
for(const platform of ['android','ios']) {
  assert.equal((await fetch(client+`/app/${platform}/welcome/email/verify`)).status,200);
  assert.equal((await fetch(client+`/app/${platform}/missing.js`)).status,404);
}
assert.equal((await fetch(client+'/')).status,200);
const report={checked_at:new Date().toISOString(),result:'passed',checks:['service readiness','native database connectivity','client CORS','private API authorization','untrusted origin refusal','bounded extractor request','client route fallback','missing asset 404'],production_data_imported:false};
await writeFile(resolve(runtime,'verification.json'),JSON.stringify(report,null,2)+'\n');
console.log('Live local environment checks passed.');
