import { setTimeout as sleep } from 'node:timers/promises';
import { loadConfig } from './config.js';
import { createDatabase } from './db/client.js';
import { checkMigrations } from '../database/migrate.js';
import { gmailTransport } from './email/gmail.js';
import { deliveryService } from './email/delivery.js';
import { senderTick } from './workers/auto-apply.js';
import { AIClient } from './ai/client.js';
const config=loadConfig(process.env,{identity:false});
if(!config.senderEnabled)throw Error('Sender is disabled; set SENDER_ENABLED=true only after the sender activation checks');
const db=createDatabase({...config,poolMax:2}),stop=new AbortController(),mail=deliveryService({db,config,transport:gmailTransport(),ai:new AIClient(config)});
for(const name of ['SIGINT','SIGTERM'])process.on(name,()=>stop.abort());
try{
  await checkMigrations(db);
  while(!stop.signal.aborted){
    const start=Date.now();try{await senderTick({db,config,mail,signal:stop.signal});}catch(error){console.error(JSON.stringify({service:'sender',event:'tick_failed',code:error.code||error.name}));}
    await sleep(Math.max(1000,30000-(Date.now()-start)),undefined,{signal:stop.signal}).catch(()=>{});
  }
}finally{await db.end();}
