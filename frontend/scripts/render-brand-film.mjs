// Offline source for the landing film. No rendering dependencies are shipped to the browser.
// Usage: node scripts/render-brand-film.mjs --modules <node_modules> --ffmpeg <binary>
import {createRequire} from 'node:module';
import {resolve} from 'node:path';
import {mkdir,readFile,writeFile} from 'node:fs/promises';
import {spawn} from 'node:child_process';
import {once} from 'node:events';
import {renderDocuments} from './film-documents.mjs';

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
const W=1080,H=1080,FPS=24,DURATION=24;
const canvas=createCanvas(W,H),ctx=canvas.getContext('2d');
const C={bg:'#171c19',paper:'#eeeade',ink:'#252d28',dim:'#94a095',line:'#343d36',sage:'#bed2a8',blue:'#315bd6'};
const clamp=x=>Math.max(0,Math.min(1,x));
const ease=x=>{x=clamp(x);return x*x*(3-2*x);};
const mix=(a,b,t)=>a+(b-a)*t;
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
function phone(image,x,y,width,rotation=0,alpha=1,zoom=1){
  const outerWidth=width+18,scale=outerWidth/device.width,height=outerWidth*device.height/device.width;
  const left=-outerWidth/2,top=-height/2,screen=device.screen;
  const sx=left+screen.x*scale,sy=top+screen.y*scale,sw=screen.width*scale,sh=screen.height*scale;
  ctx.save();ctx.globalAlpha*=alpha;ctx.translate(x,y);ctx.rotate(rotation);ctx.scale(zoom,zoom);
  ctx.shadowColor='#00000080';ctx.shadowBlur=40;ctx.shadowOffsetY=28;
  ctx.drawImage(hardware,left,top,outerWidth,height);ctx.shadowColor='transparent';
  ctx.save();ctx.beginPath();ctx.roundRect(sx,sy,sw,sh,screen.radius*scale);ctx.clip();
  ctx.fillStyle=device.background;ctx.fillRect(sx,sy,sw,sh);
  const fit=Math.min(sw/image.width,sh/image.height),iw=image.width*fit,ih=image.height*fit;
  ctx.drawImage(image,sx+(sw-iw)/2,sy+(sh-ih)/2,iw,ih);ctx.restore();
  ctx.drawImage(hardware,left,top,outerWidth,height);ctx.restore();
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
function scene(index,t){
  const p=ease(t),drift=Math.sin(t*Math.PI)*10;
  if(index===0){
    paper(682+drift,483,365,.13+mix(.02,-.02,p),'application-1',.86);
    paper(359-drift,584,365,-.16,'cover-letter',.94);
    paper(545,536-mix(0,18,p),405,mix(-.04,.025,p),'cv');
    caption('THE EXPERIENCE IS YOURS.',98,924);
  }else if(index===1){
    paper(mix(310,215,p),mix(410,385,p),330,-.17,'application-2',.92);
    paper(mix(770,855,p),mix(440,460,p),330,.15,'application-3',.92);
    paper(535,560,390,mix(.07,-.035,p),'application-1');
    rect(330,852,420,59,3,C.sage);text('Same details. Another form.',362,890,22,C.ink,600);
  }else if(index===2){
    paper(mix(362,243,p),610,310,mix(-.1,-.16,p),'cv',.94);
    phone(images[0],mix(620,605,p),mix(559,529,p),328,mix(.05,.015,p));
    caption('YOUR CV. YOUR STARTING POINT.',76,924);
  }else if(index===3){
    phone(images[1],540,mix(563,526,p),359,mix(-.035,.015,p));
    // Real screen crop, kept separate from the device so the fit is legible.
    ctx.save();ctx.translate(mix(749,767,p),mix(427,410,p));ctx.rotate(.025);
    ctx.shadowColor='#00000050';ctx.shadowBlur=24;ctx.shadowOffsetY=14;
    rect(-193,-100,386,209,13,'#fff');ctx.shadowColor='transparent';
    ctx.beginPath();ctx.roundRect(-193,-100,386,209,13);ctx.clip();ctx.drawImage(matchDetail,48,688,690,374,-193,-100,386,209);ctx.restore();
    caption('SEE THE FIT BEFORE YOU APPLY.',76,924);
  }else if(index===4){
    phone(images[2],mix(552,526,p),mix(550,524,p),354,mix(.035,-.02,p));
    rect(700,714,260,93,5,C.sage);text('YOUR PREFERENCES',721,746,11,C.ink,700);text('Your pace.',721,780,26,C.ink,600);
    caption('ELIGIBLE EMAIL JOBS / YOUR GMAIL',76,924);
  }else{
    phone(images[0],mix(404,298,p),590,263,mix(-.05,-.09,p),.58);
    phone(images[2],mix(685,794,p),590,263,mix(.06,.09,p),.58);
    phone(images[1],540,mix(554,525,p),346,0);
    caption('A LITTLE CLOSER TO YOUR NEXT MOVE.',76,924);
  }
}
function frame(seconds){
  const chapter=Math.min(5,Math.floor(seconds/4)),local=seconds%4;
  backdrop(seconds);
  // Cross dissolve with shared camera motion: every frame belongs to a continuous film.
  if(chapter>0&&local<.65){
    const fade=ease(local/.65);ctx.save();ctx.globalAlpha=1-fade;scene(chapter-1,1);ctx.restore();
    ctx.save();ctx.globalAlpha=fade;scene(chapter,local/4);ctx.restore();
  }else scene(chapter,local/4);
}
const ffmpeg=spawn(resolve(option('--ffmpeg')),['-hide_banner','-loglevel','warning','-y','-f','rawvideo','-pixel_format','rgba','-video_size',`${W}x${H}`,'-framerate',String(FPS),'-i','pipe:0','-an','-c:v','libx264','-preset','medium','-crf','23','-pix_fmt','yuv420p','-g','12','-keyint_min','12','-sc_threshold','0','-bf','0','-movflags','+faststart',resolve(out,'autolinky-story.mp4')],{stdio:['pipe','ignore','inherit'],windowsHide:true});
const finished=once(ffmpeg,'close');ffmpeg.stdin.on('error',()=>{});
for(let i=0;i<FPS*DURATION;i++){
  frame(i/FPS);
  if(i===0)await writeFile(resolve(out,'autolinky-story-poster.webp'),await canvas.encode('webp',86));
  if([48,132,240,336,432,552].includes(i))await writeFile(resolve(proofs,`chapter-${Math.floor(i/96)+1}.webp`),await canvas.encode('webp',92));
  if(!ffmpeg.stdin.write(Buffer.from(ctx.getImageData(0,0,W,H).data)))await once(ffmpeg.stdin,'drain');
  if(i%96===0)process.stdout.write(`Rendered chapter ${Math.floor(i/96)+1}/6\n`);
}
ffmpeg.stdin.end();const [code]=await finished;if(code!==0)throw Error(`FFmpeg failed (${code})`);
process.stdout.write(`Rendered ${DURATION}s / ${W}×${H} / ${FPS}fps\n`);
