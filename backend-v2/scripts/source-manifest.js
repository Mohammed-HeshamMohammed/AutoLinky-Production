import { readFile,writeFile } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const root=fileURLToPath(new URL('../../',import.meta.url));
const evidence=new URL('../../migration-plan/evidence/',import.meta.url);
const baseline=JSON.parse(await readFile(new URL('source-baseline.json',evidence),'utf8'));
const modules={
  'backend/main.py':['backend-v2/src/app.js'],
  'backend/auth.py':['backend-v2/src/http/auth.js'],
  'backend/db.py':['backend-v2/src/db/client.js'],
  'backend/config.py':['backend-v2/src/config.js'],
  'backend/ratelimit.py':['backend-v2/src/http/rate-limit.js'],
  'backend/textnorm.py':['backend-v2/src/shared/text.js'],
  'backend/skillmatch.py':['backend-v2/src/shared/skillmatch.js'],
  'backend/catalog.py':['backend-v2/src/services/catalog.js'],
  'backend/countries.py':['backend-v2/src/shared/countries.js'],
  'backend/billing.py':['backend-v2/src/services/billing.js'],
  'backend/cv_ai.py':['backend-v2/src/ai/cv-analysis.js','backend-v2/src/ai/prompts/cv-system.txt'],
  'backend/cv_file.py':['backend-v2/services/cv-extractor/cv_file.py'],
  'backend/mail_secret.py':['backend-v2/src/email/secret.js'],
  'backend/mailer.py':['backend-v2/src/email/gmail.js','backend-v2/src/email/composition.js'],
  'backend/letter_ai.py':['backend-v2/src/ai/cover-letters.js','backend-v2/src/ai/prompts/letter-system.txt'],
  'backend/application_email.py':['backend-v2/src/email/delivery.js'],
  'backend/auto_apply.py':['backend-v2/src/workers/auto-apply.js'],
  'backend/sender.py':['backend-v2/src/sender.js'],
  'backend/routers/health.py':['backend-v2/src/app.js'],
  'backend/routers/me.py':['backend-v2/src/app.js'],
  'backend/routers/taxonomy.py':['backend-v2/src/http/routes/catalog.js'],
  'backend/routers/jobs.py':['backend-v2/src/http/routes/jobs.js'],
  'backend/routers/cv.py':['backend-v2/src/http/routes/cv.js'],
  'backend/routers/profile.py':['backend-v2/src/http/routes/profile.js'],
  'backend/routers/applications.py':['backend-v2/src/http/routes/applications.js'],
  'backend/routers/email_apply.py':['backend-v2/src/http/routes/email-apply.js'],
  'backend/routers/devices.py':['backend-v2/src/http/routes/devices.js'],
  'collector/jobs_search.py':['backend-v2/src/collector/job-parser.js','backend-v2/src/collector/job-age.js'],
  'collector/post_extract.py':['backend-v2/src/collector/post-parser.js'],
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
