/** Claim before external work. A crashed process releases its time lease after
 * two minutes. Firebase deletion is idempotent and tombstones remain present. */
export async function reconcileIdentityDeletions({db,identity,limit=20,concurrency=2,signal,deadlineMs=15000}) {
  if(!Number.isInteger(limit)||limit<1||limit>100)throw Error('Invalid deletion batch limit');
  if(!Number.isInteger(concurrency)||concurrency<1||concurrency>4)throw Error('Invalid deletion concurrency');
  if(!Number.isInteger(deadlineMs)||deadlineMs<10||deadlineMs>30000)throw Error('Invalid deletion deadline');
  const result={claimed:0,completed:0,deferred:0};
  let failed=false;
  if(signal?.aborted)return result;
  // Claim only as many as can be submitted immediately: later rows remain due
  // when this process stops, rather than waiting behind an abandoned batch.
  async function run() {
    while(!signal?.aborted && !failed && result.claimed<limit) {
      result.claimed++;
      const {rows}=await db.query(`WITH due AS (
        SELECT firebase_uid FROM public.identity_deletion_queue
        WHERE completed_at IS NULL AND next_attempt_at<=now()
        ORDER BY requested_at LIMIT 1 FOR UPDATE SKIP LOCKED
      ) UPDATE public.identity_deletion_queue q
        SET attempts=q.attempts+1,next_attempt_at=now()+interval '2 minutes'
        FROM due WHERE q.firebase_uid=due.firebase_uid RETURNING q.firebase_uid,q.attempts`);
      const row=rows[0];
      if(!row){result.claimed--;return;}
      let timer;
      try {
        await Promise.race([
          Promise.resolve().then(()=>identity.deleteUser(row.firebase_uid)),
          new Promise((_,reject)=>{timer=setTimeout(()=>reject(Error('identity_deadline')),deadlineMs);}),
        ]);
        await db.query('UPDATE public.identity_deletion_queue SET completed_at=now() WHERE firebase_uid=$1 AND completed_at IS NULL',[row.firebase_uid]);
        result.completed++;
      } catch(error) {
        if(error.code==='auth/user-not-found') {
          await db.query('UPDATE public.identity_deletion_queue SET completed_at=now() WHERE firebase_uid=$1 AND completed_at IS NULL',[row.firebase_uid]);
          result.completed++;
        } else {
          const delay=Math.min(86400,30*2**Math.min(row.attempts-1,12));
          await db.query("UPDATE public.identity_deletion_queue SET next_attempt_at=now()+$2*interval '1 second' WHERE firebase_uid=$1 AND completed_at IS NULL",[row.firebase_uid,delay]);
          result.deferred++;
        }
      } finally {clearTimeout(timer);}
    }
  }
  const outcomes=await Promise.allSettled(Array.from({length:Math.min(concurrency,limit)},()=>run().catch(error=>{failed=true;throw error;})));
  const failure=outcomes.find(outcome=>outcome.status==='rejected');
  if(failure)throw failure.reason;
  return result;
}
