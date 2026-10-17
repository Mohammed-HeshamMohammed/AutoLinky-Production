function integer(env, name, fallback, min, max) {
  const n = Number(env[name] ?? fallback);
  if (!Number.isInteger(n) || n < min || n > max) throw new Error(`Invalid ${name}`);
  return n;
}
function flag(env,name,fallback=false) {
  const value=env[name];
  if (value === undefined || value === '') return fallback;
  if (['true','1'].includes(value)) return true;
  if (['false','0'].includes(value)) return false;
  throw new Error(`Invalid ${name}`);
}
export function loadConfig(env = process.env,{database=true,identity=true}={}) {
  const production=env.NODE_ENV === 'production';
  const origins=(env.CORS_ALLOWED_ORIGINS || '').split(',').map(s=>s.trim()).filter(Boolean);
  for (const origin of origins) {
    const url=new URL(origin);
    if (url.origin!==origin || (production && url.protocol!=='https:')) throw new Error('CORS origins must be exact trusted origins');
  }
  if (production && env.FIREBASE_AUTH_EMULATOR_HOST) throw new Error('Firebase emulator is forbidden in production');
  if (production && ((identity&&!env.FIREBASE_PROJECT_ID)||(database&&!env.PG_DATABASE_URL))) throw new Error('Production requires the service Firebase/PostgreSQL configuration');
  const notice=flag(env,'SERVICE_NOTICE') ? {
    en: { title:env.SERVICE_NOTICE_TITLE_EN || "We're making Autolinky better",body:env.SERVICE_NOTICE_BODY_EN || "We're updating our services right now, so some things may be slow or unavailable for a little while. Your account and everything you saved are safe, and we'll be back very soon. Thank you for your patience!" },
    ar: { title:env.SERVICE_NOTICE_TITLE_AR || 'نعمل على تحسين Autolinky',body:env.SERVICE_NOTICE_BODY_AR || 'نقوم الآن بتحديث خدماتنا، لذلك قد تكون بعض الأشياء أبطأ أو غير متاحة لفترة قصيرة. حسابك وكل ما حفظته في أمان، وسنعود قريبًا جدًا. شكرًا لصبرك!' },
  } : null;
  return Object.freeze({
    production,version:'0.5.10',serviceName:env.SERVICE_NAME||'api',host:env.HOST || '127.0.0.1',port:integer(env,'PORT',4000,1,65535),
    databaseUrl:env.PG_DATABASE_URL || '',poolMax:integer(env,'PG_POOL_MAX',8,1,20),
    statementTimeout:integer(env,'PG_STATEMENT_TIMEOUT_MS',5000,100,30000),
    firebaseProjectId:env.FIREBASE_PROJECT_ID || '',origins,notice,
    rateLimit:integer(env,'RATE_LIMIT_PER_MINUTE',120,1,10000),
    internalDownloadsKey:env.INTERNAL_DOWNLOADS_KEY || '',
    cvMaxBytes:4*1024*1024,aiKey:env.AI_API_KEY || '',aiBaseUrl:env.AI_BASE_URL || '',
    cvModel:env.CV_AI_MODEL || '',letterModel:env.LETTER_AI_MODEL || '',
    mailSecretKey:env.MAIL_SECRET_KEY || '',senderEnabled:flag(env,'SENDER_ENABLED'),collectorEnabled:flag(env,'COLLECTOR_ENABLED'),
    senderHours:env.AUTO_APPLY_HOURS||'0-24',senderTimezone:env.SENDER_TIMEZONE||'Africa/Cairo',
    freeEmails:integer(env,'FREE_EMAILS',20,0,100000),dailyEmails:integer(env,'EMAIL_DAILY_LIMIT',100,1,500),
    upgradeUrl:env.UPGRADE_URL || '',upgradeMessage:env.UPGRADE_MESSAGE || 'Hello, I want to subscribe',
  });
}
