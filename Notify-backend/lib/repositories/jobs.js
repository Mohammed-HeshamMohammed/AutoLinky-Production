export const summaryColumns='id,source,title,company,city,country,country_code,work_mode,level,employment_type,field,role,skills,apply_methods,language,snippet,url,posted_at';
const columns=summaryColumns.split(',');
export function summary(row) {
  const result=Object.fromEntries(columns.map(name=>[name,row[name]??(['skills','apply_methods'].includes(name)?[]:null)]));
  return {...result,application:null};
}
