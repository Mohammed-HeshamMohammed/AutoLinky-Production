import { spawn } from 'node:child_process';
import { readFile } from 'node:fs/promises';
import { parseEnv } from 'node:util';
import { resolve } from 'node:path';
import { setup,production,runtime } from './config.js';
// Explicit command only. Development startup never invokes this build.
await setup();
const website=resolve(production,'frontend'),env=parseEnv(await readFile(resolve(runtime,'website.env'),'utf8'));
for(const args of [[resolve(website,'node_modules/vite/bin/vite.js'),'build'],[resolve(website,'scripts/prerender.mjs')],[resolve(website,'scripts/verify-build.mjs')]]){
  await new Promise((done,reject)=>{
    const child=spawn(process.execPath,args,{cwd:website,env:{...process.env,...env},stdio:'inherit',windowsHide:true});
    child.once('error',reject);child.once('exit',code=>code===0?done():reject(Error(`React web build failed (${code})`)));
  });
}
console.log('Responsive React web frontend is ready.');
