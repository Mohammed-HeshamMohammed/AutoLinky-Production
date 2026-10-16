// Only these public fields may cross the server/browser boundary.
export function publicSettings(env=process.env){
  const fields={apiKey:'API_KEY',authDomain:'AUTH_DOMAIN',projectId:'PROJECT_ID',storageBucket:'STORAGE_BUCKET',messagingSenderId:'MESSAGING_SENDER_ID',appId:'APP_ID'};
  const firebase=Object.fromEntries(Object.entries(fields).map(([field,key])=>[field,String(env[`PUBLIC_FIREBASE_${key}`]||'').trim()]));
  if(Object.values(firebase).some(value=>!value||value.length>512||/[\s<>"']/.test(value)))throw Error('Public Firebase configuration is incomplete');
  for(const field of ['authDomain','storageBucket'])if(!/^[a-z0-9](?:[a-z0-9.-]*[a-z0-9])?$/i.test(firebase[field]))throw Error('Invalid public Firebase domain');
  if(!/^[a-z0-9-]+$/i.test(firebase.projectId)||!/^\d+$/.test(firebase.messagingSenderId))throw Error('Invalid public Firebase identity');
  const sdk=new URL(env.PUBLIC_FIREBASE_SDK_BASE_URL||'');
  if(sdk.protocol!=='https:'||sdk.username||sdk.password||sdk.search||sdk.hash||!sdk.pathname.endsWith('/'))throw Error('Invalid public Firebase SDK URL');
  return {firebase,sdkBaseUrl:sdk.href};
}

export function availablePublicSettings(env=process.env){try{return publicSettings(env);}catch{return null;}}
