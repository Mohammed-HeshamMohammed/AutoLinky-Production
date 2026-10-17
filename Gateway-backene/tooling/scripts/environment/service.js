import { readSettings } from './config.js';
import { backendFolders } from '../../support/layout.js';
import { buildGateway,gatewayTargets } from '../../../src/app.js';
import { buildData } from '../../../../Data-baceknd/app.js';
import { buildMessaging } from '../../../../Notify-backend/app.js';
import { createAppClient } from '../../../../Notify-backend/src/app-client.js';
import { runSender } from '../../../../Notify-backend/sender.js';

const name=process.argv[2];
if(!['gateway','messaging','data','sender'].includes(name))throw Error('Unknown local service');
if(process.env.NODE_ENV!=='development')throw Error('Local service wiring requires NODE_ENV=development');
const settings=await readSettings();
const appURL=`http://127.0.0.1:${settings.ports.app}`;
if(name==='sender')await runSender({appData:createAppClient({url:appURL})});
else{
  const {loadConfig}=await import(`../../../../${backendFolders[name]}/lib/config.js`);
  const {serve}=await import(`../../../../${backendFolders[name]}/lib/runtime.js`);
  const config=loadConfig(process.env,{database:name!=='gateway',identity:false});
  const app=name==='gateway'
    ?buildGateway({targets:gatewayTargets(process.env,{appURL}),origins:config.origins,notice:config.notice,version:config.version,logger:true})
    :name==='data'?buildData({appURL,logger:true})
    :buildMessaging({config,appData:createAppClient({url:appURL}),serviceKey:process.env.SERVICE_KEY||'',logger:{level:'info',redact:['req.headers','req.body']}});
  await serve(app,config);
}
