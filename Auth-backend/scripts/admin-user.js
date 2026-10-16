import { createDatabase } from '../lib/db/client.js';
import { loadConfig } from '../lib/config.js';
import { assignAdministrator } from '../src/admin-provision.js';
const usage='Use --user-id UUID OR --firebase-uid UID, --role owner|operator|viewer|none, --reason TEXT [--reset-authenticator true]';
const values={};for(let index=2;index<process.argv.length;index+=2){const name=process.argv[index];if(!['--user-id','--firebase-uid','--role','--reason','--reset-authenticator'].includes(name)||!process.argv[index+1]||values[name])throw Error(usage);values[name]=process.argv[index+1];}
if(values['--reset-authenticator']&&values['--reset-authenticator']!=='true')throw Error(usage);
const db=createDatabase(loadConfig(process.env,{identity:false}));
try{console.log(JSON.stringify(await assignAdministrator(db,{userId:values['--user-id'],firebaseUid:values['--firebase-uid'],role:values['--role'],reason:values['--reason'],resetAuthenticator:values['--reset-authenticator']==='true'}),null,2));}finally{await db.end();}
