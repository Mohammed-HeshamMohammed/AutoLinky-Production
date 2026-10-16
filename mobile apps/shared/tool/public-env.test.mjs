import { test } from 'node:test';
import assert from 'node:assert/strict';
import { publicMobileSettings } from './public-env.mjs';
test('mobile environment output includes only named public inputs and omits secrets and empty overrides',()=>{
  assert.deepEqual(publicMobileSettings({API_BASE_URL:'https://appapi.fixture.invalid',SITE_URL:'https://site.fixture.invalid',FIREBASE_APP_ID:'',AI_API_KEY:'private-ai',GOOGLE_APPLICATION_CREDENTIALS:'private.json',MAIL_SECRET_KEY:'private-mail',PUBLIC_ADMIN_KEY:'private-prefix'}),{API_BASE_URL:'https://appapi.fixture.invalid',SITE_URL:'https://site.fixture.invalid'});
});
