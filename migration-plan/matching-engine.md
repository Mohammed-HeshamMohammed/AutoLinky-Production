# Normalization, cleanup and deduplication engine

Owns the design for adapting DataForge's cleaning and matching engine (`X:\dataforge\workers\matching`: `normalize.py`, `phone.py`, `cleanup.py`, `engine.py`, `likelihood.py`, `ranking.py`) to Autolinky's data. It supersedes the short notes in [DataForge adoption](dataforge-adoption.md) and the backlog line E24 in the [efficiency plan](database-efficiency.md). The engine is the owner's own project (confirmed by the owner on 2026-10-15), so there is no licence barrier to porting or reusing any of it. DataForge's Python is kept as the **reference implementation** for parity tests, never as a runtime dependency. Nothing here is built, and no existing result changes until the activation gates in section 9 pass.

## 1. What DataForge's engine does

| Part | Capability |
| --- | --- |
| `normalize.py` (v1.3.0) | Role-based, versioned, pure normalization: Unicode folding, e-mail canonical form (case, `+tag` removal at providers that ignore tags, Gmail dots), phone keys through libphonenumber, URL canonicalization (host, `www`, tracking parameters, query sorting), postal codes, addresses, person names (titles, suffixes, particles, nicknames, Soundex). Raw values are never modified |
| `phone.py` | One way to read a phone number using libphonenumber: calling codes, validity, number type, `00`/`011` prefix handling, human-readable reasons |
| `cleanup.py` (v1.0.0) | Per-column standardization with `invalid`/`placeholder` verdicts, placeholder lists (`n/a`, `null`, `#N/A`), junk-row detection (empty, test, exact duplicates), e-mail checks (syntax, no-reply and test locals, common domain typos), OpenRefine-style key-collision clustering of variant spellings (fingerprint, n-gram fingerprint, company key without legal suffixes) |
| `engine.py` (policy-versioned) | Blocking keys with a maximum block size (oversized blocks are reported, never compared quadratically); field-level evidence (`exact`, `similar`, `different`, `conflict`) with strengths (`strong`, `supporting`, `guard`); weighted score; conservative decision (`match`, `possible_match`, `non_match`) where any guard blocks a merge and auto-match needs strong evidence plus at least two comparable fields; constrained union-find clustering (must-link, must-not-link, locked groups, rejection of "bridge" merges supported by a single link); canonical record selection with survivor order, field provenance and conflict reporting; metrics that never contain row values |
| `likelihood.py` | Fellegi-Sunter probability estimated from the data itself (chance agreement from random pairs, term frequency so common values count less, expectation-maximization for field reliability); it orders and annotates review, it never merges |
| `ranking.py` | A small logistic model trained on human review decisions (needs at least 20 labels with both outcomes) used only to order the review queue |

Measured by DataForge: about 48,500 person rows matched in about 3.4 seconds on plain Python with RapidFuzz.

## 2. Where it fits Autolinky

What exists today: exact deduplication only (`post_urn`, a text fingerprint in `hiring_posts`, `job_id` in `linkedin_jobs`); a text normalizer that already folds Arabic (`backend/textnorm.py`: tatweel, `ة→ه`, `ى→ي`, alef forms); contact extraction by pattern (`collector/contacts.py`); a placeholder list for classifier output (`collector/classifier.py`); and **no recipient quality check** (a search for no-reply, test or placeholder addresses finds nothing outside the classifier lists), so applications can be sent to addresses that will bounce or never be read.

| Autolinky need | DataForge capability that serves it | Value |
| --- | --- | --- |
| The same job appears more than once: reposted by a recruiter with different wording, or found both as a post and as a guest listing | Blocking + evidence + conservative clustering + canonical selection | Fewer rows, hosted-AI calls, cache scores and duplicate cards in feeds; one job showing every way to apply |
| Sending applications to bad addresses | E-mail cleanup rules (syntax, `..`, no-reply and test locals, known-typo domains) | Fewer bounces, protects the shared sending domain's reputation (Release 2) |
| Contact quality | libphonenumber analysis (validity, type), placeholder numbers, e-mail canonicalization | Better apply-method accuracy (mobile vs landline for WhatsApp), reliable contact keys for blocking |
| Company names vary ("Vodafone Egypt", "VODAFONE EGYPT - Cairo") | Company key without legal suffixes, fingerprint and n-gram fingerprint | A stable company key for blocking, filters, letters and reports |
| Spelling variants in locations, titles, companies | Key-collision clustering with a suggested canonical spelling | Data-quality report in the admin console; input to `search_locations` and title classification clean-up |
| Reviewing uncertain duplicates | Evidence explanations, likelihood, learned queue ordering, must/must-not-link, locks, undo | An audited review panel for operators |

Not needed: person-name matching (nickname tables, Soundex, given-name logic), postal-code and US-state rules, spreadsheet-damage repair, import mapping roles. These stay in the reference.

## 3. Adaptations required (do not port blindly)

1. **Arabic and mixed-script text.** DataForge folds with `unicodedata.normalize("NFKD", …).encode("ascii", "ignore")`, which **deletes Arabic letters entirely**. The port must use Unicode-aware tokenization (`\p{L}`, `\p{N}`), keep the Arabic folding already proven in `backend/textnorm.py`, and test Arabic company names, titles and cities explicitly.
2. **Region.** Default phone region is Egypt (`EG`), with the Gulf scopes (`SA`, `AE`, `QA`, `KW`, `BH`, `OM`) when the search scope says so; `00` and `+` prefixes handled; not the US-centric `011`.
3. **Company legal forms.** Start from DataForge's Latin suffix list and add Arabic and Gulf/Egyptian forms (for example `ش.م.م`, `شركة`, `S.A.E`, `LLC`, `FZE`, `Co.`, `Ltd`); the list is reviewed by a native speaker before activation.
4. **Entity type is "job", not "person".** Weights, strengths and guards are redefined for jobs (section 5); thresholds are starting values calibrated on a labeled set.
5. **Incremental, not batch.** DataForge processes a whole dataset; Autolinky adds a few hundred jobs an hour into a rolling 14-day window, so candidate lookup is done per new job through an indexed key table.
6. **Determinism and stable keys.** Existing IDs, fingerprints and search-query keys are untouched. New keys are additive and versioned.
7. **Libraries.** `libphonenumber-js` for phones; string similarity (token-sort ratio, Jaro-Winkler) implemented in plain JavaScript or a small pinned package and **verified against RapidFuzz outputs on a shared corpus** (tolerance recorded before comparing).

## 4. Components

| Module (under `backend-node/src/`) | Contents | Notes |
| --- | --- | --- |
| `shared/normalize/` | `tidy`, `fold` (Arabic-aware), `email`, `phone` (via libphonenumber-js), `url`, `companyKey`, `fingerprint`, `ngramFingerprint`, `titleKey` (kept identical to the SQL `search_title_key`) | Pure functions with a `NORMALIZATION_VERSION`; raw values untouched |
| `shared/cleanup/` | Placeholder lists, e-mail quality verdicts, phone placeholder patterns, variant clustering with a suggested spelling | `CLEANUP_VERSION`; verdicts are `ok`, `invalid`, `placeholder`, `suspect` |
| `dedupe/blocking.js` | Key generation and the oversize guard | Keys listed in section 5 |
| `dedupe/evidence.js` | Field comparisons, strengths, weights, guards | Evidence texts name fields, never values |
| `dedupe/decide.js` | `match` / `possible_match` / `non_match` | Conservative policy, `POLICY_VERSION` |
| `dedupe/cluster.js` | Constrained union-find, bridge rejection, locks | Operates on the small affected component per new job |
| `dedupe/canonical.js` | Survivor order, merged contacts and apply methods, provenance, conflicts | Never deletes a member |
| `dedupe/likelihood.js`, `dedupe/ranking.js` | Fellegi-Sunter estimates and a review-ordering model | Activated only with enough review volume (sections 8, 9) |
| `dedupe/run.js` | Orchestration for the enricher: incremental path and a batch path for evaluation | Batch path runs in the worker-thread pool from the [search pipeline](search-concurrency.md) |

## 5. Job evidence model (starting policy)

**Blocking keys** (a job may have several): `email:<canonical>`, `phone:<e164>`, `url:<canonical apply link>`, `co_title:<companyKey>|<titleKey>`, `co_loc:<companyKey>|<country>|<first title token>`. Blocks larger than 200 members (agencies sharing one mailbox) are reported and skipped for that key.

| Field | Comparison | Strength |
| --- | --- | --- |
| Identifier (`post_urn`, `job_id`) | equal | strong; different identifiers are not a conflict across sources |
| Apply link | equal canonical URL | strong when company agrees, otherwise supporting |
| E-mail / phone | shared canonical value | supporting alone (a recruiter posts many roles from one mailbox), strong only together with a title or company agreement |
| Company | equal `companyKey`, or token-sort ratio at least 0.92 | supporting; **guard** if both present and similarity below 0.6 |
| Title | equal `titleKey`, or token-sort ratio at least 0.85 | supporting; **guard** if both present and similarity below 0.5 (same mailbox, different role) |
| Location | city/country agreement | supporting; **guard** on different countries unless either is remote |
| Text | shingle Jaccard or token-set similarity of descriptions | supporting; strong at 0.9 or higher with company and title agreeing |
| Posted time | within the 14-day window | weak, only breaks ties |

Decision rules mirror DataForge's: any guard means non-match; auto-match needs strong evidence, a weighted score at or above the strictness threshold (conservative 0.95, balanced 0.90) and at least two comparable fields; strong evidence below the threshold or a score above the review threshold (0.75 / 0.70) goes to review. Clustering refuses unions that would put conflicting companies or countries in one group and rejects bridges supported by a single link between two groups of two or more.

## 6. Data model (post-parity, created only when the tier is activated)

| Object | Purpose |
| --- | --- |
| `job_keys (opportunity_id → opportunities ON DELETE CASCADE, key text)` | Unlogged, rebuildable index of blocking keys; primary key `(key, opportunity_id)` |
| `job_dupes (left_id, right_id → opportunities ON DELETE CASCADE, decision, score, likelihood, evidence jsonb, reason, state, decided_by, decided_at, version)` | One row per compared pair that is not a trivial non-match; `state` is `auto`, `review`, `confirmed` or `rejected`; `left_id < right_id` |
| `dedupe_constraints (left_id, right_id → opportunities ON DELETE CASCADE, kind, reason, created_by, created_at)` | Operator decisions: `must_link`, `must_not_link`; locked groups are expressed as must-links with a lock flag in `kind` |
| `opportunities.canonical_id uuid REFERENCES opportunities(id) ON DELETE SET NULL` | Survivor of the cluster; null means the row is canonical or unclustered. If the survivor is purged first, members become standalone again |

With the tier the schema grows by 3 tables, 19 columns on them, 1 column on `opportunities` and 5 foreign keys (49 tables, 401 columns, 38 foreign keys including the existing target). All rows disappear with their jobs in the 14-day purge, so no extra retention rule is needed.

## 7. Behavior when active

- Feeds, facets and `match_profile` consider `canonical_id IS NULL` rows only, so duplicates stop appearing; this is a scoring-SQL change delivered in its own migration with parity tests that compare results with the flag off.
- The canonical job shows the union of contacts and apply methods of its members (more ways to apply), with provenance of which source supplied each.
- Application state is looked up across the cluster, so a user who applied through one posting sees "applied" on the canonical card. `applications.opportunity_id` and the existing 30-day same-recipient cooldown are unchanged.
- Nothing is deleted. A mistaken merge is undone by clearing `canonical_id` and adding a `must_not_link`.

## 8. Admin console additions ([admin dashboard plan](admin-dashboard.md))

A **Duplicates** panel: mode (`off`, `shadow`, `active`, owner only) and strictness; counts (auto-merged, review backlog, oversize blocks, bridge rejections, cluster-size distribution, false-merge reports); a review queue ordered by likelihood (later by the learned ranking), each item showing the two jobs side by side with the evidence list; actions: confirm merge, keep separate, split a cluster, lock a group, undo (all audited, operators can review, owners change mode). A read-only **Data quality** report lists variant-spelling clusters for company, city and title with a suggested canonical spelling; applying a spelling choice (alias table) is a later, separate step.

## 9. Activation gates

| Stage | Setting | Requirement |
| --- | --- | --- |
| Offline | none | Engine and normalization libraries pass parity and property tests; the evaluation harness runs on a restored copy |
| Shadow | `dedupe.mode = shadow` | Decisions and metrics are computed and stored but feeds, matching and AI calls are unchanged. Runs at least 14 days. Records the duplicate rate and review volume |
| Labeled evaluation | none | Operators label at least 300 pairs (stratified across auto-match, review and non-match). Targets: **no false merge in a review of 300 sampled auto-matches (precision at least 99% with the confidence interval reported)**, recall reported, guard reasons reasonable |
| Active | `dedupe.mode = active` | Duplicate rate above the 5% trigger from the efficiency plan; labeled targets met; scoring migration parity with the flag off; rollback tested (set `off`, clear `canonical_id`) |
| Likelihood and ranking | `dedupe.ranking = on` | At least 100 reviewed pairs for likelihood calibration and 20 labels with both outcomes for the ranking model; ordering only, never merging |

## 10. Recipient quality gate (Release 2)

Adopted independently of deduplication because it protects the shared sending domain. Before a reservation is created, the recipient address gets a verdict from the cleanup rules:

| Verdict | Examples | Action |
| --- | --- | --- |
| `invalid` | Syntax failure, `..`, missing domain | Refuse the send with a clear reason |
| `placeholder` | `noreply`, `no-reply`, `donotreply`, `test`, `fake`, `email@email.com` locals | Refuse; role mailboxes such as `hr@` or `jobs@` are allowed |
| `suspect` | Known-typo domains (for example `gmial.com`) | Show the suggested correction in the preview and ask the user to confirm; **never correct silently** |
| Optional | Domain has no MX record (DNS lookup cached for 24 hours) | Refuse with a "cannot receive mail" reason; enabled only if bounce measurements justify it |

The verdict is recorded on the attempt's refusal (no new table), checked together with the suppression list in the same admission step.

## 11. Tests and evaluation

- **Parity:** run the reference Python and the JavaScript on the same corpora (e-mails, phones, URLs, company names, Arabic strings, job pairs); normalization outputs must match exactly, similarities within the recorded tolerance, decisions identical.
- **Property tests (fast-check):** normalization is idempotent and independent of formatting; evidence is symmetric where the policy is; clustering never joins a must-not-link pair; blocks never exceed the cap; canonical selection is stable under input order.
- **Golden sets:** hand-labeled job pairs including recruiter reposts, same-mailbox different roles (must stay separate), same company different cities, Arabic and English versions of the same job.
- **Metrics (never containing row values):** decisions by kind and scope, guard reasons, block sizes, cluster sizes, stage seconds, rows per second, review backlog, false-merge reports.
- **Performance budget:** incremental path under 50 ms p95 per new job at the planning load; full-window batch re-evaluation of 50,000 rows under 60 seconds in the worker pool; both measured on the rehearsal copy.

## 12. Risks

| Risk | Mitigation |
| --- | --- |
| A false merge hides a real job from users | Conservative policy, guards, shadow mode, labeled precision gate, reversible, never deletes, locks and must-not-link |
| Agency mailboxes create huge blocks | Block size cap and oversize reporting; contact alone is never strong |
| Arabic text mishandled | Unicode-aware port with explicit Arabic tests and `textnorm` parity |
| Scoring change alters match results | Own migration, flag-off parity tests, activation only after review |
| Added write load on enrichment | Unlogged key table, per-job work bounded by block caps, measured in the load test |
| Cost of review labor | Review queue is small by construction; ranking orders it; auto-match threshold stays high |
