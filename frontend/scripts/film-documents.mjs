import {readFile,writeFile,mkdir} from 'node:fs/promises';
import {resolve} from 'node:path';

// Printed sample documents, baked once before the film renders. Typography stays
// editable; image generation supplies only the blank physical paper material.
export async function renderDocuments({createCanvas,loadImage,GlobalFonts}){
  const data=JSON.parse(await readFile(resolve('scripts/film-document-content.json'),'utf8'));
  const material=await loadImage(resolve('scripts/assets/paper-sheet.png'));
  GlobalFonts.registerFromPath(resolve('scripts/assets/Manrope-Print-400.ttf'),'DocumentBody');
  GlobalFonts.registerFromPath(resolve('scripts/assets/Manrope-Print-700.ttf'),'DocumentHeading');
  const {page,candidate}=data,{width,height,margin}=page;
  const out=resolve('public/assets/film/documents');await mkdir(out,{recursive:true});
  const images={},metrics=[];
  for(const kind of ['cv','cover-letter','application-1','application-2','application-3']){
    const canvas=createCanvas(width,height),c=canvas.getContext('2d');
    // Use only the flat paper face; the generated cutout fringe is outside it.
    c.drawImage(material,90,153,875,1188,0,0,width,height);
    const right=width-margin,bodyWidth=width-margin*2;
    const font=(size,weight)=>`400 ${size}px ${weight>=600?'DocumentHeading':'DocumentBody'}`;
    let lowest=0;
    const text=(s,x,y,size=page.bodySize,weight=450,color=page.ink)=>{
      c.font=font(size,weight);c.fillStyle=color;
      c.fillText(s,x,y);lowest=Math.max(lowest,y);return c.measureText(s).width;
    };
    const line=(y,x=margin,w=bodyWidth,color=page.rule)=>{c.beginPath();c.moveTo(x,y);c.lineTo(x+w,y);c.strokeStyle=color;c.lineWidth=1.2;c.stroke();};
    const wrap=(s,y,{x=margin,w=bodyWidth,size=page.bodySize,weight=450,color=page.ink,leading=page.lineHeight}={})=>{
      c.font=font(size,weight);
      let row='';
      for(const word of s.split(/\s+/)){
        const next=row?`${row} ${word}`:word;
        if(row&&c.measureText(next).width>w){text(row,x,y,size,weight,color);y+=leading;row=word;}else row=next;
      }
      if(row){text(row,x,y,size,weight,color);y+=leading;}
      return y;
    };
    const section=(title,y)=>{text(title.toUpperCase(),margin,y,20,750);line(y+14);return y+50;};
    const header=label=>{
      text(candidate.name,margin,133,page.nameSize,750);
      text(candidate.role,margin,177,page.titleSize,500);
      text(`${candidate.location}   /   ${candidate.email}`,margin,216,18,450,page.mutedInk);
      line(247);text(label,margin,286,16,700,page.mutedInk);
    };
    if(kind==='cv'){
      header(data.cv.documentLabel);
      let y=wrap(data.cv.summary,334,{size:21,leading:31})+31;
      y=section('Experience',y);
      for(const job of data.cv.experience){
        text(job.title,margin,y,24,750);
        c.textAlign='right';text(job.dates,right,y,17,500,page.mutedInk);c.textAlign='left';
        text(`${job.company} / ${job.location}`,margin,y+31,19,500,page.mutedInk);y+=69;
        for(const bullet of job.bullets){text('•',margin+2,y,21,600);y=wrap(bullet,y,{x:margin+22,w:bodyWidth-22,size:20,leading:29});}
        y+=28;
      }
      y=section('Education & certification',y);
      y=wrap(data.cv.education.title,y,{size:22,weight:700,leading:32});
      y=wrap(`${data.cv.education.institution} / ${data.cv.education.dates}`,y,{size:18,color:page.mutedInk,leading:30});
      y=wrap(data.cv.certification,y+6,{size:20,leading:30})+35;
      y=section('Technical skills',y);
      y=wrap(data.cv.skills.join('  /  '),y,{size:21,leading:32})+28;
      text(data.cv.languages,margin,y,19,450,page.mutedInk);
    }else if(kind==='cover-letter'){
      const letter=data.coverLetter;header(letter.documentLabel);
      text(letter.date,margin,345,20,450,page.mutedInk);
      let y=400;for(const row of letter.recipient){text(row,margin,y,21,500);y+=31;}
      y=wrap(letter.subject,y+37,{size:25,weight:750,leading:35})+25;
      text(letter.salutation,margin,y,22,500);y+=49;
      for(const paragraph of letter.paragraphs)y=wrap(paragraph,y,{size:22,leading:35})+28;
      text(letter.closing,margin,y+8,22,450);text(letter.signature,margin,y+49,29,700);
      text(letter.attachment,margin,y+100,18,450,page.mutedInk);
    }else{
      const i=Number(kind.at(-1))-1,form=data.applications[i];
      text(form.company,margin,132,31,750);
      text(form.department,margin,170,19,450,page.mutedInk);line(201);
      text(form.documentLabel,margin,246,16,700,page.mutedInk);
      text(form.role,margin,295,30,700);
      text(`Position reference: ${form.reference}`,margin,331,18,450,page.mutedInk);
      let y=397;
      for(const [index,group] of form.sections.entries()){
        text(`0${index+1}   ${group.title.toUpperCase()}`,margin,y,20,750);line(y+15);y+=54;
        // A printed form uses compact ruled fields, rather than UI input cards.
        for(const field of group.fields){
          text(field.label,margin,y,16,500,page.mutedInk);
          text(field.value,margin,y+30,23,550);line(y+43);y+=80;
        }
        y+=31;
      }
    }
    const contentBottom=lowest;
    if(contentBottom>height-100)throw Error(`${kind}: document content overlaps footer (${contentBottom})`);
    line(height-76);text(page.footer,margin,height-43,13,550,page.mutedInk);
    c.textAlign='right';text('1 / 1',right,height-43,13,450,page.mutedInk);c.textAlign='left';
    const bytes=await canvas.encode('webp',94);await writeFile(resolve(out,`${kind}.webp`),bytes);
    images[kind]=canvas;metrics.push({kind,width,height,contentBottom,footerY:height-43,bytes:bytes.length});
  }
  await writeFile(resolve('output/playwright/film-documents-qa.json'),JSON.stringify({paperMaterial:'scripts/assets/paper-sheet.png',sourceCrop:{x:90,y:153,width:875,height:1188},fictionalSampleData:true,documents:metrics},null,2)+'\n');
  return images;
}
