import { spawn,execFile } from 'node:child_process';
import { promisify } from 'node:util';
import { access,readFile,writeFile,mkdir } from 'node:fs/promises';
import { resolve,delimiter,dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const frontend=fileURLToPath(new URL('../',import.meta.url));
const shared=resolve(frontend,'../mobile apps/shared');
const exists=path=>access(path).then(()=>true,()=>false);
const candidates=[process.env.AUTOLINKY_FLUTTER_ROOT,process.env.FLUTTER_ROOT,resolve(frontend,'../.runtime/flutter-sdk'),resolve(shared,'.runtime/flutter-sdk'),
  ...(process.env.PATH||'').split(delimiter).map(path=>resolve(path,'..'))].filter(Boolean);
let sdk;
for(const candidate of candidates)if(await exists(resolve(candidate,'bin/cache/flutter_tools.snapshot'))){sdk=candidate;break;}
if(!sdk)throw Error('Install Flutter 3.47.7 and set AUTOLINKY_FLUTTER_ROOT to its SDK directory.');
const dart=resolve(sdk,'bin/cache/dart-sdk/bin',process.platform==='win32'?'dart.exe':'dart');
const snapshot=resolve(sdk,'bin/cache/flutter_tools.snapshot');
const environment={...process.env,FLUTTER_ROOT:sdk,PUB_CACHE:process.env.PUB_CACHE||resolve(frontend,'../.runtime/pub-cache'),
  FLUTTER_SUPPRESS_ANALYTICS:'true',DART_SUPPRESS_ANALYTICS:'true'};
const machine=await promisify(execFile)(dart,[snapshot,'--version','--machine'],{env:environment,windowsHide:true});
if(JSON.parse(machine.stdout).frameworkVersion!=='3.47.7')throw Error('Use the pinned Flutter 3.47.7 SDK.');
function run(command,args,cwd) {
  return new Promise((done,reject)=>{
    const child=spawn(command,args,{cwd,env:environment,stdio:'inherit',windowsHide:true});
    child.once('error',reject);child.once('exit',code=>code===0?done():reject(Error(`Frontend build failed (${code}).`)));
  });
}
const settingsFile=process.env.APP_DEFINES?resolve(process.env.APP_DEFINES):resolve(shared,'env/web.json');
const supplied=await exists(settingsFile)?JSON.parse(await readFile(settingsFile,'utf8')):{};
const registration=JSON.parse(await readFile(resolve(shared,'firebase-project.json'),'utf8'));
const allowed=new Set(Object.keys(JSON.parse(await readFile(resolve(shared,'env/example.json'),'utf8'))));
if(Object.keys(supplied).some(key=>!allowed.has(key)))throw Error('APP_DEFINES may contain only public app settings from env/example.json.');
if(supplied.FIREBASE_APP_ID&&!supplied.FIREBASE_APP_ID.includes(':web:'))throw Error('Browser builds require a Firebase web registration.');
const settings={EMAIL_SIGN_IN:'false',APPLE_SIGN_IN:'false',API_BASE_URL:'',...registration,...supplied};
if(process.env.VITE_SITE_URL) {
  settings.TERMS_URL ||= new URL('/terms/',process.env.VITE_SITE_URL).href;
  settings.PRIVACY_URL ||= new URL('/privacy/',process.env.VITE_SITE_URL).href;
}
if(process.env.APP_API_BASE_URL)settings.API_BASE_URL=process.env.APP_API_BASE_URL;
else if(process.env.VITE_SITE_URL)settings.API_BASE_URL=new URL(process.env.VITE_SITE_URL).origin;
if(settings.API_BASE_URL) {
  const api=new URL(settings.API_BASE_URL);
  if(api.username||api.password||api.search||api.hash||!(api.protocol==='https:'||(api.protocol==='http:'&&['localhost','127.0.0.1','[::1]'].includes(api.hostname))))throw Error('Use HTTPS for the app API, or HTTP localhost for development.');
}
const version=(await readFile(resolve(shared,'pubspec.yaml'),'utf8')).match(/^version:\s*(\S+)/m)?.[1];
const output=resolve(frontend,'.runtime/web-defines.json');
await mkdir(dirname(output),{recursive:true});
await writeFile(output,JSON.stringify(settings,null,2)+'\n');
await run(process.env.AUTOLINKY_PYTHON||(process.platform==='win32'?'python':'python3'),[resolve(shared,'tool/mobile_apps.py'),'--web'],frontend);
for(const platform of ['android','ios']) {
  const app=resolve(frontend,'apps',platform);
  await run(dart,[snapshot,'pub','get','--enforce-lockfile'],app);
  await run(dart,[snapshot,'build','web','--release',`--base-href=/app/${platform}/`,`--dart-define-from-file=${output}`,
    `--dart-define=WEB_APP_VARIANT=${platform}`,'--output',resolve(frontend,'dist/app',platform)],app);
}
await mkdir(resolve(frontend,'dist/app'),{recursive:true});
await writeFile(resolve(frontend,'dist/app/index.html'),'<!doctype html><html><head><meta name="robots" content="noindex"><title>Open AutoLinky</title></head><body><a href="/app/android/">Android web app</a><a href="/app/ios/">iOS web app</a></body></html>');
await writeFile(resolve(frontend,'dist/app/release.json'),JSON.stringify({version,variants:['android','ios'],source_commit:process.env.GITHUB_SHA||null,api_configured:Boolean(settings.API_BASE_URL)},null,2)+'\n');
console.log(`Built both browser app targets from shared version ${version}.`);
