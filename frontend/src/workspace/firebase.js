let pending;
export function firebaseSession(){
  pending||=fetch('/api/config',{cache:'no-store',credentials:'same-origin'}).then(async response=>{
    if(!response.ok)throw Error('Sign-in configuration is unavailable');
    const {firebase,sdkBaseUrl}=await response.json();
    const [app,sdk]=await Promise.all([
      import(/* @vite-ignore */ `${sdkBaseUrl}firebase-app.js`),
      import(/* @vite-ignore */ `${sdkBaseUrl}firebase-auth.js`),
    ]);
    const auth=sdk.getAuth(app.getApps().length?app.getApp():app.initializeApp(firebase));
    await sdk.setPersistence(auth,sdk.indexedDBLocalPersistence);
    return {auth,sdk};
  }).catch(error=>{pending=null;throw error;});
  return pending;
}
export function signInMessage(error,ar=false){
  const code=error?.code||'';
  if(['auth/popup-closed-by-user','auth/cancelled-popup-request'].includes(code))return '';
  if(['auth/operation-not-allowed','auth/unauthorized-domain','auth/invalid-api-key'].includes(code))return ar?'طريقة الدخول غير متاحة لهذا الموقع بعد. تواصل مع الدعم.':'This sign-in method is not available for this website yet. Contact support.';
  if(['auth/invalid-action-code','auth/expired-action-code'].includes(code))return ar?'انتهت صلاحية الرابط. اطلب رابطًا جديدًا.':'This sign-in link has expired. Request a new link.';
  return ar?'تعذر تسجيل الدخول. تحقق من الاتصال وحاول مجددًا.':'Sign-in could not be completed. Check your connection and try again.';
}
