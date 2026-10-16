import { defineConfig,loadEnv } from 'vite';

export default defineConfig(({mode})=>{
  const env={...loadEnv(mode,process.cwd(),''),...process.env},target=env.FRONTEND_DEV_ORIGIN;
  if(!target)return {};
  const url=new URL(target);
  if(!['http:','https:'].includes(url.protocol)||url.username||url.password||url.pathname!=='/'||url.search||url.hash)throw Error('FRONTEND_DEV_ORIGIN must be a trusted site-server origin');
  return {server:{proxy:Object.fromEntries(['/v1','/admin/api','/health','/app','/download','/api'].map(path=>[path,url.origin]))}};
});
