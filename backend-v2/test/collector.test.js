import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { parsePosts } from '../../Fetching-backend/src/collector/post-parser.js';
import { parseSearch,parseDetails } from '../../Fetching-backend/src/collector/job-parser.js';
import { urnTime,postTooOld,listingTooOld } from '../../Fetching-backend/src/collector/job-age.js';
const fixture=JSON.parse(await readFile(new URL('./fixtures/collector-parity.json',import.meta.url)));
test('post RSC parsing, mentions, mailto and attached jobs match the original Python fixture exactly',()=>{
  assert.deepEqual(parsePosts(fixture.posts.input),fixture.posts.expected);
  assert.deepEqual(parsePosts(''),[]);assert.deepEqual(parsePosts('0:broken'),[]);
});
test('guest-job HTML parsing and detail fields match the original Python fixture exactly',()=>{
  assert.deepEqual(parseSearch(fixture.jobs.input),fixture.jobs.expected);
  assert.deepEqual(parseDetails(fixture.details.input),fixture.details.expected);
  assert.deepEqual(parseSearch(''),[]);assert.equal(parseDetails('').description,null);
});
test('LinkedIn timestamps use BigInt and preserve the 14-day cutoff and unknown-age behavior',()=>{
  const now=new Date('2026-10-12T12:00:00Z'),date=new Date('2026-10-01T08:30:00Z'),urn=`urn:li:activity:${BigInt(+date)<<22n}`;
  assert.deepEqual(urnTime(urn),date);assert.equal(urnTime('urn:li:activity:1'),null);
  assert.equal(postTooOld(`urn:li:activity:${BigInt(+now-15*86400000)<<22n}`,now),true);
  assert.equal(listingTooOld('2026-09-28',now),false);assert.equal(listingTooOld('2026-09-27',now),true);assert.equal(listingTooOld('2026-02-30',now),false);
});
