import { readFile,writeFile } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import path from 'node:path';
import { execFileSync } from 'node:child_process';
const baseline=JSON.parse(await readFile(new URL('../../migration-plan/evidence/source-baseline.json',import.meta.url),'utf8'));
const report={checkedAt:new Date().toISOString(),workspaces:[]};
for(const [name,entry] of Object.entries(baseline)){
  const changed=[];
  for(const [relative,expected] of Object.entries(entry.files)){
    try{
      // The owner authorized replacing frontend/ and the root README. Verify
      // their exact original bytes from the retained baseline Git commit.
      const authorized=name==='production-existing'&&(relative.startsWith('frontend/')||relative==='README.md');
      const bytes=authorized?execFileSync('git',['show',`${entry.commit}:${relative}`],{cwd:entry.root,maxBuffer:20*1024*1024}):await readFile(path.join(entry.root,relative));
      const actual=createHash('sha256').update(bytes).digest('hex');
      // Baseline hashes were captured from the Windows working tree. Git may
      // store LF bytes; reconstruct its original CRLF checkout when needed.
      if(actual!==expected&&(!authorized||createHash('sha256').update(bytes.toString('utf8').replace(/\r?\n/g,'\r\n')).digest('hex')!==expected))changed.push(relative);
    }
    catch{changed.push(relative);}
  }
  report.workspaces.push({name,root:entry.root,filesChecked:Object.keys(entry.files).length,changed,...(name==='production-existing'?{preservation:'Original frontend and README retained in baseline Git commit; canonical frontend replacement authorized by owner',baseline_commit:entry.commit}:{})});
}
await writeFile(new URL('../../migration-plan/evidence/workspace-preservation.json',import.meta.url),JSON.stringify(report,null,2)+'\n');
for(const result of report.workspaces)console.log(`${result.name}: ${result.filesChecked} files checked, ${result.changed.length} changed`);
if(report.workspaces.some(r=>r.changed.length))process.exitCode=1;
