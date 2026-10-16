import { before,after,test } from 'node:test';
import assert from 'node:assert/strict';
import pg from 'pg';
import { testDatabase } from '../helpers/database.js';
import { reconcileIdentityDeletions } from '../../../Auth-backend/src/identity-deletions.js';
let fixture,db;
before(async()=>{
  fixture=await testDatabase();
  await fixture.db.query(`ALTER ROLE autolinky_ops LOGIN PASSWORD '${fixture.password}'`);
  db=new pg.Pool({host:'127.0.0.1',port:fixture.port,user:'autolinky_ops',password:fixture.password,database:'postgres',max:4});
});
after(async()=>{await db?.end();await fixture?.close();});
test('concurrent reconciliation claims each deletion once and accepts already-deleted Firebase users',async()=>{
  await fixture.db.query("INSERT INTO public.identity_deletion_queue(firebase_uid) VALUES('one'),('already-deleted')");
  const calls=[];
  const identity={async deleteUser(uid){calls.push(uid);if(uid==='already-deleted')throw Object.assign(Error(),{code:'auth/user-not-found'});}};
  const results=await Promise.all([reconcileIdentityDeletions({db,identity}),reconcileIdentityDeletions({db,identity})]);
  assert.equal(results.reduce((sum,result)=>sum+result.completed,0),2);
  assert.deepEqual(calls.sort(),['already-deleted','one']);
  assert.equal((await db.query('SELECT count(*)::integer AS n FROM public.identity_deletion_queue WHERE completed_at IS NOT NULL')).rows[0].n,2);
  await assert.rejects(db.query("UPDATE public.identity_deletion_queue SET firebase_uid='renamed' WHERE firebase_uid='one'"),{code:'42501'});
  await assert.rejects(db.query("DELETE FROM public.identity_deletion_queue WHERE firebase_uid='one'"),{code:'42501'});
});
test('provider failure and deadline defer work; cancellation leaves unclaimed work untouched',async()=>{
  await fixture.db.query("INSERT INTO public.identity_deletion_queue(firebase_uid) VALUES('outage'),('deadline')");
  const identity={deleteUser(uid){if(uid==='outage')throw Error('synthetic provider outage');return new Promise(()=>{});}};
  const result=await reconcileIdentityDeletions({db,identity,deadlineMs:20});
  assert.equal(result.deferred,2);
  assert.equal((await db.query("SELECT count(*)::integer AS n FROM public.identity_deletion_queue WHERE completed_at IS NULL AND attempts=1 AND next_attempt_at>now()")).rows[0].n,2);
  assert.equal((await reconcileIdentityDeletions({db,identity,signal:AbortSignal.abort()})).claimed,0);
});
