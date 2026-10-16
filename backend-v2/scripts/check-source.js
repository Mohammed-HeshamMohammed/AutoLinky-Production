import { readdir,readFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';
const root=new URL('../',import.meta.url),failures=[];
async function walk(url){for(const item of await readdir(url,{withFileTypes:true})){if(['node_modules','.runtime','__pycache__','.venv','.git'].includes(item.name))continue;const path=new URL(item.name+(item.isDirectory()?'/':''),url);if(item.isDirectory())await walk(path);else{
  const relative=fileURLToPath(path).slice(fileURLToPath(root).length).replaceAll('\\','/');
  if(/\.(tx|ts|tsx)$/.test(item.name))failures.push(`Backend must use JavaScript: ${relative}`);
  if(item.name.endsWith('.js')){
    const code=await readFile(path,'utf8');
    if(/(?:from|import\s*\()\s*['"]@supabase\//.test(code))failures.push(`Legacy runtime SDK: ${relative}`);
    const result=spawnSync(process.execPath,['--check',fileURLToPath(path)],{encoding:'utf8'});if(result.status!==0)failures.push(`JavaScript syntax: ${relative}\n${result.stderr}`);
  }
}}}
await walk(root);
const pkg=JSON.parse(await readFile(new URL('package.json',root),'utf8'));
if(Object.values(pkg.scripts).some(s=>/\b(tsc|tsx|ts-node)\b/.test(s)))failures.push('A backend TypeScript build/runtime is forbidden');
if(failures.length){console.error(failures.join('\n'));process.exitCode=1;}else console.log('Backend ESM syntax and source-boundary checks passed');
