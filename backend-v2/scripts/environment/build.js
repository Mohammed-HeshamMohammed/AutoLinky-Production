import { spawn } from 'node:child_process';
import { resolve } from 'node:path';
import { setup,backend,production,runtime,exists } from './config.js';
const settings=await setup();
const client=resolve(production,'mobile apps/shared'),website=resolve(production,'frontend-v2');
function run(command,args,cwd,env={}) {
  return new Promise((done,reject)=>{
    const child=spawn(command,args,{cwd,env:{...process.env,...env},stdio:'inherit',windowsHide:true});
    child.on('error',reject);child.on('exit',code=>code===0?done():reject(Error(`Environment build failed (${code})`)));
  });
}
const sdk=resolve(production,'.runtime/flutter-sdk');
const dart=resolve(sdk,process.platform==='win32'?'bin/cache/dart-sdk/bin/dart.exe':'bin/cache/dart-sdk/bin/dart');
const snapshot=resolve(sdk,'bin/cache/flutter_tools.snapshot');
if(!await exists(dart)||!await exists(snapshot))throw Error('Install Flutter 3.47.7 in .runtime/flutter-sdk first; see ENVIRONMENT.md');
const websiteBuild={VITE_SITE_URL:`http://localhost:${settings.ports.website}`,VITE_WHATSAPP_NUMBER:'201060933358',
  AUTOLINKY_FLUTTER_ROOT:sdk,PUB_CACHE:resolve(production,'.runtime/pub-cache'),APP_DEFINES:resolve(runtime,'flutter-web.json')};
await run(process.execPath,[resolve(website,'node_modules/vite/bin/vite.js'),'build'],website,websiteBuild);
await run(process.execPath,[resolve(website,'scripts/prerender.mjs')],website,websiteBuild);
await run(process.execPath,[resolve(website,'scripts/build-apps.mjs')],website,websiteBuild);
await run(process.execPath,[resolve(website,'scripts/verify-build.mjs')],website,websiteBuild);
console.log('Unified landing site and both browser apps are ready.');
