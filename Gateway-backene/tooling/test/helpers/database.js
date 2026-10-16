import EmbeddedPostgres from 'embedded-postgres';
import pg from 'pg';
import { randomBytes } from 'node:crypto';
import { mkdir, readFile,rm } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
import net from 'node:net';
import { migrate } from '../../../../Data-baceknd/database/migrate.js';

export async function testDatabase() {
  const server = net.createServer();
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  const port = server.address().port;
  await new Promise(resolve => server.close(resolve));
  const root = new URL(`../../.runtime/test-${randomBytes(6).toString('hex')}/`, import.meta.url);
  const runtimeRoot=fileURLToPath(new URL('../../.runtime/',import.meta.url));
  const target=fileURLToPath(root);
  if(!/^test-[a-f0-9]{12}[\\/]?$/.test(path.relative(runtimeRoot,target)))throw Error('Test database directory is outside the intended runtime workspace');
  const remove=()=>rm(target,{recursive:true,force:true});
  await mkdir(root, { recursive: true });
  const password = randomBytes(24).toString('hex');
  const cluster = new EmbeddedPostgres({
    databaseDir: fileURLToPath(root), user: 'postgres', password, port,
    persistent: true, onLog: () => {}, onError: () => {},
    postgresFlags: ['-h','127.0.0.1'], initdbFlags: ['--encoding=UTF8','--locale=C'],
  });
  const db = new pg.Pool({ host: '127.0.0.1', port, user: 'postgres', password, database: 'postgres', max: 4 });
  try {
    await cluster.initialise();
    await cluster.start();
    await db.query(await readFile(new URL('../../../../Data-baceknd/database/bootstrap.sql', import.meta.url), 'utf8'));
    await db.query(`ALTER ROLE autolinky_migrator LOGIN PASSWORD '${password}'`);
    const migrator=new pg.Pool({host:'127.0.0.1',port,user:'autolinky_migrator',password,database:'postgres',max:1});
    try{await migrate(migrator);}finally{await migrator.end();}
    return { db, cluster, port, password, close: async () => { await db.end(); await cluster.stop(); await remove(); } };
  } catch (error) { await db.end(); await cluster.stop().catch(() => {}); await remove(); throw error; }
}

export async function asRole(db, role, run) {
  if (!/^autolinky_(api|collector|sender|ops|admin|migrator)$/.test(role)) throw new Error('Unknown test role');
  const connection = await db.connect();
  try {
    await connection.query(`SET ROLE ${role}`);
    return await run(connection);
  } finally {
    await connection.query('RESET ROLE');
    connection.release();
  }
}
