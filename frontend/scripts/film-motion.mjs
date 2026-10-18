// Absolute-time choreography: the same frame is used in both scroll directions.
export const FILM_SECONDS=24;
export const TRANSITIONS=[
  {at:4,start:3.5,end:4.8,action:'The CV pulls back as the next application slides onto the desk.'},
  {at:8,start:7.5,end:8.9,action:'The form leaves the desk while the profile phone arrives beside the CV.'},
  {at:12,start:11.35,end:13.35,action:'The same phone slides to matches and lifts its complete first card.'},
  {at:16,start:15,end:17,action:'The card returns to its exact screen position before preferences slide in.'},
  {at:20,start:19.25,end:20.9,action:'The settings phone fans right to reveal matches, with profile on the left.'},
];
export const clamp=value=>Math.max(0,Math.min(1,value));
export const ease=value=>{const p=clamp(value);return p*p*(3-2*p);};
export const mix=(a,b,p)=>a+(b-a)*p;
export const between=(seconds,start,end)=>ease((seconds-start)/(end-start));

// Each point is [seconds, x, y, width, rotation]. Coordinates remain continuous
// through every chapter; no scene is reset when a chapter number changes.
const cv=[
  [0,545,536,405,-.04],[.6,544,533,405,-.035],
  [1.9,1171.2,1658.2,2600,0],[3.5,1171.2,918.2,2600,0],
  [4.8,243,610,310,-.16],[10.9,237,602,310,-.14],
  [12.45,-240,710,270,-.22],
];
const form=[
  [3.5,1460,568,390,.12],[4.8,535,560,390,.045],
  [6,1171.2,888.2,2600,0],[7.5,1171.2,78.2,2600,0],
  [8.65,330,620,270,-.11],[9.35,-310,655,250,-.16],
];
const handset=[
  [7.5,1340,620,300,.11],[8.9,620,550,328,.025],
  [10.9,605,529,328,.015],[12.75,540,546,359,-.025],
  [15,540,534,359,.005],[17,536,540,354,.018],
  [19.25,540,550,354,-.02],[20.9,794,590,263,.09],
  [24,806,581,263,.09],
];

export function track(points,seconds){
  const end=points.findIndex(point=>point[0]>=seconds);
  if(end===0||end===-1){const point=points[end===0?0:points.length-1];return {x:point[1],y:point[2],width:point[3],rotation:point[4]};}
  const a=points[end-1],b=points[end],p=between(seconds,a[0],b[0]);
  const values=a.slice(1).map((value,index)=>mix(value,b[index+1],p));
  return {x:values[0],y:values[1],width:values[2],rotation:values[3]};
}

export function filmMotion(seconds){
  const t=Math.max(0,Math.min(FILM_SECONDS,seconds));
  const fan=between(t,19.25,20.9);
  return {
    cv:track(cv,t),form:track(form,t),phone:track(handset,t),
    openingStack:1-between(t,.6,1.9),
    formStack:between(t,3.55,4.8)*(1-between(t,5,6)),
    profileToMatches:between(t,11.35,12.55),
    matchesToSettings:between(t,15.85,17),
    cardLift:between(t,12.6,13.35)*(1-between(t,15,15.7)),
    preferenceNote:between(t,17,17.8)*(1-between(t,18.9,19.45)),
    fan,
    summaryMatch:{x:540,y:mix(550,525,between(t,19.25,24)),width:mix(320,346,fan),rotation:0},
    summaryProfile:{x:mix(540,298,fan),y:mix(550,590,fan),width:263,rotation:mix(0,-.09,fan)},
  };
}
