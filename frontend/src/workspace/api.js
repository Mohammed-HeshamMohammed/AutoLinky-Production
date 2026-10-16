export class APIError extends Error{
  constructor(status,detail,{uncertain=false}={}){super(typeof detail==='string'?detail:'The request could not be completed.');this.status=status;this.detail=detail;this.uncertain=uncertain;}
}
export function createClient({getToken,fetcher=fetch}={}){
  return async(path,{method='GET',body,headers={},signal}={})=>{
    if(!/^\/(v1\/|admin\/api\/)/.test(path)||path.includes('\\')||path.includes('#'))throw Error('Invalid API path');
    const token=await getToken?.(),binary=body instanceof Blob||body instanceof ArrayBuffer||ArrayBuffer.isView(body);
    let response;
    try{response=await fetcher(path,{method,credentials:'omit',redirect:'error',headers:{...(token?{Authorization:`Bearer ${token}`}:{ }),...(body!==undefined&&!binary?{'Content-Type':'application/json'}:{}),...headers},body:body===undefined?undefined:binary?body:JSON.stringify(body),signal:signal?AbortSignal.any([signal,AbortSignal.timeout(90000)]):AbortSignal.timeout(90000)});}
    catch(error){if(signal?.aborted)throw error;throw new APIError(0,'The connection was interrupted.',{uncertain:!['GET','HEAD'].includes(method)});}
    const value=response.status===204?null:await response.json().catch(()=>null);
    if(!response.ok)throw new APIError(response.status,value?.detail||'The service is unavailable.',{uncertain:response.status>=500&&!['GET','HEAD'].includes(method)});
    return value;
  };
}
export function friendlyError(error,ar=false){
  if(error?.uncertain)return ar?'تعذر تأكيد النتيجة. حدّث البيانات قبل المحاولة مرة أخرى.':'We could not confirm the outcome. Refresh the data before trying again.';
  const messages={no_profile:['Set up your profile to find your matches.','أكمل ملفك لعرض الوظائف المناسبة.'],no_cv:['Upload your CV to get started.','ارفع سيرتك الذاتية للبدء.'],cv_needed:['Upload a CV before applying by email.','ارفع سيرة ذاتية قبل التقديم بالبريد.'],email_not_connected:['Connect your Gmail in Auto Apply first.','اربط Gmail من صفحة التقديم التلقائي أولاً.'],email_invalid:['Your Gmail connection needs attention.','اتصال Gmail يحتاج إلى مراجعة.'],free_limit:['You have reached your email allowance.','وصلت إلى حد رسائل البريد المتاح.'],daily_limit:['You have reached your daily sending limit.','وصلت إلى الحد اليومي للإرسال.'],deletion_blocked:['An email is still being processed. Check its status before deleting your account.','هناك رسالة قيد المعالجة. راجع حالتها قبل حذف حسابك.'],already_sent:['This application is already being sent or has been sent.','هذا الطلب قيد الإرسال أو تم إرساله.'],cv_too_large:['Choose a PDF or DOCX smaller than 4 MB.','اختر PDF أو DOCX أصغر من ٤ ميجابايت.'],ai_unavailable:['CV analysis is unavailable right now. Your existing CV is still saved.','تحليل السيرة غير متاح الآن. سيرتك الحالية محفوظة.'],admin_not_configured:['Administrator access has not been configured. Contact the owner.','وصول الإدارة غير مهيأ. تواصل مع المالك.'],invalid_login:['The sign-in details could not be verified.','تعذر التحقق من بيانات الدخول.'],reauth_required:['Confirm your password and authenticator code to continue.','أكد كلمة المرور ورمز المصادقة للمتابعة.'],changed_meanwhile:['This record changed. Refresh it before saving again.','تغير هذا السجل. حدّث الصفحة قبل الحفظ.']};
  if(messages[error?.message])return messages[error.message][ar?1:0];
  if(error?.status===401)return ar?'انتهت الجلسة. سجل الدخول مجددًا.':'Your session has expired. Sign in again.';
  if(error?.status===403)return ar?'ليس لديك صلاحية لهذا الإجراء.':'You do not have permission for this action.';
  if(error?.status===429)return ar?'طلبات كثيرة. انتظر قليلًا ثم حاول مجددًا.':'Too many requests. Wait a little and try again.';
  if(error?.status===409&&String(error.message).includes('Profile needed'))return ar?'أكمل الأدوار والمهارات في ملفك أولاً.':'Add your roles and skills in Profile first.';
  return error?.status===0||error?.status>=500?(ar?'تعذر الاتصال بالخدمة. حاول مجددًا بعد قليل.':'We could not reach the service. Try again shortly.'):(ar?'تعذر إكمال الطلب. راجع البيانات وحاول مجددًا.':'We could not complete that request. Check the details and try again.');
}
export function safeExternal(value){try{const url=new URL(value);return ['http:','https:'].includes(url.protocol)&&!url.username&&!url.password?url.href:null;}catch{return null;}}
