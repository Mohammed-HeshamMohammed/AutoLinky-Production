import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { spawnSync } from 'node:child_process';
import { randomBytes } from 'node:crypto';
import { fileURLToPath } from 'node:url';
import { normalize } from '../src/shared/text.js';
import { SkillMatcher,RoleMatcher } from '../src/shared/skillmatch.js';
import { titleKey } from '../src/ai/cv-analysis.js';
import { encryptSecret,decryptSecret } from '../src/email/secret.js';
import { MemoryCache } from '../src/cache/memory.js';
import fc from 'fast-check';
const fixture=JSON.parse(await readFile(new URL('./fixtures/text-parity.json',import.meta.url)));
test('normalization, search-title keys, skills and role tie-breaking match the pinned Python output',()=>{
  for(const row of fixture.normalization)assert.equal(normalize(row.text),row.expected,row.text);
  for(const row of fixture.titles)assert.equal(titleKey(row.text),row.expected,row.text);
  const skills=new SkillMatcher([['javascript',['JavaScript','js']],['react',['=React']],['dotnet',['.NET','dotnet']],['c_lang',['C']]]);
  for(const row of fixture.skills){assert.deepEqual(skills.extract(row.text),row.extract,row.text);assert.equal(skills.lookup(row.text),row.lookup,row.text);}
  const roles=new RoleMatcher([['software',['developer','software engineer']],['network',['network engineer']],['sales',['sales engineer']]]);
  for(const row of fixture.roles)assert.equal(roles.match(row.text),row.expected,row.text);
});
test('Fernet reads Python-encrypted secrets, writes Python-readable secrets, rotates keys and rejects tampering',async()=>{
  const fixture=JSON.parse(await readFile(new URL('./fixtures/fernet.json',import.meta.url)));
  assert.equal(decryptSecret(fixture.token,fixture.key),fixture.plaintext);
  const next=randomBytes(32).toString('base64').replaceAll('+','-').replaceAll('/','_'),rotated=`${next},${fixture.key}`;
  assert.equal(decryptSecret(fixture.token,rotated),fixture.plaintext);
  const token=encryptSecret(fixture.plaintext,rotated);assert.equal(decryptSecret(token,next),fixture.plaintext);
  const result=spawnSync(process.env.PYTHON||'python',['-B','-c','import sys,json;from cryptography.fernet import Fernet;x=json.load(sys.stdin);print(Fernet(x["key"].encode()).decrypt(x["token"].encode()).decode())'],{input:JSON.stringify({key:next,token}),encoding:'utf8',env:{...process.env,PYTHONPATH:fileURLToPath(new URL('../.runtime/python-deps/',import.meta.url))}});
  assert.equal(result.status,0,result.stderr);assert.equal(result.stdout.trim(),fixture.plaintext);
  const bytes=Buffer.from(token,'base64url');bytes[30]^=1;assert.throws(()=>decryptSecret(bytes.toString('base64url'),rotated));
});
test('cache collapses concurrent loads, clones shared results, expires values and evicts within byte/entry budgets',async()=>{
  let now=0,calls=0;const cache=new MemoryCache({maxEntries:2,maxBytes:1024,now:()=>now});
  const loader=async()=>{calls++;return {items:[1]};};
  const [a,b]=await Promise.all([cache.load('x',10,loader),cache.load('x',10,loader)]);assert.equal(calls,1);a.items.push(2);assert.deepEqual(b.items,[1]);assert.deepEqual(cache.get('x').items,[1]);
  now=11;assert.equal(cache.get('x'),undefined);cache.set('a',1,100);cache.set('b',2,100);cache.set('c',3,100);assert.equal(cache.entries.size,2);assert.ok(cache.bytes<=1024);
});
test('normalization is idempotent and Fernet round-trips arbitrary short text',()=>{
  fc.assert(fc.property(fc.string({maxLength:200}),value=>normalize(normalize(value))===normalize(value)),{numRuns:300});
  const key=randomBytes(32).toString('base64url');fc.assert(fc.property(fc.string({maxLength:200}),value=>decryptSecret(encryptSecret(value,key),key)===value),{numRuns:100});
});
