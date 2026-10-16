export function registerCatalog(app,{db,cache}) {
  app.get('/v1/taxonomy',async()=>cache.load('taxonomy:public',3600000,async()=>{
    const [fields,roles,skills]=await Promise.all([
      db.query('SELECT slug,name_en,name_ar,icon FROM public.job_fields WHERE active ORDER BY sort_order'),
      db.query('SELECT slug,field,name_en,name_ar FROM public.job_roles WHERE active ORDER BY sort_order'),
      db.query('SELECT slug,name,skill_group AS "group" FROM public.skills WHERE active ORDER BY skill_group,name'),
    ]);
    return {fields:fields.rows,roles:roles.rows,skills:skills.rows};
  },{cacheIf:value=>value.fields.length>0}));
}
