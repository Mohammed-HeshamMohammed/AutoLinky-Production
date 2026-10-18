// Offline source for the landing film. No rendering dependencies are shipped to the browser.
// Usage: node scripts/render-brand-film.mjs --modules <node_modules> --ffmpeg <binary>
import {createRequire} from 'node:module';
import {resolve} from 'node:path';
import {mkdir,readFile,writeFile} from 'node:fs/promises';
import {spawn} from 'node:child_process';
import {once} from 'node:events';
import {createHash} from 'node:crypto';
import {renderDocuments} from './film-documents.mjs';
import {filmMotion,TRANSITIONS,between,mix} from './film-motion.mjs';

const option=name=>process.argv[process.argv.indexOf(name)+1];
if(!process.argv.includes('--modules')||!process.argv.includes('--ffmpeg'))throw Error('Provide the optional canvas module directory and FFmpeg executable.');
const require=createRequire(import.meta.url);
const {createCanvas,loadImage,GlobalFonts}=require(require.resolve('@napi-rs/canvas',{paths:[resolve(option('--modules'))]}));
const out=resolve('public/assets/film'),proofs=resolve('output/playwright/film-stills');await mkdir(out,{recursive:true});await mkdir(proofs,{recursive:true});
GlobalFonts.registerFromPath(resolve('public/assets/workspace-fonts/Manrope-Variable.ttf'),'Manrope');
const documents=await renderDocuments({createCanvas,loadImage,GlobalFonts});
const device=JSON.parse(await readFile(resolve('src/iphoneMockup.json'),'utf8'));
const hardware=await loadImage(resolve('public'+device.frameSrc));
const images=await Promise.all(['profile','for-you','auto-apply'].map(name=>loadImage(resolve(`public/assets/app/iphone/${name}.webp`))));
const matchDetail=await loadImage(resolve('public/assets/app/for-you.webp'));
const matchCardCrop={x:48,y:686,width:690,height:556};
const W=1080,H=1080,FPS=60,DURATION=24;
const GOP=6,CRF=22;
const previewOnly=process.argv.includes('--preview-only');
const PAPER_LAYOUT_WIDTH=1000,MACRO_PAPER_WIDTH=2600,PHONE_PREVIEW_WIDTH=300;
const canvas=createCanvas(W,H),ctx=canvas.getContext('2d');
const C={bg:'#171c19',paper:'#eeeade',ink:'#252d28',dim:'#94a095',line:'#343d36',sage:'#bed2a8',blue:'#315bd6'};
function rect(x,y,w,h,r,fill,stroke){ctx.beginPath();ctx.roundRect(x,y,w,h,r);if(fill){ctx.fillStyle=fill;ctx.fill();}if(stroke){ctx.strokeStyle=stroke;ctx.lineWidth=1.2;ctx.stroke();}}
function text(value,x,y,size=20,color=C.ink,weight=500){ctx.fillStyle=color;ctx.font=`${weight} ${size}px Manrope`;ctx.fillText(value,x,y);}
function paper(x,y,w,rotation=0,kind='cv',shade=1){
  const image=documents[kind],h=w*image.height/image.width;
  ctx.save();ctx.translate(x,y);ctx.rotate(rotation);
  ctx.shadowColor='#00000090';ctx.shadowBlur=35;ctx.shadowOffsetY=19;ctx.shadowOffsetX=7;
  ctx.drawImage(image,-w/2,-h/2,w,h);ctx.shadowColor='transparent';
  // Back sheets remain opaque: a physical stack, with slight studio falloff.
  if(shade<1){ctx.fillStyle=`rgba(23,28,25,${1-shade})`;ctx.fillRect(-w/2,-h/2,w,h);}
  ctx.restore();
}
function phoneGeometry({width},image){
  const outerWidth=width+18,scale=outerWidth/device.width,height=outerWidth*device.height/device.width;
  const left=-outerWidth/2,top=-height/2,screen=device.screen;
  const sx=left+screen.x*scale,sy=top+screen.y*scale,sw=screen.width*scale,sh=screen.height*scale;
  const fit=Math.min(sw/image.width,sh/image.height),iw=image.width*fit,ih=image.height*fit;
  return {outerWidth,height,left,top,sx,sy,sw,sh,fit,ix:sx+(sw-iw)/2,iy:sy+(sh-ih)/2,iw,ih,radius:screen.radius*scale};
}
function phone(image,pose,{dim=0,change=null,hideMatchCard=false}={}){
  const {x,y,rotation}=pose,g=phoneGeometry(pose,image);
  ctx.save();ctx.translate(x,y);ctx.rotate(rotation);
  ctx.shadowColor='#00000080';ctx.shadowBlur=40;ctx.shadowOffsetY=28;
  ctx.drawImage(hardware,g.left,g.top,g.outerWidth,g.height);ctx.shadowColor='transparent';
  ctx.save();ctx.beginPath();ctx.roundRect(g.sx,g.sy,g.sw,g.sh,g.radius);ctx.clip();
  ctx.fillStyle=device.background;ctx.fillRect(g.sx,g.sy,g.sw,g.sh);
  if(change){
    // Both opaque screens travel through one hardware aperture; no ghost phones.
    ctx.drawImage(image,g.ix-change.progress*g.iw,g.iy,g.iw,g.ih);
    ctx.drawImage(change.image,g.ix+(1-change.progress)*g.iw,g.iy,g.iw,g.ih);
  }else ctx.drawImage(image,g.ix,g.iy,g.iw,g.ih);
  if(hideMatchCard){ctx.fillStyle=device.background;ctx.fillRect(g.ix+72*g.fit,g.iy+1206*g.fit,1035*g.fit,834*g.fit);}
  if(dim>0){ctx.fillStyle=`rgba(23,28,25,${dim})`;ctx.fillRect(g.sx,g.sy,g.sw,g.sh);}
  ctx.restore();ctx.drawImage(hardware,g.left,g.top,g.outerWidth,g.height);ctx.restore();
}
function liftedCard(pose,lift,seconds){
  const g=phoneGeometry(pose,images[1]);
  // Safe-area render includes a 177px vertical inset; use its measured card bounds.
  const localX=g.ix+(72+1035/2)*g.fit,localY=g.iy+(1206+834/2)*g.fit;
  const anchorX=pose.x+localX*Math.cos(pose.rotation)-localY*Math.sin(pose.rotation);
  const anchorY=pose.y+localX*Math.sin(pose.rotation)+localY*Math.cos(pose.rotation);
  const drift=between(seconds,12.6,15.7),width=mix(1035*g.fit,386,lift),height=width*matchCardCrop.height/matchCardCrop.width;
  const x=mix(anchorX,mix(749,767,drift),lift),y=mix(anchorY,mix(427,410,drift)-100+386*556/690/2,lift);
  ctx.save();ctx.translate(x,y);ctx.rotate(mix(pose.rotation,.025,lift));
  ctx.shadowColor=`rgba(0,0,0,${.31*lift})`;ctx.shadowBlur=24*lift;ctx.shadowOffsetY=14*lift;
  rect(-width/2,-height/2,width,height,width*11/386,'#fffefa');ctx.shadowColor='transparent';
  ctx.beginPath();ctx.roundRect(-width/2,-height/2,width,height,width*11/386);ctx.clip();
  ctx.drawImage(matchDetail,matchCardCrop.x,matchCardCrop.y,matchCardCrop.width,matchCardCrop.height,-width/2,-height/2,width,height);ctx.restore();
}
function caption(label,x,y,align='left'){
  ctx.save();ctx.textAlign=align;ctx.letterSpacing='2px';text(label,x,y,12,C.dim,500);ctx.restore();
}
function backdrop(time){
  ctx.fillStyle=C.bg;ctx.fillRect(0,0,W,H);
  // A quiet studio grid provides depth without glows, stock footage or decorative icons.
  ctx.strokeStyle='#253027';ctx.lineWidth=1;
  for(let i=0;i<5;i++){const y=300+i*160;ctx.beginPath();ctx.moveTo(70,y);ctx.lineTo(1010,y);ctx.stroke();}
  ctx.beginPath();ctx.moveTo(540,55);ctx.lineTo(540,1025);ctx.stroke();
  caption('AUTOLINKY / THE SEARCH, RECONSIDERED',76,83);
  caption('A LITTLE LESS BUSYWORK',1004,1018,'right');
}
function frame(seconds){
  const motion=filmMotion(seconds);backdrop(seconds);
  if(motion.openingStack>0){
    ctx.save();ctx.globalAlpha=motion.openingStack;
    paper(682+seconds*4,483,365,.15-seconds*.01,'application-1',.86);
    paper(359-seconds*4,584,365,-.16,'cover-letter',.94);ctx.restore();
  }
  if(motion.formStack>0){
    ctx.save();ctx.globalAlpha=motion.formStack;
    const arrival=between(seconds,3.55,4.8);
    paper(mix(-230,215,arrival),385,330,-.17,'application-2',.92);
    paper(mix(1340,855,arrival),460,330,.15,'application-3',.92);ctx.restore();
  }
  if(seconds<12.45)paper(motion.cv.x,motion.cv.y,motion.cv.width,motion.cv.rotation,'cv');
  if(seconds>=3.5&&seconds<9.35)paper(motion.form.x,motion.form.y,motion.form.width,motion.form.rotation,'application-1');
  if(seconds>=7.5){
    if(seconds>=19.25){
      // The retained settings handset moves aside to uncover the final group.
      phone(images[0],motion.summaryProfile,{dim:.22});
      phone(images[1],motion.summaryMatch);
      phone(images[2],motion.phone,{dim:.22*motion.fan});
    }else{
      const settings=motion.matchesToSettings,matched=motion.profileToMatches;
      const image=settings>0?images[1]:matched<1?images[0]:images[1];
      const change=settings>0&&settings<1?{image:images[2],progress:settings}:matched>0&&matched<1?{image:images[1],progress:matched}:null;
      phone(settings===1?images[2]:image,motion.phone,{change,hideMatchCard:motion.cardLift>0});
    }
  }
  if(motion.cardLift>0)liftedCard(motion.phone,motion.cardLift,seconds);
  if(motion.preferenceNote>0){
    const p=motion.preferenceNote;ctx.save();ctx.translate(mix(610,700,p),mix(665,714,p));ctx.scale(p,p);
    rect(0,0,260,93,5,C.sage);text('YOUR PREFERENCES',21,32,11,C.ink,700);text('Your pace.',21,66,26,C.ink,600);ctx.restore();
  }
  const labels=['THE EXPERIENCE IS YOURS.','SAME DETAILS. ANOTHER FORM.','YOUR CV. YOUR STARTING POINT.','SEE THE FIT BEFORE YOU APPLY.','ELIGIBLE EMAIL JOBS / YOUR GMAIL','A LITTLE CLOSER TO YOUR NEXT MOVE.'];
  labels.forEach((label,index)=>{
    const enter=index===0?1:between(seconds,index*4-.45,index*4+.45);
    const leave=index===5?1:1-between(seconds,(index+1)*4-.45,(index+1)*4+.45);
    const visibility=enter*leave*(index<2?1-between(seconds,index*4+.6,index*4+1.4):1);
    if(visibility>0){ctx.save();ctx.globalAlpha=visibility;caption(label,76,924+(1-enter)*12-(1-leave)*12);ctx.restore();}
  });
}
const framing={
  source:'Actual supersampled printed document canvases; no substitute overlay text',
  phonePreviewWidth:PHONE_PREVIEW_WIDTH,filmWidth:W,macroPaperWidth:MACRO_PAPER_WIDTH,
  establishingSeconds:.6,pushSeconds:1.3,
  macroCssSizes:Object.fromEntries([300,260].map(displayWidth=>[displayWidth,Object.fromEntries([['cvName',47],['cvRole',29],['cvJobTitle',24],['formValue',23],['formLabel',16]].map(([name,size])=>[name,Number((size*MACRO_PAPER_WIDTH/PAPER_LAYOUT_WIDTH*displayWidth/W).toFixed(2))]))])),
  chapters:[{chapter:1,kind:'cv',macroStarts:1.9,macroEnds:3.5,topStart:-180,topEnd:-920,readableLines:['Sara Ali','Network Engineer','EXPERIENCE','Network Engineer','Northline Networks / Cairo, Egypt']},{chapter:2,kind:'application-1',macroStarts:6,macroEnds:7.5,topStart:-950,topEnd:-1760,readableLines:['Full name','Sara Ali','Email address','sara.ali@example.com','Current position','Network Engineer','Relevant experience','3 years','Core skills','BGP, OSPF, routing and switching']}]
};
await writeFile(resolve('output/playwright/film-paper-framing-qa.json'),JSON.stringify(framing,null,2)+'\n');
const reversibility=[];
for(const {at} of TRANSITIONS){
  frame(at);const before=createHash('sha256').update(Buffer.from(ctx.getImageData(0,0,W,H).data)).digest('hex');
  frame(at+1);frame(at-1);frame(at);
  const after=createHash('sha256').update(Buffer.from(ctx.getImageData(0,0,W,H).data)).digest('hex');
  if(before!==after)throw Error(`History-dependent rendered frame at ${at}s`);
  reversibility.push({seconds:at,forwardBackwardIdentical:before===after,sha256:before});
}
await writeFile(resolve('output/playwright/film-object-motion-qa.json'),JSON.stringify({transitions:TRANSITIONS,wholeSceneDissolves:false,absoluteTime:true,reversibility,matchCardCrop,safeAreaMatchCardCrop:{x:72,y:1206,width:1035,height:834}},null,2)+'\n');
if(previewOnly){
  const previews=resolve('output/playwright/film-paper-preview');await mkdir(previews,{recursive:true});
  const moments=[0,1.3,2.05,2.8,3.5,4.6,5.3,6.05,6.8,7.5,12.4,14,15.6,...TRANSITIONS.flatMap(({at})=>[-.6,-.3,0,.3,.6].map(offset=>at+offset)),13.35,15,15.7,19.25,20.9,23.9];
  for(const seconds of [...new Set(moments)].sort((a,b)=>a-b)){
    frame(seconds);const name=`${String(seconds).replace('.','-')}s`;
    await writeFile(resolve(previews,`${name}-1080.webp`),await canvas.encode('webp',100));
    for(const size of [PHONE_PREVIEW_WIDTH,260]){
      const phone=createCanvas(size,size);phone.getContext('2d').drawImage(canvas,0,0,size,size);
      await writeFile(resolve(previews,`${name}-${size}.webp`),await phone.encode('webp',100));
    }
  }
  process.stdout.write(`Rendered paper close-up previews in ${previews}\n`);
  process.exit(0);
}
const ffmpeg=spawn(resolve(option('--ffmpeg')),['-hide_banner','-loglevel','warning','-y','-f','rawvideo','-pixel_format','rgba','-video_size',`${W}x${H}`,'-framerate',String(FPS),'-i','pipe:0','-an','-c:v','libx264','-preset','medium','-crf',String(CRF),'-pix_fmt','yuv420p','-g',String(GOP),'-keyint_min',String(GOP),'-sc_threshold','0','-bf','0','-movflags','+faststart',resolve(out,'autolinky-story.mp4')],{stdio:['pipe','ignore','inherit'],windowsHide:true});
const finished=once(ffmpeg,'close');ffmpeg.stdin.on('error',()=>{});
const stillFrames=new Map([2,5.5,10,14,18,23].map((seconds,index)=>[Math.round(seconds*FPS),index+1]));
for(let i=0;i<FPS*DURATION;i++){
  frame(i/FPS);
  if(i===0)await writeFile(resolve(out,'autolinky-story-poster.webp'),await canvas.encode('webp',86));
  if(stillFrames.has(i))await writeFile(resolve(proofs,`chapter-${stillFrames.get(i)}.webp`),await canvas.encode('webp',92));
  if(!ffmpeg.stdin.write(Buffer.from(ctx.getImageData(0,0,W,H).data)))await once(ffmpeg.stdin,'drain');
  if(i%(FPS*2)===0)process.stdout.write(`Rendered ${i}/${FPS*DURATION} frames (${i/FPS}s)\n`);
}
ffmpeg.stdin.end();const [code]=await finished;if(code!==0)throw Error(`FFmpeg failed (${code})`);
process.stdout.write(`Rendered ${DURATION}s / ${W}×${H} / ${FPS}fps / ${FPS*DURATION} frames / GOP ${GOP} / CRF ${CRF}\n`);
