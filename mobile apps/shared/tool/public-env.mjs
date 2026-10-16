import { readFile,mkdir,writeFile } from 'node:fs/promises';
import { resolve,dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const root=fileURLToPath(new URL('../',import.meta.url));
const keys=Object.keys(JSON.parse(await readFile(new URL('../env/example.json',import.meta.url),'utf8')));
export function publicMobileSettings(env){
  return Object.fromEntries(keys.filter(key=>typeof env[key]==='string'&&env[key].trim()).map(key=>[key,env[key].trim()]));
}
if(process.argv[1]&&resolve(process.argv[1])===fileURLToPath(import.meta.url)){
  const output=process.argv[2];
  if(!output)throw Error('Usage: node --env-file=.env tool/public-env.mjs env/device.json');
  const destination=resolve(output),privateDirectory=resolve(root,'env');
  if(dirname(destination)!==privateDirectory||!destination.endsWith('.json')||destination===resolve(privateDirectory,'example.json'))throw Error('Write public settings only to an ignored JSON in shared/env/');
  await mkdir(privateDirectory,{recursive:true});
  await writeFile(destination,JSON.stringify(publicMobileSettings(process.env),null,2)+'\n',{mode:0o600});
  console.log('Prepared public mobile settings. No app build was started.');
}
