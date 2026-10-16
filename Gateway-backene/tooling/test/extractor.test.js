import { test } from 'node:test';
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const worker=fileURLToPath(new URL('../../../App-backend/extractor/worker.py',import.meta.url));
function parse(bytes){const result=spawnSync(process.env.PYTHON||'python',['-B',worker],{input:bytes,timeout:15000,encoding:'buffer'});assert.equal(result.status,0,String(result.stderr));return JSON.parse(result.stdout);}
test('real Python extraction refuses empty, unsupported, oversized and malformed files',()=>{
  assert.equal(parse(Buffer.alloc(0)).error,'cv_empty');
  assert.equal(parse(Buffer.from('not a document')).error,'cv_bad_type');
  assert.equal(parse(Buffer.alloc(4194305)).error,'cv_too_large');
  assert.equal(parse(Buffer.from('%PDF-invalid')).error,'cv_unreadable');
});
test('real DOCX extraction preserves text/hyperlinks, detects ZIP expansion and computes the file hash',()=>{
  const code=`import io,zipfile,sys
out=io.BytesIO()
with zipfile.ZipFile(out,'w',zipfile.ZIP_DEFLATED) as z:
 z.writestr('word/document.xml','<w:document><w:p><w:t>Developer '+('JavaScript experience in web applications. '*10)+'</w:t></w:p></w:document>')
 z.writestr('word/_rels/document.xml.rels','<Relationships><Relationship Target="https://github.com/example" TargetMode="External"/></Relationships>')
sys.stdout.buffer.write(out.getvalue())`;
  const generated=spawnSync(process.env.PYTHON||'python',['-B','-c',code]);assert.equal(generated.status,0,String(generated.stderr));
  const {result}=parse(generated.stdout);assert.equal(result.file_type,'docx');assert.match(result.text,/Developer JavaScript/);assert.deepEqual(result.links,['https://github.com/example']);assert.match(result.sha256,/^[a-f0-9]{64}$/);
  const bomb=spawnSync(process.env.PYTHON||'python',['-B','-c',`import io,zipfile,sys
out=io.BytesIO()
with zipfile.ZipFile(out,'w',zipfile.ZIP_DEFLATED) as z:z.writestr('word/document.xml','x'*2000000)
sys.stdout.buffer.write(out.getvalue())`]);
  assert.equal(parse(bomb.stdout).error,'cv_unreadable');
});
