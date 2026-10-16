import { readFile,writeFile,mkdir,access,unlink } from 'node:fs/promises';
import { resolve,sep,dirname } from 'node:path';
import { randomBytes } from 'node:crypto';
import { createDatabase,transaction } from '../lib/db/client.js';
import { loadConfig } from '../lib/config.js';
import { base32,hashPassword,encryptTotp,encryptionKey,totp } from '../src/admin-crypto.js';
const values={};for(let index=2;index<process.argv.length;index+=2){const name=process.argv[index];if(!['--username','--role','--output','--password-file','--totp-file'].includes(name)||!process.argv[index+1])throw Error('Use --username NAME --role owner|operator|viewer --output PRIVATE_FILE [--password-file FILE] [--totp-file FILE]');values[name]=process.argv[index+1];}
const username=values['--username']?.trim().toLowerCase(),role=values['--role']||'owner';if(!/^[a-z0-9._-]{3,64}$/.test(username||'')||!['owner','operator','viewer'].includes(role))throw Error('Invalid username or role');
const runtime=resolve(import.meta.dirname,'../.runtime'),output=resolve(values['--output']||resolve(runtime,'admin-setup.json'));
if(!output.startsWith(runtime+sep))throw Error('Admin setup output must stay inside Auth-backend/.runtime/');
try{await access(output);throw Error('Private setup output already exists; choose another file');}catch(error){if(error.code!=='ENOENT')throw error;}
const password=values['--password-file']?(await readFile(resolve(values['--password-file']),'utf8')).trim():randomBytes(24).toString('base64url');
const secret=values['--totp-file']?(await readFile(resolve(values['--totp-file']),'utf8')).trim():base32(randomBytes(20));
if(!/^[A-Z2-7]{32,64}$/.test(secret))throw Error('TOTP secret must contain 32 to 64 base32 characters');totp(secret,0);
const passwordHash=await hashPassword(password),totpSecret=encryptTotp(secret,encryptionKey(process.env.ADMIN_TOTP_KEY));
const db=createDatabase(loadConfig(process.env,{identity:false}));let written=false;
try{await mkdir(dirname(output),{recursive:true});await transaction(db,async connection=>{
  await connection.query('INSERT INTO public.admin_accounts(username,password_hash,totp_secret,role) VALUES($1,$2,$3,$4)',[username,passwordHash,totpSecret,role]);
  await writeFile(output,JSON.stringify({username,role,password,totp_secret:secret,authenticator_uri:`otpauth://totp/AutoLinky:${encodeURIComponent(username)}?secret=${secret}&issuer=AutoLinky&algorithm=SHA1&digits=6&period=30`},null,2)+'\n',{flag:'wx',mode:0o600});written=true;
});console.log(`Created administrator ${username} (${role}). Private setup file: ${output}`);
}catch(error){if(written)await unlink(output).catch(()=>{});throw error;}finally{await db.end();}
