import { readdir,readFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';
import { relative } from 'node:path';
import { backendFolders } from '../support/layout.js';
const root=new URL('../',import.meta.url),failures=[];
async function walk(url){for(const item of await readdir(url,{withFileTypes:true})){if(['node_modules','.runtime','__pycache__','.venv','.git','tooling'].includes(item.name))continue;const path=new URL(item.name+(item.isDirectory()?'/':''),url);if(item.isDirectory())await walk(path);else{
  const label=relative(fileURLToPath(new URL('../../',root)),fileURLToPath(path)).replaceAll('\\','/');
  if(/\.(tx|ts|tsx)$/.test(item.name))failures.push(`Backend must use JavaScript: ${label}`);
  if(item.name.endsWith('.js')){
    const code=await readFile(path,'utf8');
    if(/(?:from|import\s*\()\s*['"]@supabase\//.test(code))failures.push(`Legacy runtime SDK: ${label}`);
    const result=spawnSync(process.execPath,['--check',fileURLToPath(path)],{encoding:'utf8'});if(result.status!==0)failures.push(`JavaScript syntax: ${label}\n${result.stderr}`);
  }
}}}
for(const folder of [root,...Object.values(backendFolders).map(name=>new URL(`../../${name}/`,root))]){
  await walk(folder);
  const pkg=JSON.parse(await readFile(new URL('package.json',folder),'utf8'));
  if(Object.values(pkg.scripts).some(s=>/\b(tsc|tsx|ts-node)\b/.test(s)))failures.push(`A backend TypeScript build/runtime is forbidden: ${pkg.name}`);
}
if(failures.length){console.error(failures.join('\n'));process.exitCode=1;}else console.log('Backend ESM syntax and source-boundary checks passed');
