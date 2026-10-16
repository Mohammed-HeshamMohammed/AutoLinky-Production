export const overlayPath='/internal/v1/applications/overlay';
export async function applicationOverlay(db,user_id,ids){
  if(!ids.length)return [];
  const rows=(await db.query('SELECT opportunity_id,method,status,created_at FROM public.applications WHERE user_id=$1 AND opportunity_id=ANY($2::uuid[])',[user_id,ids])).rows;
  return rows.map(row=>({...row,status:row.status==='sending'?'queued':row.status}));
}
export function registerApplicationAPI(app,{db}){
  app.post(overlayPath,{schema:{body:{type:'object',additionalProperties:false,required:['user_id','ids'],properties:{user_id:{type:'string',format:'uuid'},ids:{type:'array',maxItems:100,items:{type:'string',format:'uuid'}}}}}},request=>applicationOverlay(db,request.body.user_id,request.body.ids));
}
