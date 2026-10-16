import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import fc from 'fast-check';
import * as sq from '../../Fetching-backend/src/collector/search-query.js';
const fixture=JSON.parse(await readFile(new URL('fixtures/search-query-parity.json',import.meta.url),'utf8'));
test('search phrases, Unicode cleanup, country grouping and exact query labels match the original Python outputs',()=>{
  for(const item of fixture.cases) {
    assert.equal(sq.clean(item.title),item.clean,item.title);
    assert.equal(sq.plural(item.title),item.plural,item.title);
    assert.deepEqual(sq.phrasesFor(item.title,item.synonyms),item.phrases,item.title);
    assert.deepEqual(sq.placeGroups(item.locations),item.groups,item.title);
    assert.deepEqual(sq.searches(item.title,item.locations,item.synonyms),item.searches,item.title);
  }
});
test('arbitrary title punctuation cannot escape the query or exceed its operator budget',()=>{
  fc.assert(fc.property(fc.string({maxLength:100}),title=>{
    const queries=sq.searches(title,[{keyword:'egypt',country:'Egypt'},{keyword:'cairo',country:'Egypt'}],['network engineer','noc engineer']);
    for(const [query] of queries) {
      assert(sq.operators(query)<=sq.MAX_OPERATORS);
      assert.equal([...query.matchAll(/"/g)].length%2,0);
      assert.equal([...query.matchAll(/\(/g)].length,[...query.matchAll(/\)/g)].length);
    }
  }),{seed:49421,numRuns:200});
  assert.equal(sq.operators('("sales OR marketing" OR "x") egypt'),1);
});
