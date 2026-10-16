import { readdir,readFile,realpath } from 'node:fs/promises';
import { resolve,relative,sep } from 'node:path';
import { fileURLToPath,pathToFileURL } from 'node:url';
import { isBuiltin } from 'node:module';

export const backendNames=['gateway','auth','app','messaging','fetching','data'];
const inside=(path,folder)=>path===folder||path.startsWith(folder+sep);
async function sources(folder){
  const found=[];
  for(const entry of await readdir(folder,{withFileTypes:true})){
    if(['node_modules','.runtime','__pycache__'].includes(entry.name))continue;
    const path=resolve(folder,entry.name);
    if(entry.isDirectory())found.push(...await sources(path));else if(entry.name.endsWith('.js'))found.push(path);
  }
  return found;
}

export async function inspectBoundary(root,name){
  root=await realpath(root);
  const own=resolve(root,'services',name),shared=resolve(root,'shared'),database=resolve(root,'database');
  const pkg=JSON.parse(await readFile(resolve(own,'package.json'),'utf8'));
  const pending=await sources(own),visited=new Set();
  while(pending.length){
    const file=await realpath(pending.pop());if(visited.has(file))continue;
    if(![own,shared,database].some(folder=>inside(file,folder)))throw Error(`${name}: forbidden source dependency ${relative(root,file)}`);
    visited.add(file);
    const code=await readFile(file,'utf8');
    const imports=[...code.matchAll(/\b(?:from\s*|import\s*\(\s*|import\s*)['"]([^'"]+)['"]/g)];
    for(const [,specifier] of imports){
      if(specifier.startsWith('.')){
        const target=resolve(file,'..',specifier);
        if(![own,shared,database].some(folder=>inside(target,folder)))throw Error(`${name}: forbidden source dependency ${relative(root,target)}`);
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
  for(const match of docker.matchAll(/services\/([a-z-]+)/g))if(match[1]!==name)throw Error(`${name}: image copies another backend`);
  return {name,source_files:visited.size,runtime_dependencies:Object.keys(pkg.dependencies||{}),image:`autolinky-${name}:development`};
}

if(process.argv[1]&&pathToFileURL(resolve(process.argv[1])).href===import.meta.url){
  const root=fileURLToPath(new URL('../',import.meta.url));
  for(const name of backendNames)console.log(JSON.stringify(await inspectBoundary(root,name)));
  console.log('Independent backend source, runtime dependency and image boundaries passed');
}
