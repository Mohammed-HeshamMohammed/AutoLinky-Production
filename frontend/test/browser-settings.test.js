import { test } from 'node:test';
import assert from 'node:assert/strict';
import { browserBuildSettings } from '../scripts/browser-settings.mjs';

test('both browser builds exclude Firebase and native OAuth registrations even in legacy define files',()=>{
  const supplied={FIREBASE_API_KEY:'legacy-web-key',FIREBASE_APP_ID:'native-or-old-web-id',FIREBASE_PROJECT_ID:'old-project',FIREBASE_LINK_HOST:'old.invalid',GOOGLE_WEB_CLIENT_ID:'native-client',GOOGLE_IOS_CLIENT_ID:'native-ios-client',EMAIL_SIGN_IN:'false'};
  const settings=browserBuildSettings(supplied,{VITE_SITE_URL:'https://web.fixture.invalid',PUBLIC_FIREBASE_API_KEY:'runtime-only-key',GITHUB_TOKEN:'private-token'});
  assert.deepEqual(settings,{EMAIL_SIGN_IN:'false',APPLE_SIGN_IN:'false',API_BASE_URL:'https://web.fixture.invalid',SITE_URL:'https://web.fixture.invalid',TERMS_URL:'https://web.fixture.invalid/terms/',PRIVACY_URL:'https://web.fixture.invalid/privacy/'});
  for(const marker of ['legacy-web-key','native-client','runtime-only-key','private-token'])assert(!JSON.stringify(settings).includes(marker));
  assert.throws(()=>browserBuildSettings({AI_API_KEY:'secret'},{}),/only named public/);
});

test('browser settings keep native inputs unchanged and preserve explicit public API/feature settings',()=>{
  const supplied={API_BASE_URL:'https://compiled.fixture.invalid',FIREBASE_API_KEY:'native-key',EMAIL_SIGN_IN:'false'};
  const before=JSON.stringify(supplied),settings=browserBuildSettings(supplied,{APP_API_BASE_URL:'https://appapi.fixture.invalid'});
  assert.equal(JSON.stringify(supplied),before);assert.equal(supplied.FIREBASE_API_KEY,'native-key');assert.equal(settings.API_BASE_URL,'https://appapi.fixture.invalid');
  assert.throws(()=>browserBuildSettings({},{APP_API_BASE_URL:'https://user:secret@api.invalid'}));
});
