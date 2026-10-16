export function workspaceHeaders({development=false,settings=null}={}){
  const sdk=settings?` ${new URL(settings.sdkBaseUrl).origin}`:'';
  const auth=settings?` https://${settings.firebase.authDomain}`:'';
  return {'Cache-Control':'no-store','X-Robots-Tag':'noindex, nofollow','Referrer-Policy':'no-referrer','X-Frame-Options':'DENY',
    'Content-Security-Policy':`default-src 'self'; script-src 'self'${sdk}; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; img-src 'self' data: https://lh3.googleusercontent.com; font-src 'self' https://fonts.gstatic.com; connect-src 'self' https://*.googleapis.com https://*.google.com${auth}${sdk}${development?' ws://localhost:* ws://127.0.0.1:*':''}; frame-src https://accounts.google.com${auth}; object-src 'none'; base-uri 'self'; form-action 'self'; frame-ancestors 'none'`};
}
