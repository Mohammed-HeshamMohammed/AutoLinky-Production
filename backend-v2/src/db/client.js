import pg from 'pg';
import { unavailable } from '../http/errors.js';
export function createDatabase(config) {
  if (!config.databaseUrl) return {configured:false,query:async()=>{throw unavailable();},transaction:async()=>{throw unavailable();},end:async()=>{}};
  const pool=new pg.Pool({connectionString:config.databaseUrl,max:config.poolMax,connectionTimeoutMillis:5000,idleTimeoutMillis:30000,
    statement_timeout:config.statementTimeout,idle_in_transaction_session_timeout:10000,application_name:'autolinky-api-v2'});
  pool.on('error',()=>{});
  return {
    configured:true,query:(text,values)=>pool.query(text,values),end:()=>pool.end(),
    async transaction(run) {
      const connection=await pool.connect();
      try { await connection.query('BEGIN');const result=await run(connection);await connection.query('COMMIT');return result; }
      catch(error) { await connection.query('ROLLBACK').catch(()=>{});throw error; }
      finally {connection.release();}
    },
  };
}
export async function transaction(db,run) {
  if(db.transaction) return db.transaction(run);
  const connection=await db.connect();
  try {await connection.query('BEGIN');const result=await run(connection);await connection.query('COMMIT');return result;}
  catch(error){await connection.query('ROLLBACK');throw error;}
  finally{connection.release();}
}
