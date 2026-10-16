import { readFile } from 'node:fs/promises';
import { readSettings,controlFile,exists } from './config.js';
if(!await exists(controlFile)){console.log('No running environment control file. No process was stopped.');}
else {
  const settings=await readSettings(),control=JSON.parse(await readFile(controlFile,'utf8'));
  if(!Number.isInteger(control.port)||control.port<1||control.port>65535)throw Error('Invalid local environment control port');
  const response=await fetch(`http://127.0.0.1:${control.port}/stop`,{method:'POST',headers:{'X-Environment-Key':settings.controlKey},signal:AbortSignal.timeout(10000)});
  if(response.status!==202)throw Error('Environment stop request was refused; no unrelated process was stopped');
  console.log('Environment shutdown requested; the local database is retained.');
}
