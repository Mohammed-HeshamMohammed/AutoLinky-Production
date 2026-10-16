import http from 'node:http';
import https from 'node:https';
import { createReadStream } from 'node:fs';
import { stat } from 'node:fs/promises';
import { resolve,sep,extname } from 'node:path';
import { fileURLToPath } from 'node:url';
import download from './api/download.js';
import latest from './api/latest.js';
import { workspaceRoute } from './workspace-routes.js';
import { workspaceHeaders } from './workspace-headers.js';
import { availablePublicSettings } from './public-settings.js';

const types={'.html':'text/html; charset=utf-8','.js':'text/javascript; charset=utf-8','.css':'text/css; charset=utf-8',
  '.json':'application/json; charset=utf-8','.svg':'image/svg+xml','.webp':'image/webp','.png':'image/png','.ico':'image/x-icon',
  '.txt':'text/plain; charset=utf-8','.xml':'application/xml; charset=utf-8','.woff2':'font/woff2','.ttf':'font/ttf',
  '.wasm':'application/wasm','.webmanifest':'application/manifest+json'};

export function createSiteServer({directory=fileURLToPath(new URL('./dist/',import.meta.url)),spaFallback=false,env=process.env,apiOrigin=env.API_BASE_URL||''}={}) {
  const root=resolve(directory);
  let api;
  if(apiOrigin){api=new URL(apiOrigin);if(!['http:','https:'].includes(api.protocol)||api.username||api.password||api.pathname!=='/'||api.search||api.hash)throw Error('API_BASE_URL must be a trusted gateway origin');}
  return http.createServer(async(req,res)=>{
    res.setHeader('X-Content-Type-Options','nosniff');
    res.setHeader('X-Frame-Options','DENY');
    res.setHeader('Referrer-Policy','strict-origin-when-cross-origin');
    try {
      const url=new URL(req.url,'http://site.local');
      if(url.pathname==='/api/config'){
        if(!['GET','HEAD'].includes(req.method)){res.writeHead(405,{Allow:'GET, HEAD','Cache-Control':'no-store'}).end();return;}
        const settings=availablePublicSettings(env);
        res.writeHead(settings?200:503,{'Content-Type':'application/json; charset=utf-8','Cache-Control':'no-store'});
        res.end(req.method==='HEAD'?undefined:JSON.stringify(settings||{error:'public_configuration_unavailable'}));return;
      }
      if(url.pathname.startsWith('/v1/')||url.pathname.startsWith('/admin/api/')||['/health','/health/ready'].includes(url.pathname)){
        if(!api){res.writeHead(503,{'Content-Type':'application/json','Cache-Control':'no-store'}).end(JSON.stringify({detail:'API gateway is not configured'}));return;}
        const headers={};
        for(const key of ['authorization','content-type','content-length','origin','x-request-id','x-autolinky-client-version','x-admin-session','x-admin-elevation','access-control-request-method','access-control-request-headers'])if(req.headers[key])headers[key]=req.headers[key];
        const upstream=(api.protocol==='https:'?https:http).request(new URL(url.pathname+url.search,api),{method:req.method,headers,timeout:95000},response=>{
          const output={'Cache-Control':'no-store',...(url.pathname.startsWith('/admin/')?{'X-Robots-Tag':'noindex, nofollow'}:{})};
          for(const key of ['content-type','retry-after','www-authenticate','x-request-id','access-control-allow-origin','access-control-allow-methods','access-control-allow-headers','access-control-expose-headers','vary'])if(response.headers[key])output[key]=response.headers[key];
          res.writeHead(response.statusCode,output);response.on('error',()=>res.destroy());response.pipe(res);
        });
        upstream.once('error',()=>{if(!res.headersSent)res.writeHead(503,{'Content-Type':'application/json','Cache-Control':'no-store'}).end(JSON.stringify({detail:'API gateway unavailable'}));else res.destroy();});
        upstream.once('timeout',()=>upstream.destroy());req.once('aborted',()=>upstream.destroy());
        res.once('close',()=>upstream.destroy());
        let bytes=0;
        req.on('data',chunk=>{bytes+=chunk.length;if(bytes>4*1024*1024){if(!res.headersSent)res.writeHead(413,{'Cache-Control':'no-store'}).end();else if(!res.writableEnded)res.destroy();upstream.destroy();req.unpipe(upstream);}});
        req.pipe(upstream);return;
      }
      if(['/download','/apk'].includes(url.pathname))return await download(req,res);
      if(url.pathname==='/api/latest')return await latest(req,res);
      if(!['GET','HEAD'].includes(req.method)){res.writeHead(405,{Allow:'GET, HEAD'}).end();return;}
      const workspace=workspaceRoute(url);
      if(workspace){
        const shell=resolve(root,'workspace/index.html'),info=await stat(shell).catch(()=>null);
        const headers=workspaceHeaders({...workspace,settings:availablePublicSettings(env)});
        if(!info?.isFile()){res.writeHead(503,{'Content-Type':'text/plain; charset=utf-8',...headers}).end('The desktop web client is awaiting a requested web deployment.');return;}
        res.writeHead(200,{'Content-Type':'text/html; charset=utf-8',...headers});
        if(req.method==='HEAD'){res.end();return;}createReadStream(shell).on('error',()=>res.destroy()).pipe(res);return;
      }
      const pathname=decodeURIComponent(url.pathname);
      if(pathname.includes('\0') || pathname.includes('\\')){res.writeHead(400).end();return;}
      if(pathname==='/app'||pathname==='/app/') {
        const platform=/iPhone|iPad|iPod/i.test(req.headers['user-agent']||'')?'ios':'android';
        res.writeHead(302,{Location:`/app/${platform}/${url.search}`,'Cache-Control':'no-store',Vary:'User-Agent'}).end();return;
      }
      let path=resolve(root,'.'+pathname);
      if(path!==root && !path.startsWith(root+sep)){res.writeHead(404).end();return;}
      let info=await stat(path).catch(()=>null);
      if(info?.isDirectory()) {
        if(!url.pathname.endsWith('/')){res.writeHead(308,{Location:url.pathname+'/'+url.search}).end();return;}
        path=resolve(path,'index.html');info=await stat(path).catch(()=>null);
      }
      if(!info?.isFile()){
        const app=pathname.match(/^\/app\/(android|ios)(?:\/|$)/)?.[1];
        const appRoute=app&&!extname(pathname)&&!pathname.startsWith(`/app/${app}/assets/`);
        const fallback=appRoute||(spaFallback && !extname(pathname) && !pathname.startsWith('/api/'));
        path=resolve(root,appRoute?`app/${app}/index.html`:fallback?'index.html':'404.html');
        info=await stat(path).catch(()=>null);res.statusCode=fallback&&info?.isFile()?200:404;
      }
      if(!info?.isFile()){res.writeHead(404).end('Not found');return;}
      res.setHeader('Content-Type',types[extname(path)]||'application/octet-stream');
      res.setHeader('Content-Length',info.size);
      const appAsset=pathname.startsWith('/app/');
      res.setHeader('Cache-Control',res.statusCode===404?'no-store':appAsset||extname(path)==='.html'?'public, max-age=0, must-revalidate':'public, max-age=3600');
      if(req.method==='HEAD'){res.end();return;}
      createReadStream(path).on('error',()=>res.destroy()).pipe(res);
    } catch {
      if(!res.headersSent)res.writeHead(500,{'Cache-Control':'no-store'}).end('Unavailable');
      else res.destroy();
    }
  });
}

if(process.argv[1] && resolve(process.argv[1])===fileURLToPath(import.meta.url)) {
  const port=Number(process.env.PORT||8080);
  if(!Number.isInteger(port)||port<1||port>65535)throw new Error('Invalid PORT');
  const server=createSiteServer();
  server.requestTimeout=20000;server.headersTimeout=10000;
  server.listen(port,process.env.HOST||'127.0.0.1');
  for(const signal of ['SIGINT','SIGTERM'])process.once(signal,()=>{server.close();server.closeIdleConnections();setTimeout(()=>process.exit(1),15000).unref();});
}
