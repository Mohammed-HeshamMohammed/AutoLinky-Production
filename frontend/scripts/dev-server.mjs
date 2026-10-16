import http from 'node:http';
import { readFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import { resolve } from 'node:path';
import { createServer as createViteServer } from 'vite';
import React from 'react';
import { renderToString } from 'react-dom/server';
import { createSiteServer } from '../server.js';
import { workspaceRoute } from '../workspace-routes.js';
import { workspaceHeaders } from '../workspace-headers.js';
import { availablePublicSettings } from '../public-settings.js';

// Current React source plus existing browser-app assets; no production build.
export async function createDevelopmentServer({port=Number(process.env.PORT||8080),host=process.env.HOST||'127.0.0.1'}={}){
  const root=fileURLToPath(new URL('../',import.meta.url));
  process.env.VITE_SITE_URL||=`http://localhost:${port}`;
  const staticServer=createSiteServer();
  const httpServer=http.createServer();
  const vite=await createViteServer({root,configFile:false,appType:'custom',logLevel:'error',server:{middlewareMode:true,hmr:{server:httpServer},fs:{allow:[root],deny:['**/.env','**/.env.*','**/*.{crt,pem,key}','**/.runtime/**','**/.git/**']}}});
  httpServer.on('request',(req,res)=>{
    res.setHeader('X-Content-Type-Options','nosniff');res.setHeader('X-Frame-Options','DENY');res.setHeader('Referrer-Policy','strict-origin-when-cross-origin');
    let url;
    try{url=new URL(req.url,'http://local.site');}catch{res.writeHead(400).end('Invalid request');return;}
    if(/^\/(app(?:\/|$)|v1(?:\/|$)|api(?:\/|$)|health(?:\/|$)|download(?:\/|$)|apk(?:\/|$)|admin\/api(?:\/|$))/.test(url.pathname)){
      staticServer.emit('request',req,res);return;
    }
    vite.middlewares(req,res,async()=>{
      try{
        if(!['GET','HEAD'].includes(req.method)){staticServer.emit('request',req,res);return;}
        const workspace=workspaceRoute(url);
        if(workspace){
          const {default:DesktopApp}=await vite.ssrLoadModule('/src/workspace/DesktopApp.jsx');
          const markup=renderToString(React.createElement(DesktopApp,{initialURL:url.pathname+url.search}));
          let html=await vite.transformIndexHtml(req.url,await readFile(resolve(root,'index.html'),'utf8'));
          html=html.replace('<html lang="en" dir="ltr">',`<html lang="${workspace.lang}" dir="${workspace.lang==='ar'?'rtl':'ltr'}">`).replace(/<title>[^<]*<\/title>/,'<title>AutoLinky · '+(workspace.admin?'Admin':workspace.screen==='login'||workspace.screen==='signup'?'Sign in':'Workspace')+'</title>').replace(/(<meta name="robots" content=")[^"]*(" \/>)/,'$1noindex, nofollow$2').replace('<div id="root"></div>',`<div id="root">${markup}</div>`);
          res.writeHead(200,{'Content-Type':'text/html; charset=utf-8',...workspaceHeaders({development:true,settings:availablePublicSettings()})}).end(req.method==='HEAD'?undefined:html);return;
        }
        const parts=url.pathname.split('/').filter(Boolean),lang=parts[0]==='ar'?'ar':'en';if(lang==='ar')parts.shift();
        const slug=parts[0]||'';
        const {PAGES}=await vite.ssrLoadModule('/src/pageContent.js');
        if(parts.length>1||(slug&&!Object.hasOwn(PAGES,slug))){staticServer.emit('request',req,res);return;}
        const {default:Page}=await vite.ssrLoadModule(slug?'/src/ContentPage.jsx':'/src/PageMarkup.jsx');
        const {META}=await vite.ssrLoadModule('/src/content.js');
        const page=slug?PAGES[slug][lang]:META[lang];
        const markup=renderToString(React.createElement(Page,{lang,slug,release:null,sticky:false}));
        const esc=value=>String(value).replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
        let html=await vite.transformIndexHtml(req.url,await readFile(resolve(root,'index.html'),'utf8'));
        html=html.replace('<html lang="en" dir="ltr">',`<html lang="${lang}" dir="${lang==='ar'?'rtl':'ltr'}">`)
          .replace(/<title>[^<]*<\/title>/,`<title>${esc(page.title)}</title>`)
          .replace('<div id="root"></div>',`<div id="root">${markup}</div>`);
        res.writeHead(200,{'Content-Type':'text/html; charset=utf-8','Cache-Control':'no-store','X-Content-Type-Options':'nosniff'}).end(req.method==='HEAD'?undefined:html);
      }catch(error){vite.ssrFixStacktrace(error);console.error(error.message);if(!res.headersSent)res.writeHead(500,{'Cache-Control':'no-store'}).end('Development frontend unavailable');else res.destroy();}
    });
  });
  await new Promise((done,reject)=>{httpServer.once('error',reject);httpServer.listen(port,host,done);});
  return {server:httpServer,vite,async close(){await vite.close();httpServer.closeAllConnections();await new Promise(done=>httpServer.close(done));}};
}

if(process.argv[1]&&resolve(process.argv[1])===fileURLToPath(import.meta.url)){
  const app=await createDevelopmentServer();
  console.log(`Current frontend source is live on http://localhost:${app.server.address().port}; existing browser apps reused.`);
  for(const signal of ['SIGINT','SIGTERM'])process.once(signal,async()=>{await app.close();});
}
