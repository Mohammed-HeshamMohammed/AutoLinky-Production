import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readdir,readFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import { resolve,relative } from 'node:path';

test('frontend source and Docker build are independent of native projects and toolchains',async()=>{
  const root=fileURLToPath(new URL('../',import.meta.url)),files=[];
  async function walk(directory){for(const entry of await readdir(directory,{withFileTypes:true})){
    if(['node_modules','.runtime','dist','output','.git'].includes(entry.name))continue;
    const path=resolve(directory,entry.name);if(entry.isDirectory())await walk(path);else files.push(path);
  }}
  await walk(root);
  for(const path of files){
    assert(!/\.(dart|swift|kt|kts|gradle|pbxproj)$|(?:^|[\\/])pubspec\.(yaml|lock)$|google-services\.json$|GoogleService-Info\.plist$/.test(path),'Native source in frontend: '+relative(root,path));
    if(/\.(js|jsx|mjs)$/.test(path)&&!relative(root,path).startsWith('test'))assert(!/(?:from\s*|import\s*\(|new URL\s*\()[^;\n]*mobile apps/.test(await readFile(path,'utf8')),'Native import from frontend: '+relative(root,path));
  }
  const pkg=JSON.parse(await readFile(resolve(root,'package.json'),'utf8')),docker=await readFile(resolve(root,'Dockerfile'),'utf8');
  assert(pkg.dependencies.react&&pkg.dependencies['react-dom']);assert(!/flutter|dart|swift|xcode|mobile apps/i.test(JSON.stringify(pkg.scripts)+docker));
  for(const line of docker.split(/\r?\n/).filter(line=>/^COPY /.test(line)&&!line.includes('--from=')))assert(line.startsWith('COPY frontend/'),'Docker input outside React frontend: '+line);
  assert.match(docker,/FROM runtime AS Production/);
});
