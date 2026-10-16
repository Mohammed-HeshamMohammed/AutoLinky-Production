# AI token efficiency plan

Goal: spend as few AI tokens as possible while keeping every AI-produced result at today's quality. "Same level" is enforced by measurable non-inferiority gates (section 6), not by judgment: any change that is not proven at least as good on a fixed evaluation set does not ship. Related: [matching engine](matching-engine.md) (near-duplicate reuse), [admin dashboard](admin-dashboard.md) (AI usage and controls), [DataForge adoption](dataforge-adoption.md), [roadmap](implementation-roadmap.md).

## 1. Baseline: where tokens go today

Sources: the code (`collector/ai_batch.py`, `title_ai.py`, `requirements_ai.py`, `skill_ai.py`, `classifier.py`, `backend/cv_ai.py`, `letter_ai.py`, `config.py`), `collector/settings.toml`, `scripts/eval_ai.py`, `docs/ai-cost-analysis.md` (analysis of 2026-10-08, partly implemented since) and commit `03a4857`. Costs are the repository's own measurements or estimates; prices must be re-checked at implementation time.

| Task | Where | Model today | Unit cost (as measured or estimated) | What drives volume |
| --- | --- | --- | --- | --- |
| Post classification (is it hiring, title, level, company, city, country, remote) | collector, batches of 5, line output | `google/gemini-2.5-flash-lite` | about 290 input tokens and 20 output tokens per post, about $0.038 per 1,000 posts | New, non-duplicate posts that pass the free pre-filters (12-31% of posts read) |
| Job requirements reading (required/preferred skills, min years, education) | collector, batches of 5, JSON | `openai/gpt-6-luna` without thinking (83% F1 on required skills; flash-lite 76%) | about $0.059 per 1,000 jobs | Jobs "someone could be shown" (Step 16), once per content hash |
| Title to role classification | collector | flash-lite | about 0.5 cent per cycle; the 86-role list is about 920 tokens per call | New normalized titles, batched |
| Skill learning | collector | `google/gemini-2.5-flash` | about 1 cent per 150 names | New skill names seen in 3+ ads, every 6 hours |
| Cover letters | backend/sender | `google/gemini-2.5-flash` | about 2,300 input tokens typical (CV up to 9,000 characters plus post up to 3,500), 300-400 output, about 0.16-0.45 cent each (the backend README says about 0.25) | One per auto-applied e-mail and per first "Send my CV" preview; 300/day global guard |
| CV analysis | backend | `google/gemini-2.5-flash` | 2,750-5,000 input tokens (CV up to 15,000 characters plus the 86-role list), 250-400 output, about 0.16-0.45 cent | Once per new CV file; 500/day global guard |
| Embeddings | local E5 service | none (own CPU) | no token cost | - |

Per unit, **a letter or CV analysis costs 40 to 100 times a post classification**; per cycle the collector's volume dominates. Both must be addressed, but the order of effort follows unit cost times volume.

## 2. Already in place and to be preserved in the port

These are why the collector bill is already low; the Node port must reproduce them exactly and prove it with parity tests (section 8):

- Cheap model for posts, batch size 5 (more tokens saved at 8 but "the cheap model got sloppier on titles"), hold up to 30 s to fill a batch (except for a new user's searches), compact post text (head 1,100 plus tail 350 characters, links, emails, phones and emoji removed), line answers with a token cap of `60n + 40`.
- Answering without thinking on every collector call (`no_thinking`), `temperature = 0`, and the provider flag `data_collection: deny`.
- Result caches that prevent paying twice: `post_verdicts` (including "not hiring"), `job_requirements` keyed by content hash `md5(title || '\n' || left(body, 2500))`, `title_classifications` by `title_key`, letters per user, job and CV hash, CV analysis per file hash.
- Free gates before the model: a pre-filter (`worth_classifying`), a 14-day age gate from the post URN (`post_too_old`), listing age gate for jobs, and Step 16 "requirements are read only for jobs someone could be shown", with skipped jobs re-checked only after profile or statistics changes.
- Budgets: `CV_AI_DAILY_LIMIT = 500`, `LETTER_AI_DAILY_LIMIT = 300`, per-user hourly and daily limits, and rules-only fallbacks.
- Measured choices that were tested and dropped, so they are not retried: line answers for requirements (lost 10-15 points on preferred skills), reading requirements inside the classifier request (lost 15), shorter requirement text windows, `date_posted = past-24h`, batches larger than 5 for posts.

## 3. Levers

Savings are hypotheses labelled by evidence; each is measured by the gates in section 6 before it is kept.

### A. Do not call the model

| ID | Change | Evidence / expected effect | Quality risk | When |
| --- | --- | --- | --- | --- |
| A1 | **Reuse for identical or near-identical text before the call.** Posts: look up the text fingerprint (`fp:`) in the verdict cache before the model, not only after (the analysis found 16-37% of AI-classified posts produced no new row because the same text arrived under a new URN). Requirements: reuse the stored answer of an identical content hash (the analysis estimated 5-15%); extend to near-duplicates through the [matching engine](matching-engine.md) (same company, title and high text similarity) | Posts: 10-25% fewer classification calls for exact text, more with near-duplicates; requirements 5-15%+ | None for exact fingerprints (same text, same answer); near-duplicate reuse only after the engine's labeled precision gate | Exact: after Release 1 parity; near-duplicate: with the dedupe tier |
| A2 | **Retry caps and parking.** At most 3 attempts per item (title, ad, post); a batch that fails is re-asked item by item once, then the item is parked with a reason and a re-check date; no retry loop across enricher cycles | Closes the "poison item re-sent every run" hole (the analysis could not rule out 8-30 cents/day per stuck batch) | None | Release 1 (part of the AI client) |
| A3 | **Known-lookup failure handling.** If the "already classified" lookup fails, do not send the batch; retry the verdict write once | Avoids paying twice during database hiccups | None | Release 1 |
| A4 | **Junk, test and placeholder gate** from the DataForge cleanup rules (empty, placeholder, test-word entries) before the model, in addition to today's pre-filter | Small; cheap to add; measured by an "AI avoided: junk" counter | Very low (only entries that are clearly not real) | After parity |
| A5 | **Cheap eligibility first for letters:** run every inexpensive check (recipient quality gate, suppression list, quotas, cooldown, CV present, reservation feasibility) before writing a letter, so letters are never paid for and then discarded when the address is refused or the claim fails | The current flow writes the letter before the claim and send checks; refused addresses waste a letter | None | Release 2 |

### B. Ask code or a small local model instead

| ID | Change | Evidence / expected effect | Quality risk | When |
| --- | --- | --- | --- | --- |
| B1 | **Title to role by embeddings first.** Keep all AI-labelled titles with their E5 vectors (the embedder already runs locally); a new title takes the role of its nearest labelled neighbour when cosine similarity is above a calibrated threshold and the neighbours agree; otherwise ask the model. Add a noise-free cache key (strip gender tags, remote/hybrid markers, seniority words) so trivial variants share one answer | Fewer title calls (the analysis estimated 20-40% for the key alone); title AI is about 0.5 cent per cycle, so the absolute gain is small | Low when the threshold keeps role accuracy at the current level on the evaluation set | After parity |
| B2 | **Rules first for requirement fields that rules can read exactly:** minimum years ("3+ years") and education when stated in an explicit requirements section; skills stay with the model because rules "cannot tell required from a plus" and miss unknown skills | Smaller prompts for fields the model need not read; measured against the 83% F1 baseline before use | Medium; accepted only if F1 and years/education agreement are not lower | Evaluate after parity; adopt only if proven |
| B3 | **Pre-screen classifier for "is it hiring"** (a small logistic model in the style of DataForge's `ranking.py`) | **Rejected on evidence:** after the free pre-filters about four in five posts that reach the model are genuine hiring posts (for example 15 of 19 in a logged search), and the model's real work is extracting title, level, company and city, which rules do less well than the 93% role accuracy now achieved. The pattern is kept (versioned model, holdout evaluation, deterministic training hash) in case the evaluation shows a safe skip band | - | Not planned |

### C. Send fewer input tokens

| ID | Change | Evidence / expected effect | Quality risk | When |
| --- | --- | --- | --- | --- |
| C1 | **Role shortlist in prompts.** Title and CV prompts carry the whole 86-role list (about 920 tokens, 77% of the title prompt). Rank roles by embedding similarity and keywords and send the top K (for example 15) plus a fallback to the full list when confidence is low | CV analysis: about 700 tokens saved per CV; title calls: most of the repeated prompt | The right role missing from the shortlist; gate: shortlist recall at least 99.5% on the evaluation set | After parity |
| C2 | **Letters from structured facts, not raw text.** The CV is analyzed once into structured fields (`detected`: roles, skills, level, years, headline). Build the letter prompt from a compact per-user profile (headline, years, top skills, 3 best experience lines chosen for the job) and the job's stored requirements (required skills, years, title, company) instead of the full CV (about 1,500 tokens) and raw post (up to 875) | Input falls from about 2,300 to roughly 600 tokens per letter (hypothesis) | Invented claims or generic letters; gated by a deterministic grounding check (every skill or employer named in the letter must exist in the user's CV data) and a blind quality comparison | After parity, Release 1 tuning wave |
| C3 | **Trim the ad tail** (benefits, company boilerplate, equal-opportunity text) before requirements reading (already read from the requirements part of the ad; extend with the analysis's P8) | Fewer tokens per ad (the earlier requirements-part change cut 36%) | Cutting a real "nice to have" section; gated by preferred-skill F1 | After parity |
| C4 | **Static-first prompts** (system prompt, roles list and the user's CV facts first, variable job text last) so provider prefix caching can apply; remove "Today is ..." from the start of prompts | 0-15% on letters; free to try | None | After parity |
| C5 | **Shorter system prompts** only with an evaluation; never trim rules the model needs (the classifier prompt's own comments record failures from changes) | Small | Accuracy | Only if the gates pass |

### D. Ask for fewer output tokens

| ID | Change | Evidence / expected effect | Quality risk | When |
| --- | --- | --- | --- | --- |
| D1 | **Letters:** switch off thinking for the letter and CV calls (the collector already does; the backend sends no reasoning setting, so Gemini 2.5 Flash's default thinking is probably billed as output); reject a letter whose `finish_reason` is `length` (today a cut-off letter over 90 words is stored and sent) | 40-60% of a letter's cost if thinking is on (check the sender log: totals well above about 3,600 tokens mean it is) | Small; the finish check also improves quality | Release 1 tuning wave, behind an A/B |
| D2 | **Letters:** let the model write only the body paragraphs; greeting, closing and signature are composed by code (already built from the CV contacts in `application_email.py`) | Fewer output tokens | None if the prompt already forbids those parts (it does) | With C2 |
| D3 | Keep line formats where measured not to lose accuracy (posts yes; requirements no) | Already decided | - | - |

### E. Right model for each task

| ID | Change | Rule |
| --- | --- | --- |
| E1 | Cascade for formats: ask the cheap model first, escalate one tier only for an item whose answer fails parsing or validation twice (instead of asking the same model again) | Only where escalation fixes more items than it costs |
| E2 | Letters on `flash-lite` instead of `flash` (75-88% cheaper per the analysis) | Only if 100 (CV, job) pairs show **zero** additional invented claims and blind quality is not worse; roll back with a setting |
| E3 | Keep CV analysis on the stronger model | It sets roles, level and years for all matching and the collector's search titles; a few CVs a day makes the saving negligible against the risk |
| E4 | Re-run the model comparison (`scripts/eval_ai.py`) before every model or prompt change | The gold answers and the report already exist |

### F. Cadence and batching (mostly done)

Full batches via the hold (done); titles wait for 40 titles or 30 minutes; requirements run in full batches; first-search lanes bypass the hold so new users are never delayed. These are preserved and tuned from the metrics in section 5.

### G. Caching rules

All existing result caches stay, with their keys frozen so a port or normalization change never forces re-payment. New reuse keys (fingerprints, near-duplicate links, noise-free title keys) are additive. Prompt prefixes are arranged for provider caching (C4). Stored answers are kept raw so a better taxonomy re-maps them without asking again (as requirements already are).

## 4. Architecture in the Node codebase

One `ai/` module (the layout already lists `ai/client.js`, `cv-analysis.js`, `cover-letters.js`):

| Part | Behavior |
| --- | --- |
| Task profiles | Per task: model, `max_tokens` formula, temperature, reasoning off, provider flags (`data_collection: deny`), batch size, hold time, retry cap; values come from `app_settings` with environment fallbacks and code maxima |
| Prompt registry | Each prompt has an id, version and hash; a change requires an evaluation report reference in the pull request |
| Meter | Every call records input, output and cached tokens, cost estimate, latency, outcome (ok, parse failure, validation failure, cut off, provider error) per task, model and API key |
| Cache layer | Verdict, content-hash, title-key, letter and CV caches behind one interface; "avoided" reasons are counted |
| Retry and park | Retry caps, item-level re-ask, parking with a re-check date, circuit breaker on provider errors, bounded backoff |
| Providers | OpenRouter-compatible client with the same flags as today; local Ollama/vLLM-compatible endpoint remains possible by configuration (the classifier already documents it) |
| Keys | One API key per service (collector, sender, API, scripts) with provider-side limits, so spend is attributable |
| Test double | A deterministic fake provider replays recorded answers for tests; no test spends tokens |

## 5. Visibility and control ([admin console](admin-dashboard.md))

- **AI usage panel:** tokens and estimated cost by task, model and key (today, 7, 30 days, from daily rollups kept 400 days in `ops_metrics`); cost per 1,000 posts, per 1,000 jobs, per letter, per CV; budget burn against the daily guards.
- **Tokens avoided:** counters by reason (known verdict, identical text, near-duplicate reuse, age gate, out of scope, junk, parked, cache hit, eligibility-first for letters) with the estimated tokens saved.
- **Health of the AI paths:** parse failure rate, retry rate, escalation rate, cut-off letters, template fallbacks, provider errors, p95 latency; alerts when cost per unit rises more than 30% over its 14-day baseline or a parked backlog grows.
- **Controls (owner):** per-task on/off, model, daily cap, batch size and hold time within maxima; a one-click return to the baseline profile for a task; every change audited.

## 6. Quality guardrails ("same level")

| Task | Evaluation set (fixed, kept out of git like today's `logs/`) | Metrics and non-inferiority margin |
| --- | --- | --- |
| Posts | 300 real hiring posts with gold answers from the strong reference model (as `eval_ai.py` does) | Hiring decision precision and recall, role accuracy (baseline 93%), remote accuracy, level agreement; the optimized path may be no more than 1 point lower, with the 95% interval's lower bound reported |
| Requirements | 200 real jobs with gold answers | Required-skill F1 (baseline 83%), preferred-skill F1, minimum-years and education agreement; no more than 1 point lower on each |
| Titles | All distinct titles from a month of data, labelled by the full-list prompt | Role agreement; shortlist recall at least 99.5% |
| Letters | 100 (CV, job) pairs | **Zero** invented claims by the grounding check and by a human review of a 50-letter sample; length and structure rules pass; blind pairwise comparison against the current letters shows no preference for the baseline beyond chance |
| CV analysis | 50 CVs, Arabic and English | Field agreement with the current output (roles, level, years, skills) at least as high as the model's own run-to-run agreement; no regression on Arabic CVs |
| Matching impact | The existing matching evaluation (`eval/`, NDCG@10 on 35 profiles) | No drop beyond the measurement noise after any change to requirements or title reading |

Rollout of each change: offline evaluation, then **shadow** (run the optimized path beside the current one on a sample for 7 days, store hashed-id differences, no personal text), then enable per task behind a setting, with the baseline kept for instant rollback. Evaluation outputs and reports are release evidence.

## 7. Estimated effect (to be replaced by measurements)

| Area | Lever | Plausible reduction of that task's tokens |
| --- | --- | --- |
| Posts | A1 exact/near-duplicate reuse, A2/A3 waste closure | 10-30% |
| Requirements | A1, C3 | 10-25% |
| Titles | B1, C1 | 30-60% of a small cost |
| Letters | D1, C2, D2, C4 (and E2 only if proven) | 60-85% per letter if C2 passes its gates; 40-60% from D1 alone |
| CV analysis | C1, D1 | 20-30% |

The numbers are hypotheses from the repository's own analysis and arithmetic. The first release records the baseline per task so each saving is reported as measured, not assumed.

## 8. Port parity and tasks

The Python AI paths are ported first without behavior change (same prompts, caps, flags, parsing, caches, retries), with parity tests against recorded model answers and token counts within a recorded tolerance. Only then do the levers above ship, one at a time, each with its evaluation. Tasks are in the [roadmap](implementation-roadmap.md): R1-59 to R1-62 (AI client, meter and caches with parity; usage panel and controls; evaluation harness and baselines; per-service keys and budgets) and post-parity AI-01 to AI-08.
