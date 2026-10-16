import { test, before, after } from 'node:test';
import assert from 'node:assert/strict';
import { randomUUID } from 'node:crypto';
import { testDatabase, asRole } from '../helpers/database.js';
import { checkMigrations, migrate } from '../../../../Data-baceknd/database/migrate.js';

let cluster, db;
before(async () => { cluster = await testDatabase(); db = cluster.db; });
after(async () => { await cluster?.close(); });

test('native PostgreSQL 17 baseline installs idempotently and runtime roles see the checksum/fingerprint', async () => {
  assert.match((await db.query('SELECT version() v')).rows[0].v, /PostgreSQL 17/);
  await migrate(db);
  for (const role of ['api','collector','sender','ops','admin']) await asRole(db,`autolinky_${role}`,checkMigrations);
  const forbidden = await db.query("SELECT nspname FROM pg_namespace WHERE nspname IN ('auth','storage')");
  assert.equal(forbidden.rowCount,0);
  assert.equal((await db.query("SELECT FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname='public' AND c.relrowsecurity")).rowCount,0);
});

test('least privilege: collector cannot read private CV/mail, API cannot change settings or audit, admin audit is immutable', async () => {
  for (const [role,sql] of [
    ['collector','SELECT * FROM public.user_cv_files'], ['collector','SELECT * FROM public.mail_accounts'],
    ['collector',"SELECT public.delete_user_data(gen_random_uuid())"],
    ['api',"INSERT INTO public.app_settings VALUES('x','{}',now(),null)"],
    ['api','SELECT * FROM public.admin_accounts'], ['admin','DELETE FROM public.admin_log'],
  ]) await assert.rejects(asRole(db,`autolinky_${role}`,c => c.query(sql)),{code:'42501'});
});

test('Firebase UID is opaque and unique; user deletion removes internal data and preserves subscriptions', async () => {
  const id=randomUUID(), uid='firebase-opaque:not-a-uuid';
  await db.query("INSERT INTO app_users(id,email,firebase_uid) VALUES($1,'test@example.com',$2)",[id,uid]);
  await db.query("INSERT INTO user_profiles(user_id,search_titles) VALUES($1,ARRAY['Network Engineer'])",[id]);
  await db.query("INSERT INTO subscriptions(email) VALUES('test@example.com')");
  await db.query("INSERT INTO applications(user_id,opportunity_id,method,status,job) VALUES($1,$2,'email','sending','{}')",[id,randomUUID()]);
  await assert.rejects(db.query('SELECT delete_user_data($1)',[id]),/deletion_blocked/);
  await db.query("UPDATE applications SET status='sent' WHERE user_id=$1",[id]);
  await asRole(db,'autolinky_api',c => c.query('SELECT delete_user_data($1)',[id]));
  assert.equal((await db.query('SELECT FROM user_profiles WHERE user_id=$1',[id])).rowCount,0);
  assert.equal((await db.query('SELECT FROM applications WHERE user_id=$1',[id])).rowCount,0);
  assert.equal((await db.query('SELECT FROM identity_deletion_queue WHERE firebase_uid=$1',[uid])).rowCount,1);
  assert.equal((await db.query("SELECT FROM subscriptions WHERE email='test@example.com'")).rowCount,1);
});

test('rate limit retention runs outside the request path and touch_app_user avoids unnecessary last-seen changes', async () => {
  const id=randomUUID();
  await db.query('INSERT INTO app_users(id) VALUES($1)',[id]);
  const before=(await db.query('SELECT last_seen_at FROM app_users WHERE id=$1',[id])).rows[0].last_seen_at;
  await asRole(db,'autolinky_api',async c => {
    assert.equal((await c.query('SELECT touch_app_user($1,$2) status',[id,'new@example.com'])).rows[0].status,'active');
    assert.equal((await c.query("SELECT api_hit('test',60,1) retry")).rows[0].retry,0);
    assert.ok((await c.query("SELECT api_hit('test',60,1) retry")).rows[0].retry>0);
  });
  assert.deepEqual((await db.query('SELECT last_seen_at FROM app_users WHERE id=$1',[id])).rows[0].last_seen_at,before);
  await db.query("INSERT INTO api_rate_limits VALUES('expired',now()-interval '3 days',1)");
  await db.query("SELECT api_hit('other',60,1)");
  assert.equal((await db.query("SELECT FROM api_rate_limits WHERE bucket='expired'")).rowCount,1);
  await db.query('SELECT housekeeping(1000)');
  assert.equal((await db.query("SELECT FROM api_rate_limits WHERE bucket='expired'")).rowCount,0);
});

test('runtime startup rejects catalog drift and migrator refuses to bless it', async () => {
  const connection=await db.connect();
  try {
    await connection.query('BEGIN');
    await connection.query('GRANT UPDATE(email) ON public.app_users TO autolinky_ops');
    await assert.rejects(checkMigrations(connection),/schema differs/);
  } finally {await connection.query('ROLLBACK');connection.release();}
  await checkMigrations(db);
  await db.query('ALTER TABLE app_users ADD COLUMN unexpected text');
  await assert.rejects(checkMigrations(db),/schema differs/);
  await assert.rejects(migrate(db),/catalog drift/);
  await db.query('ALTER TABLE app_users DROP COLUMN unexpected');
  await checkMigrations(db);
});
