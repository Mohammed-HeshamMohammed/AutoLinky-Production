import { setTimeout as sleep } from 'node:timers/promises';
import { loadConfig } from '../../shared/config.js';
import { createDatabase } from '../../shared/db/client.js';
import { checkMigrations } from '../../database/migrate.js';
import { gmailTransport } from './src/email/gmail.js';
import { deliveryService } from './src/email/delivery.js';
import { senderTick } from './src/auto-apply.js';
import { AIClient } from '../../shared/ai/client.js';
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
