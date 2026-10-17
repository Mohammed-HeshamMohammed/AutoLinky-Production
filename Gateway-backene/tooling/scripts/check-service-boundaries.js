import { readdir,readFile,realpath } from 'node:fs/promises';
import { resolve,relative,sep } from 'node:path';
import { fileURLToPath,pathToFileURL } from 'node:url';
import { isBuiltin } from 'node:module';
import { backendFolders } from '../support/layout.js';

export const backendNames=Object.keys(backendFolders);
const inside=(path,folder)=>path===folder||path.startsWith(folder+sep);
async function sources(folder){
  const found=[];
  for(const entry of await readdir(folder,{withFileTypes:true})){
    if(['node_modules','.runtime','__pycache__','tooling'].includes(entry.name))continue;
    const path=resolve(folder,entry.name);
    if(entry.isDirectory())found.push(...await sources(path));else if(entry.name.endsWith('.js'))found.push(path);
  }
  return found;
}

export async function inspectBoundary(root,name){
  root=await realpath(root);
  if(!Object.hasOwn(backendFolders,name))throw Error(`Unknown backend: ${name}`);
  const own=resolve(root,backendFolders[name]);
  const pkg=JSON.parse(await readFile(resolve(own,'package.json'),'utf8'));
  const pending=await sources(own),visited=new Set();
  while(pending.length){
    const file=await realpath(pending.pop());if(visited.has(file))continue;
    if(!inside(file,own)||inside(file,resolve(own,'tooling')))throw Error(`${name}: forbidden source dependency ${relative(root,file)}`);
    visited.add(file);
    const code=await readFile(file,'utf8');
    const imports=[...code.matchAll(/\b(?:from\s*|import\s*\(\s*|import\s*)['"]([^'"]+)['"]/g)];
    for(const [,specifier] of imports){
      if(specifier.startsWith('.')){
        const target=resolve(file,'..',specifier);
        if(!inside(target,own)||inside(target,resolve(own,'tooling')))throw Error(`${name}: forbidden source dependency ${relative(root,target)}`);
        if(target.endsWith('.js'))pending.push(target);
      }else if(!isBuiltin(specifier)){
        const dependency=specifier.startsWith('@')?specifier.split('/').slice(0,2).join('/'):specifier.split('/')[0];
        if(!pkg.dependencies?.[dependency])throw Error(`${name}: undeclared runtime dependency ${dependency}`);
      }
    }
  }
  const lock=JSON.parse(await readFile(resolve(own,'package-lock.json'),'utf8'));
  for(const [dependency,version] of Object.entries(pkg.dependencies||{})){
    if(lock.packages?.['']?.dependencies?.[dependency]!==version||!lock.packages?.['node_modules/'+dependency])throw Error(`${name}: runtime lock does not contain ${dependency}`);
  }
  const docker=await readFile(resolve(own,'Dockerfile'),'utf8');
  const targets=[...docker.matchAll(/^FROM\s+\S+\s+AS\s+(\S+)\s*$/gmi)].map(match=>match[1]);
  if(!targets.includes('Production'))throw Error(`${name}: Docker target Production is missing`);
  const allowed=new Set(['package.json','package-lock.json','index.js','app.js','routes.js','sender.js','reconcile.js','src','lib','database','scripts',...(name==='app'?['extractor','extractor/requirements.txt']:[])]);
  const copied=new Set();
  for(const line of docker.split(/\r?\n/).filter(line=>line.startsWith('COPY '))){
    const args=line.split(/\s+/).slice(1).filter(arg=>!arg.startsWith('--'));
    for(const source of args.slice(0,-1)){
      if(!allowed.has(source))throw Error(`${name}: image copies unowned source ${source}`);
      copied.add(source);
    }
  }
  if(!copied.has('index.js')||!copied.has('lib'))throw Error(`${name}: image is missing its owned backend`);
  if(name==='app'&&(!copied.has('extractor')||!copied.has('extractor/requirements.txt')||!docker.includes('python3 -m venv')||!docker.includes('pip install --no-cache-dir -r extractor/requirements.txt')))throw Error('app: image is missing its on-demand parser or pinned Python dependencies');
  return {name,directory:backendFolders[name],source_files:visited.size,runtime_dependencies:Object.keys(pkg.dependencies||{}),image:`autolinky-${name}:development`,docker_target:'Production'};
}

if(process.argv[1]&&pathToFileURL(resolve(process.argv[1])).href===import.meta.url){
  const root=fileURLToPath(new URL('../../../',import.meta.url));
  for(const name of backendNames)console.log(JSON.stringify(await inspectBoundary(root,name)));
  console.log('Independent backend source, runtime dependency and image boundaries passed');
}
