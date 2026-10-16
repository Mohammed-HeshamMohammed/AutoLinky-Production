import { loadConfig } from './lib/config.js';
import { createDatabase } from './lib/db/client.js';
import { firebaseIdentity } from './src/auth.js';
import { schemaReadiness } from './lib/api.js';
import { reconcileIdentityDeletions } from './src/identity-deletions.js';

const args=process.argv.slice(2);
if(args.some(arg=>!['--apply','--dry-run'].includes(arg)))throw Error('Use --dry-run (default) or --apply');
if(args.includes('--apply')&&args.includes('--dry-run'))throw Error('Choose one mode');
if(!process.env.PG_OPS_URL)throw Error('PG_OPS_URL is required with the autolinky_ops role');
const config=loadConfig({...process.env,PG_DATABASE_URL:process.env.PG_OPS_URL});
if(args.includes('--apply')&&!config.firebaseProjectId)throw Error('FIREBASE_PROJECT_ID is required to apply identity deletions');
const db=createDatabase({...config,databaseUrl:process.env.PG_OPS_URL,poolMax:2});
const stop=new AbortController();
for(const name of ['SIGINT','SIGTERM'])process.once(name,()=>stop.abort());
try {
  await schemaReadiness(config.dataServiceUrl);
  if(!args.includes('--apply')) {
    const {rows}=await db.query(`SELECT count(*) FILTER(WHERE completed_at IS NULL)::integer AS pending,
      count(*) FILTER(WHERE completed_at IS NULL AND next_attempt_at<=now())::integer AS due,
      count(*) FILTER(WHERE completed_at IS NOT NULL)::integer AS completed FROM public.identity_deletion_queue`);
    console.log(JSON.stringify({mode:'dry-run',...rows[0]}));
  } else {
    const result=await reconcileIdentityDeletions({db,identity:firebaseIdentity(config),signal:stop.signal});
    console.log(JSON.stringify({mode:'apply',...result}));
    if(result.deferred)process.exitCode=2;
  }
} finally {await db.end();}
