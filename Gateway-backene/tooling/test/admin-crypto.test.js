import { test } from 'node:test';
import assert from 'node:assert/strict';
import { randomBytes } from 'node:crypto';
import { base32,totp,totpStep,hashPassword,verifyPassword,encryptTotp,decryptTotp,signedToken,readToken } from '../../../Auth-backend/src/admin-crypto.js';
test('administrator TOTP matches the RFC 6238 SHA-1 vector and rejects reused steps',()=>{
  const secret=base32(Buffer.from('12345678901234567890'));
  assert.equal(totp(secret,1),'287082');assert.equal(totpStep(secret,'287082',-1,59000),1);assert.equal(totpStep(secret,'287082',1,59000),null);
});
test('administrator passwords, encrypted TOTP and purpose-bound signed tokens resist wrong inputs',async()=>{
  const password='A long private fixture password',encoded=await hashPassword(password);assert(await verifyPassword(password,encoded));assert.equal(await verifyPassword('not the password',encoded),false);
  const key=randomBytes(32),secret=base32(randomBytes(20)),envelope=encryptTotp(secret,key);assert.equal(decryptTotp(envelope,key),secret);assert.throws(()=>decryptTotp(envelope,randomBytes(32)));
  const token=signedToken('key'.repeat(20),{purpose:'admin-challenge',exp:200});assert(readToken('key'.repeat(20),token,'admin-challenge',100000));assert.equal(readToken('key'.repeat(20),token,'admin-session',100000),null);assert.equal(readToken('key'.repeat(20),token,'admin-challenge',200000),null);
});
