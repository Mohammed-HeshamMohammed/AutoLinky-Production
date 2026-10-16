// Public Firebase web configuration. Private Admin/provider secrets stay on Auth.
const config={apiKey:'AIzaSyBdqjxSr3ZCXI-QmDOovZrJILf3kEr-R5s',authDomain:'auto-linky.firebaseapp.com',projectId:'auto-linky',storageBucket:'auto-linky.firebasestorage.app',messagingSenderId:'218018023814',appId:'1:218018023814:web:f019dda9f6205e2973c407'};
let pending;
export function firebaseSession(){
  pending||=Promise.all([
    import(/* @vite-ignore */ 'https://www.gstatic.com/firebasejs/13.0.0/firebase-app.js'),
    import(/* @vite-ignore */ 'https://www.gstatic.com/firebasejs/13.0.0/firebase-auth.js'),
  ]).then(async([app,sdk])=>{
    const auth=sdk.getAuth(app.getApps().length?app.getApp():app.initializeApp(config));
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
