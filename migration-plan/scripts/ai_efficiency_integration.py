import os
os.chdir(r'X:\Autolinky-with-serverbased\migration-plan')

def sub(path, old, new, required=True):
    s = open(path, encoding='utf-8').read()
    if old not in s:
        if required:
            print('MISSING in', path, ':', old[:70])
        return
    open(path, 'w', encoding='utf-8').write(s.replace(old, new, 1))

# README
sub('README.md', '| [Matching engine](matching-engine.md) |',
    '| [AI token efficiency](ai-token-efficiency.md) | Baseline AI spend by task, what is already optimized and preserved, levers to cut tokens (skip, reuse, shortlist, structured prompts, no-thinking, tiering), the non-inferiority quality gates that keep results at today\'s level, usage visibility and controls |\n| [Matching engine](matching-engine.md) |')

# owner confirmation of DataForge ownership / licence
sub('matching-engine.md', 'The engine is the same owner\'s project, so porting is allowed in principle; licence status should be confirmed once.',
    'The engine is the owner\'s own project (confirmed by the owner on 2026-10-15), so there is no licence barrier to porting or reusing any of it.')
sub('dataforge-adoption.md', '# DataForge: what was reviewed and what is taken',
    '# DataForge: what was reviewed and what is taken\n\n**Ownership:** DataForge is the owner\'s own project (confirmed 2026-10-15), so any part of it may be ported or reused without a licence question; the rule "take whatever is useful" applies. The table below records what is useful, and anything else found useful later is added here.')

# adoption: new rows
sub('dataforge-adoption.md', '## 2. Considered and not taken',
    '''### Further items taken (2026-10-15)

| # | DataForge idea | How it lands |
| --- | --- | --- |
| 14 | Small logistic model with a deterministic training hash, a holdout evaluation and a version string (`ranking.py`) | Pattern for the learned review-queue ordering ([matching engine](matching-engine.md)) and, if an evaluation ever shows a safe skip band, for AI pre-screening ([AI token efficiency](ai-token-efficiency.md), B3, currently rejected on evidence) |
| 15 | Fellegi-Sunter likelihood with term frequency and EM (`likelihood.py`) | Duplicate review ordering and calibration ([matching engine](matching-engine.md)) |
| 16 | Selector-free extraction from structured data (JSON-LD, microdata) as a fallback when HTML patterns drift (`structured.py`) | Optional fallback for the job-detail parser, reported by the parser-health metrics; not a replacement for the current parsing |
| 17 | Example-based selector and pattern suggestion and relocation suggestions (`suggest.py`, `resilience.py`) | An operator repair tool for parser drift (suggest new patterns from a failure fixture, always reviewed by a person) |
| 18 | File type by magic bytes, never by extension (`documents.py`) | Already how the CV extractor identifies PDF and DOCX; kept as an explicit rule |
| 19 | Content-addressed artifacts with hashes and provenance on every derived value | Already the pattern for CV hashes and `job_requirements`; extended to AI answers (prompt version and model recorded with each stored answer) |

## 2. Considered and not taken''')

# efficiency: ops_metrics retention
sub('database-efficiency.md', '`ops_metrics` 30 days, `admin_log` 365 days, both removed by maintenance functions in batches',
    '`ops_metrics` five-minute rows 30 days (daily rollup rows, including the AI usage and cost series, 400 days), `admin_log` 365 days, all removed by maintenance functions in batches')
sub('sql-mapping.md', '`ops_metrics` 30 days; `admin_log` 365 days;',
    '`ops_metrics` five-minute rows 30 days and daily rollup rows (AI usage and cost among them) 400 days; `admin_log` 365 days;')

# admin dashboard: AI usage panel
sub('admin-dashboard.md', '### G. Global settings (table `app_settings`)',
    '### G0. AI usage and controls\n\nSpecified in the [AI token efficiency plan](ai-token-efficiency.md#5-visibility-and-control-admin-console): tokens and estimated cost by task, model and key; cost per 1,000 posts, per 1,000 jobs, per letter and per CV; budget burn; tokens avoided by reason; parse, retry, escalation, cut-off and fallback rates; alerts on unit-cost drift. Controls (owner): per-task on/off, model, daily cap, batch size and hold time within code maxima, and a one-click return to the baseline profile; every change audited.\n\n### G. Global settings (table `app_settings`)')
sub('admin-dashboard.md', '| Duplicate handling (`dedupe.mode`',
    '| AI task profiles (`ai.<task>.enabled`, `.model`, `.daily_cap`, `.batch_size`, `.hold_seconds`) | enum / integers within code maxima | owner | Applied at the next call; baseline profile restorable in one click; each change audited and notified |\n| Duplicate handling (`dedupe.mode`')

# scope plan row
sub('python-to-nodejs.md', '| Hosted collector AI |',
    '| AI efficiency layer | Python AI paths above, `backend/cv_ai.py`, `backend/letter_ai.py`, `scripts/eval_ai.py` | The `ai/` module reproduces today\'s prompts, caps, flags, caches and retries first, then adds the levers of the [AI token efficiency plan](ai-token-efficiency.md) one at a time behind evaluation gates; `eval_ai.py` stays as the evaluation tool (Python or ported) with its gold answers. |\n| Hosted collector AI |')

# roadmap
R = 'implementation-roadmap.md'
s = open(R, encoding='utf-8').read()
marker = '| R1-35 | 8 |'
add = (
 '| R1-59 | 3 | `ai/` client with task profiles, token meter (input, output, cached), retry caps with parking, no-thinking and provider flags, prompt registry, cache layer and a deterministic fake provider; parity with the Python AI paths on recorded answers ([AI token efficiency](ai-token-efficiency.md)) | R1-17 | L | Same prompts, caps, parsing and cache behavior; token counts within tolerance |\n'
 '| R1-60 | 6a | AI usage metrics (daily rollups), admin AI usage panel and controls, per-service API keys, budgets and anomaly alerts | R1-59, R1-28 | M | Panel shows seeded usage; caps and kill switches tested |\n'
 '| R1-61 | 7 | Evaluation harness and baselines: recorded gold sets, report per task, non-inferiority checker; baseline metrics recorded before any lever ships | R1-59 | M | Baseline report in the release evidence |\n'
 '| R1-62 | 3 | Port of the free gates and caches exactly: pre-filter, age gates, Step 16 "wanted" selection, verdict, content-hash, title-key and letter caches | R1-59, R1-20 | M | Gate and cache parity tests against the Python behavior |\n')
if marker in s:
    s = s.replace(marker, add + marker, 1)
else:
    print('roadmap marker missing')
tail = (
 '\n## 4c. AI tuning wave (after Release 1 parity, each behind its evaluation)\n\n'
 'Each task ships only after passing the non-inferiority gates in the [AI token efficiency plan](ai-token-efficiency.md#6-quality-guardrails-same-level), first in shadow mode on a sample, with the baseline profile kept for rollback.\n\n'
 '| ID | Task | Gate |\n| --- | --- | --- |\n'
 '| AI-01 | Exact text-fingerprint reuse before the post call and content-hash reuse for requirements (A1), retry caps and parking (A2), known-lookup failure handling (A3) | Identical outputs on the gold sets; avoided-token counters |\n'
 '| AI-02 | Letters: thinking off, `finish_reason` check, static-first prompt (D1, C4) | 20-letter A/B, then the 100-pair set: zero invented claims |\n'
 '| AI-03 | Letters from structured facts and body-only generation (C2, D2) | Grounding check plus blind comparison on 100 pairs |\n'
 '| AI-04 | Title key without noise and embedding nearest-neighbour reuse; role shortlist in title and CV prompts (B1, C1) | Role agreement and shortlist recall at least 99.5% |\n'
 '| AI-05 | Ad tail trimming and rules-first years and education (C3, B2) | Required and preferred F1 and years/education agreement not lower |\n'
 '| AI-06 | Near-duplicate reuse before posts and requirements calls (A1 extension) | Matching-engine precision gate met |\n'
 '| AI-07 | Cheap-eligibility-first ordering for letters (A5) | Release 2; no letter written for a refused or unclaimable send |\n'
 '| AI-08 | Model tiering and letters on the lighter model (E1, E2) | Only if proven by the gates; otherwise left unchanged |\n')
anchor = '\n## 5. Release 2: platform mail'
if anchor in s:
    s = s.replace(anchor, tail + anchor, 1)
else:
    print('roadmap anchor missing')
open(R, 'w', encoding='utf-8').write(s)

# review register
sub('review-and-questions.md', '| 36 | The DataForge cleaning and deduplication engine itself',
    '| 37 | Minimize AI token usage while keeping today\'s quality (your request, 2026-10-15), and use whatever is useful from DataForge (you own it) | [AI token efficiency plan](ai-token-efficiency.md): baseline spend by task, what is already optimized and preserved, 20+ levers in five groups with expected effect, non-inferiority gates on fixed evaluation sets, shadow rollout, usage panel and controls, per-service keys; DataForge ownership recorded and six more items taken | [ai-token-efficiency.md](ai-token-efficiency.md), [dataforge-adoption.md](dataforge-adoption.md) |\n| 36 | The DataForge cleaning and deduplication engine itself')
sub('review-and-questions.md', 'with 76 tasks plus 6 post-parity tasks,', 'with 80 tasks plus 14 post-parity tasks,')
print('done')
