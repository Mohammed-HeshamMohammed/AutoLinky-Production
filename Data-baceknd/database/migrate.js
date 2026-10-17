import { createHash } from 'node:crypto';
import { readdir, readFile } from 'node:fs/promises';
import { fileURLToPath, pathToFileURL } from 'node:url';
import pg from 'pg';

const directory = new URL('./migrations/', import.meta.url);
export async function migrationFiles() {
  const names = (await readdir(directory)).filter(n => /^\d{4}_[a-z0-9_]+\.sql$/.test(n)).sort();
  return Promise.all(names.map(async name => {
    const sql = await readFile(new URL(name, directory), 'utf8');
    return { name, sql, checksum: createHash('sha256').update(sql).digest('hex') };
  }));
}

export async function checkMigrations(db) {
  const expected = await migrationFiles();
  const { rows } = await db.query('SELECT * FROM migrator.runtime_schema_status()');
  const state = rows[0];
  let reason;
  if (!state) reason='missing_state';
  else if (state.actual !== state.expected) reason='catalog_drift';
  else if (!Array.isArray(state.migrations) || state.migrations.length !== expected.length) reason='migration_count';
  else if (state.migrations.some((row,i) => row?.name !== expected[i].name || row?.checksum !== expected[i].checksum)) reason='migration_mismatch';
  if (reason) {
    throw Object.assign(new Error('Database schema differs from this release; run reviewed migrations before startup'),{code:'DATABASE_SCHEMA_NOT_READY',reason});
  }
}

const fingerprintSQL = `CREATE OR REPLACE FUNCTION migrator.catalog_fingerprint() RETURNS text
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = pg_catalog, pg_temp AS $$
SELECT md5(string_agg(item,E'\\n' ORDER BY item)) FROM (
  SELECT 'column:'||c.table_name||':'||c.column_name||':'||c.udt_name||':'||c.is_nullable||':'||coalesce(c.column_default,'') AS item
    FROM information_schema.columns c WHERE c.table_schema='public'
  UNION ALL SELECT 'relation:'||c.relname||':'||c.relrowsecurity||':'||coalesce(c.relacl::text,'')
    FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname='public' AND c.relkind IN ('r','p','v')
  UNION ALL SELECT 'column-acl:'||c.relname||':'||a.attname||':'||coalesce(a.attacl::text,'')
    FROM pg_attribute a JOIN pg_class c ON c.oid=a.attrelid JOIN pg_namespace n ON n.oid=c.relnamespace
    WHERE n.nspname='public' AND c.relkind IN ('r','p','v') AND a.attnum>0 AND NOT a.attisdropped
  UNION ALL SELECT 'function:'||p.oid::regprocedure::text||':'||md5(pg_get_functiondef(p.oid))||':'||coalesce(p.proacl::text,'')
    FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname='public'
  UNION ALL SELECT 'constraint:'||conname||':'||pg_get_constraintdef(oid) FROM pg_constraint WHERE connamespace='public'::regnamespace
  UNION ALL SELECT 'index:'||indexname||':'||indexdef FROM pg_indexes WHERE schemaname='public'
) objects;
$$;
REVOKE ALL ON FUNCTION migrator.catalog_fingerprint() FROM PUBLIC;`;

export async function migrate(db, { production = false, snapshot = false, automatic = false } = {}) {
  if (production && !snapshot && !automatic) throw new Error('Production migration requires a verified pre-migration snapshot (--snapshot-verified)');
  const files = await migrationFiles();
  const connection = db.connect ? await db.connect() : db;
  try {
    await connection.query('SELECT pg_advisory_lock(812761502)');
    await connection.query(`CREATE SCHEMA IF NOT EXISTS migrator;
      REVOKE ALL ON SCHEMA migrator FROM PUBLIC;
      CREATE TABLE IF NOT EXISTS migrator.schema_migrations(name text PRIMARY KEY,checksum text NOT NULL,applied_at timestamptz NOT NULL DEFAULT now());
      CREATE TABLE IF NOT EXISTS migrator.schema_state(id boolean PRIMARY KEY DEFAULT true CHECK(id),fingerprint text NOT NULL);`);
    const applied = (await connection.query('SELECT name,checksum FROM migrator.schema_migrations ORDER BY name')).rows;
    if (applied.some((row, i) => row.name !== files[i]?.name || row.checksum !== files[i]?.checksum)) throw Object.assign(new Error('Applied migration checksum/order mismatch'),{code:'DATABASE_SCHEMA_NOT_READY',reason:'migration_mismatch'});
    if (applied.length) {
      const { rows } = await connection.query('SELECT actual,expected FROM migrator.runtime_schema_status()');
      if (!rows[0] || rows[0].actual !== rows[0].expected) throw Object.assign(new Error('Unreviewed catalog drift; refusing to apply migrations'),{code:'DATABASE_SCHEMA_NOT_READY',reason:'catalog_drift'});
    }
    await connection.query('BEGIN');
    try {
      for (const file of files.slice(applied.length)) {
        await connection.query(file.sql);
        await connection.query('INSERT INTO migrator.schema_migrations(name,checksum) VALUES($1,$2)', [file.name, file.checksum]);
      }
      await connection.query(fingerprintSQL);
      await connection.query(`INSERT INTO migrator.schema_state(id,fingerprint) VALUES(true,migrator.catalog_fingerprint())
        ON CONFLICT(id) DO UPDATE SET fingerprint=EXCLUDED.fingerprint;
        CREATE OR REPLACE FUNCTION migrator.runtime_schema_status()
        RETURNS TABLE(actual text,expected text,migrations jsonb)
        LANGUAGE sql STABLE SECURITY DEFINER SET search_path=pg_catalog,pg_temp AS $$
          SELECT migrator.catalog_fingerprint(),s.fingerprint,
            (SELECT jsonb_agg(jsonb_build_object('name',m.name,'checksum',m.checksum) ORDER BY m.name) FROM migrator.schema_migrations m)
          FROM migrator.schema_state s WHERE s.id;
        $$;
        REVOKE ALL ON FUNCTION migrator.runtime_schema_status() FROM PUBLIC;
        GRANT USAGE ON SCHEMA migrator TO autolinky_api,autolinky_collector,autolinky_sender,autolinky_ops,autolinky_admin,autolinky_auth,autolinky_app,autolinky_messaging,autolinky_fetching,autolinky_data;
        GRANT EXECUTE ON FUNCTION migrator.runtime_schema_status() TO autolinky_api,autolinky_collector,autolinky_sender,autolinky_ops,autolinky_admin,autolinky_auth,autolinky_app,autolinky_messaging,autolinky_fetching,autolinky_data;`);
      await connection.query('COMMIT');
    } catch (error) { await connection.query('ROLLBACK'); throw error; }
  } finally {
    await connection.query('SELECT pg_advisory_unlock(812761502)').catch(() => {});
    connection.release?.();
  }
}

if (process.argv[1] && pathToFileURL(fileURLToPath(pathToFileURL(process.argv[1]))).href === import.meta.url) {
  const connectionString = process.env.PG_MIGRATOR_URL;
  if (!connectionString) throw new Error('PG_MIGRATOR_URL is required');
  const db = new pg.Pool({ connectionString, max: 1, connectionTimeoutMillis: 5000 });
  try {
    if (process.argv.includes('--check')) await checkMigrations(db);
    else await migrate(db, { production: process.env.NODE_ENV === 'production', snapshot: process.argv.includes('--snapshot-verified') });
    console.log('Migration verification passed');
  } finally { await db.end(); }
}
