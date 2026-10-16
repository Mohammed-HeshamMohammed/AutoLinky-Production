const element=node=>Array.isArray(node)&&node.length===4&&node[0]==='$'&&node[3]&&typeof node[3]==='object'&&!Array.isArray(node[3]);
const authorURLs=blob=>[...blob.matchAll(/(?:"|https:\/\/(?:www\.|[a-z]{2}\.)?linkedin\.com)\/(in|company)\/([^"?\\/#]+)/g)].map(m=>`https://www.linkedin.com/${m[1]}/${m[2]}`);
function mostCommon(values){const counts=new Map();for(const value of values)counts.set(value,(counts.get(value)||0)+1);let best=null,count=0;for(const [value,n] of counts)if(n>count){best=value;count=n;}return best;}
function textOf(node,rows,out,depth=0){
  if(depth>80)return;
  if(typeof node==='string'){const ref=/^\$([0-9a-f]+)$/.exec(node);if(ref&&rows.has(ref[1]))textOf(rows.get(ref[1]),rows,out,depth+1);else if(node.startsWith('$$'))out.push(node.slice(1));else if(!node.startsWith('$'))out.push(node);}
  else if(element(node)){if(node[1]==='br')out.push('\n');else textOf(node[3].children,rows,out,depth+1);}
  else if(Array.isArray(node))for(const value of node)textOf(value,rows,out,depth+1);
}
function walk(node,fn,depth=0){if(depth>80||!node||typeof node!=='object')return;if(fn(node)===false)return;for(const value of Object.values(node))walk(value,fn,depth+1);}
export function parsePosts(stream){
  const rows=new Map(),raw=new Map(),children=new Map(),parent=new Map();
  for(const line of stream.split('\n')){const match=/^([0-9a-f]+):(.*)$/.exec(line);if(!match)continue;raw.set(match[1],match[2]);if('["{'.includes(match[2][0])&&match[2])try{rows.set(match[1],JSON.parse(match[2]));}catch{}}
  for(const [id,line] of raw){const kids=[...line.matchAll(/"\$[A-Z@]?([0-9a-f]+)"/g)].map(m=>m[1]);children.set(id,kids);for(const kid of kids)if(kid!==id&&!parent.has(kid)&&id!=='0')parent.set(kid,id);}
  function containerOf(id){const seen=new Set([id]);while(parent.has(id)&&!seen.has(parent.get(id))){id=parent.get(id);seen.add(id);}return id;}
  function subtree(root){const seen=new Set(),stack=[root];while(stack.length){const id=stack.pop();if(seen.has(id)||!raw.has(id)||id==='0')continue;seen.add(id);for(const child of children.get(id)||[])if(!seen.has(child))stack.push(child);}return seen;}
  const groups=new Map();
  for(const [id,row] of rows){const blocks=[];walk(row,node=>{if(element(node)){const props=node[3];if(typeof props.expansionKey==='string'&&props.expansionKey.startsWith('expandable_text_block')&&props.textProps&&typeof props.textProps==='object'){blocks.push(props.textProps);return false;}}});
    if(!blocks.length)continue;const container=containerOf(id);if(!groups.has(container))groups.set(container,{texts:[],mailto:[],textRows:new Set()});const entry=groups.get(container);entry.textRows.add(id);
    for(const block of blocks){const parts=[];textOf(block.children,rows,parts);const text=parts.join('').replace(/\n{3,}/g,'\n\n').trim();if(text&&!entry.texts.includes(text))entry.texts.push(text);walk(block,node=>{for(const [key,value] of Object.entries(node))if(key==='url'&&typeof value==='string'&&value.toLowerCase().startsWith('mailto:'))entry.mailto.push(value);});}
  }
  const posts=[];for(const [container,entry] of groups){if(!entry.texts.length)continue;const sub=subtree(container),blob=[...sub].map(id=>raw.get(id)).join('\n'),urn=mostCommon(blob.match(/urn:li:(?:activity|ugcPost):\d+/g)||[]),textSubtree=new Set([...entry.textRows].flatMap(id=>[...subtree(id)])),mentions=new Set(authorURLs([...textSubtree].map(id=>raw.get(id)).join('\n'))),author=mostCommon(authorURLs(blob).filter(url=>!mentions.has(url))),outside=[...sub].filter(id=>!textSubtree.has(id)).map(id=>raw.get(id)).join('\n');
    posts.push({text:entry.texts.join('\n\n'),urn,url:urn?`https://www.linkedin.com/feed/update/${urn}/`:null,author_url:author,mailto:[...new Set(entry.mailto)],attached_jobs:[...new Set([...outside.matchAll(/\/jobs\/view\/(\d+)/g)].map(m=>m[1]))].map(id=>`https://www.linkedin.com/jobs/view/${id}/`),contacts:[]});
  }return posts;
}
