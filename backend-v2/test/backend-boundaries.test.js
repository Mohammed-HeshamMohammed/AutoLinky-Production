import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdir,writeFile,rm } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import { randomBytes } from 'node:crypto';
import { backendNames,inspectBoundary } from '../scripts/check-service-boundaries.js';

test('production backends import only owned code/shared libraries and declare their own runtime dependencies',async()=>{
  const root=fileURLToPath(new URL('../../',import.meta.url));
  const results=await Promise.all(backendNames.map(name=>inspectBoundary(root,name)));
  assert.equal(results.length,6);
  assert.deepEqual(results.filter(result=>result.runtime_dependencies.includes('firebase-admin')).map(r=>r.name),['auth']);
  assert.deepEqual(results.filter(result=>result.runtime_dependencies.includes('nodemailer')).map(r=>r.name),['messaging']);
});
test('a backend importing another backend implementation is rejected',async()=>{
  const root=new URL(`../.runtime/boundary-test-${randomBytes(8).toString('hex')}/`,import.meta.url);
  assert(root.href.startsWith(new URL('../.runtime/',import.meta.url).href)&&/boundary-test-[a-f0-9]{16}\/$/.test(root.href));
  await mkdir(new URL('Auth-backend/',root),{recursive:true});
  try{
    await writeFile(new URL('Auth-backend/package.json',root),JSON.stringify({type:'module',dependencies:{}}));
    await writeFile(new URL('Auth-backend/index.js',root),"import '../Notify-backend/app.js';\n");
    await assert.rejects(inspectBoundary(fileURLToPath(root),'auth'),/forbidden source dependency/);
  }finally{
    assert(root.href.startsWith(new URL('../.runtime/',import.meta.url).href)&&/boundary-test-[a-f0-9]{16}\/$/.test(root.href));
    await rm(root,{recursive:true,force:true});
  }
});
