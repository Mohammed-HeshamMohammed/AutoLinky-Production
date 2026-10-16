import { readFile,writeFile } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import path from 'node:path';
const baseline=JSON.parse(await readFile(new URL('../../migration-plan/evidence/source-baseline.json',import.meta.url),'utf8'));
const report={checkedAt:new Date().toISOString(),workspaces:[]};
for(const [name,entry] of Object.entries(baseline)){
  const changed=[];
  for(const [relative,expected] of Object.entries(entry.files)){
    try{const actual=createHash('sha256').update(await readFile(path.join(entry.root,relative))).digest('hex');if(actual!==expected)changed.push(relative);}
    catch{changed.push(relative);}
  }
  report.workspaces.push({name,root:entry.root,filesChecked:Object.keys(entry.files).length,changed});
}
await writeFile(new URL('../../migration-plan/evidence/workspace-preservation.json',import.meta.url),JSON.stringify(report,null,2)+'\n');
for(const result of report.workspaces)console.log(`${result.name}: ${result.filesChecked} files checked, ${result.changed.length} changed`);
if(report.workspaces.some(r=>r.changed.length))process.exitCode=1;
