import { readFile,writeFile } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const root=fileURLToPath(new URL('../../../',import.meta.url));
const evidence=new URL('../../../migration-plan/evidence/',import.meta.url);
const baseline=JSON.parse(await readFile(new URL('source-baseline.json',evidence),'utf8'));
const modules={
  'backend/main.py':['Gateway-backene/src/app.js','Auth-backend/app.js','App-backend/app.js','Notify-backend/app.js'],
  'backend/auth.py':['Auth-backend/src/auth.js'],
  'backend/db.py':['Data-baceknd/lib/db/client.js'],
  'backend/config.py':['Auth-backend/lib/config.js'],
  'backend/ratelimit.py':['Auth-backend/lib/http/rate-limit.js'],
  'backend/textnorm.py':['App-backend/lib/domain/text.js'],
  'backend/skillmatch.py':['App-backend/lib/domain/skillmatch.js'],
  'backend/catalog.py':['App-backend/src/catalog.js'],
  'backend/countries.py':['App-backend/lib/domain/countries.js'],
  'backend/billing.py':['Notify-backend/src/billing.js'],
  'backend/cv_ai.py':['App-backend/src/ai/cv-analysis.js','App-backend/src/ai/prompts/cv-system.txt'],
  'backend/cv_file.py':['App-backend/extractor/cv_file.py'],
  'backend/mail_secret.py':['Notify-backend/src/email/secret.js'],
  'backend/mailer.py':['Notify-backend/src/email/gmail.js','Notify-backend/src/email/composition.js'],
  'backend/letter_ai.py':['Notify-backend/src/ai/cover-letters.js','Notify-backend/src/ai/prompts/letter-system.txt'],
  'backend/application_email.py':['Notify-backend/src/email/delivery.js'],
  'backend/auto_apply.py':['Notify-backend/src/auto-apply.js'],
  'backend/sender.py':['Notify-backend/sender.js'],
  'backend/routers/health.py':['Gateway-backene/src/app.js','Auth-backend/app.js','App-backend/app.js','Notify-backend/app.js'],
  'backend/routers/me.py':['Gateway-backene/src/app.js','Auth-backend/app.js','App-backend/app.js','Notify-backend/app.js'],
  'backend/routers/taxonomy.py':['App-backend/src/routes/catalog.js'],
  'backend/routers/jobs.py':['App-backend/src/routes/jobs.js'],
  'backend/routers/cv.py':['App-backend/src/routes/cv.js'],
  'backend/routers/profile.py':['App-backend/src/routes/profile.js'],
  'backend/routers/applications.py':['Notify-backend/src/routes/applications.js'],
  'backend/routers/email_apply.py':['Notify-backend/src/routes/email-apply.js'],
  'backend/routers/devices.py':['Notify-backend/src/routes/devices.js'],
  'collector/jobs_search.py':['Fetching-backend/src/collector/job-parser.js','Fetching-backend/src/collector/job-age.js'],
  'collector/post_extract.py':['Fetching-backend/src/collector/post-parser.js'],
};
async function digest(relative) {
  const target=path.resolve(root,relative);
  if(!target.startsWith(path.resolve(root)+path.sep))throw Error('Manifest target outside production workspace');
  try{return {path:relative,sha256:createHash('sha256').update(await readFile(target)).digest('hex')};}
  catch(error){if(error.code==='ENOENT')return {path:relative,missing:true};throw error;}
}
const files=[];
for(const [workspace,value] of Object.entries(baseline)) {
  if(!value.files)continue;
  for(const [source,sha256] of Object.entries(value.files)) {
    let destinations=[],status='pending',note='No completed port is asserted for this file.';
    if(workspace==='reference') {
      if(source.startsWith('migration-plan/')){destinations=[source];status='copied_specification';note='Reference specification; link targets may point back to the read-only source.';}
      else if(source==='mobile/lib/core/storage/secure_session_storage.dart'){destinations=['mobile apps/shared/lib/core/storage/email_link_store.dart'];status='replaced_with_sdk_session_and_pending_email_storage';note='Firebase owns the session and the previous local session is cleared.';}
      else if(source==='mobile/lib/features/auth/presentation/verify_code_screen.dart'){destinations=['mobile apps/shared/lib/features/auth/presentation/email_link_screen.dart'];status='replaced_with_email_link_flow';note='The native email-link flow deliberately replaces the old six-digit experience.';}
      else if(source.startsWith('mobile/android/')){destinations=['mobile apps/Android app/android/'+source.slice('mobile/android/'.length)];status='android_platform_project';note='Native Android project; Flutter screens and update configuration come from shared.';}
      else if(source.startsWith('mobile/ios/Runner/Assets.xcassets/')){destinations=['mobile apps/IOS app/Resources/Assets.xcassets/'+source.slice('mobile/ios/Runner/Assets.xcassets/'.length)];status='preserved_ios_branding';note='Original icon/image resources in the independent Swift app.';}
      else if(source.startsWith('mobile/ios/')){destinations=['mobile apps/IOS app/project.yml','mobile apps/IOS app/Sources/AutoLinkyApp.swift'];status='replaced_with_native_swiftui';note='The Flutter runner is replaced by an independent native app. See native feature and verification evidence; a destination pointer is not parity certification.';}
      else if(source.startsWith('mobile/web/')){destinations=['frontend/web-template/'+source.slice('mobile/web/'.length)];status='shared_browser_host_template';note='Browser hosts are generated from this template in the unified frontend.';}
      else if(source.startsWith('mobile/')){destinations=['mobile apps/shared/'+source.slice(7)];status='copied_client_with_firebase_changes';note='Client changes and local tests are recorded separately; native/device release gates remain open.';}
      else if(modules[source]){destinations=modules[source];status='implemented_partial_parity';note='A source module can cover more behavior than the mapped implementation. This is not full parity certification.';}
      else if(source.startsWith('website/api/')){destinations=['frontend/api/'+source.slice('website/api/'.length)];status='adapted_to_current_vps_site';note='The destination uses the existing production React website and a Node VPS server.';}
      else if(source.startsWith('supabase/')||source.startsWith('selfhost/')){status='historical_migration_input';note='Native SQL/auth/CV replacements are tested separately; no legacy service is activated or deleted.';}
    } else if(source==='frontend/README.md'){destinations=['frontend/docs/WEBSITE.md'];status='adapted_website_instructions';note='The original README is retained at baseline commit 52a996c; canonical frontend instructions replace it with owner authorization.';} else if(source.startsWith('frontend/')) {
      destinations=['frontend/'+source.slice('frontend/'.length)];status='copied_current_production_site';note='Canonical unified frontend; original bytes retained at baseline commit 52a996c and the local archive.';
    }
    files.push({workspace,source,source_sha256:sha256,status,note,destinations:await Promise.all(destinations.map(digest))});
  }
}
const missing=files.flatMap(file=>file.destinations.filter(destination=>destination.missing).map(destination=>`${file.source} -> ${destination.path}`));
const result={generated_at:new Date().toISOString(),scope:'Source inventory and destination pointers, not a completion certificate',reference_commit:baseline.reference.commit,files,missing_destinations:missing};
await writeFile(new URL('source-to-destination.json',evidence),JSON.stringify(result,null,2)+'\n');
console.log(`${files.length} original files inventoried; ${missing.length} mapped destination(s) missing`);
for(const value of missing)console.log(value);
if(missing.length)process.exitCode=1;
