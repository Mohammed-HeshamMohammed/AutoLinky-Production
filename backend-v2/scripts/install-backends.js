import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { backendFolders } from '../shared/layout.js';

// Run through npm so its exact CLI is available on Windows as well as Linux.
if(!process.env.npm_execpath)throw Error('Run npm run install:backends from backend-v2/');
for(const folder of Object.values(backendFolders)){
  console.log(`Installing pinned runtime dependencies for ${folder}`);
  const result=spawnSync(process.execPath,[process.env.npm_execpath,'ci','--omit=dev','--ignore-scripts','--no-audit','--no-fund'],{
    cwd:fileURLToPath(new URL(`../../${folder}/`,import.meta.url)),stdio:'inherit',windowsHide:true,
  });
  if(result.error)throw result.error;
  if(result.status!==0)process.exit(result.status||1);
}
