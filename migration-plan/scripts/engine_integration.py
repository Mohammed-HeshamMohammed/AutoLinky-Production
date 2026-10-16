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
sub('README.md', '| [DataForge adoption](dataforge-adoption.md) |',
    '| [Matching engine](matching-engine.md) | Normalization, cleanup and deduplication engine adapted from DataForge: Arabic-aware normalizers, job evidence model, incremental blocking and clustering, review panel, activation gates, recipient quality gate |\n| [DataForge adoption](dataforge-adoption.md) |')

# adoption rows
sub('dataforge-adoption.md', '| 5 | **Conservative near-duplicate matching.**',
    '| 5 | **Conservative near-duplicate matching** (full design in the [matching engine plan](matching-engine.md)).')
sub('dataforge-adoption.md', '| 6 | **Phone parsing from libphonenumber** with readable reasons for rejection |',
    '| 6 | **Phone parsing from libphonenumber** with readable reasons for rejection; plus e-mail, URL and company-key normalization and the cleanup rules (see the [matching engine plan](matching-engine.md)) |')
sub('dataforge-adoption.md', '## 2. Considered and not taken',
    '**The matching and cleaning engine is the largest item taken.** Its capabilities, the Arabic-script adaptation it needs (DataForge folds to ASCII, which deletes Arabic letters), the job evidence model, the data model, the admin review panel, the activation gates and the recipient quality gate are specified in [matching-engine.md](matching-engine.md).\n\n## 2. Considered and not taken')

# efficiency E24
sub('database-efficiency.md',
    'If above 5%, add DataForge-style conservative clustering ([adoption notes](dataforge-adoption.md))',
    'If above 5%, activate the conservative clustering specified in the [matching engine plan](matching-engine.md) (shadow mode first, labeled precision gate)')

# SQL plan
sub('sql-mapping.md',
    '| Near-duplicate job clustering (E24) | Measure the duplicate rate | Rate above 5% of active opportunities |',
    '| Near-duplicate job clustering (E24) | Designed in the [matching engine plan](matching-engine.md); built offline in Release 1, shadow then active | Duplicate rate above 5% of active opportunities and the labeled precision gate |')
sub('sql-mapping.md', '## Efficiency changes applied with the port',
    '## Deduplication tier (post-parity, flag-controlled)\n\nIf the [matching engine](matching-engine.md) is activated the schema adds `job_keys` (unlogged), `job_dupes`, `dedupe_constraints` and `opportunities.canonical_id` (`ON DELETE SET NULL`), with their foreign keys to `opportunities` (all removed with the job by the 14-day purge). That is 49 tables, 401 columns and 38 foreign keys including everything above. The migration is created with the offline engine work but the tables stay empty and unused while `dedupe.mode = off`. Feeds, facets and `match_profile` change (to read `canonical_id IS NULL`) only in a separate, parity-tested migration at activation.\n\n## Efficiency changes applied with the port')
sub('sql-mapping.md',
    'the recipient against `mail_suppressions` (a suppressed recipient is refused before any reservation)',
    'the recipient against `mail_suppressions` and the recipient quality gate (a suppressed, invalid or placeholder recipient is refused before any reservation)')

# mail plan
sub('softfix-mail-adaptation.md', '## Capacity, warm-up and abuse handling',
    '## Recipient quality gate\n\nBefore a reservation is created, the recipient address is checked by the cleanup rules from the [matching engine plan](matching-engine.md#10-recipient-quality-gate-release-2): syntax failures and placeholder or no-reply addresses are refused with a clear reason, known-typo domains are shown with a suggested correction for the user to confirm (never corrected silently), and an optional cached MX check can refuse domains that cannot receive mail. The verdict is evaluated together with the suppression list in the same admission step.\n\n## Capacity, warm-up and abuse handling')

# admin dashboard
sub('admin-dashboard.md', '### F. Taxonomy',
    '### E2. Duplicates and data quality (post-parity tier)\n\nSpecified in the [matching engine plan](matching-engine.md#8-admin-console-additions-admin-dashboard-plan): mode (`off`/`shadow`/`active`) and strictness (owner), counts and metrics (viewer), a review queue ordered by likelihood with side-by-side jobs and evidence (operator: confirm merge, keep separate, split, lock, undo, all audited), and a read-only variant-spelling report for company, city and title.\n\n### F. Taxonomy')
sub('admin-dashboard.md', '| Collector paused | on/off | operator | See collector |',
    '| Collector paused | on/off | operator | See collector |\n| Duplicate handling (`dedupe.mode` off/shadow/active, `dedupe.strictness` conservative/balanced, `dedupe.ranking`) | enums | owner | Activation gates in the matching engine plan; every change audited and notified |')

# scope plan
sub('python-to-nodejs.md', '| Contacts/geography/text/job age |',
    '| Normalization and cleanup engine | `collector/contacts.py` rules, `backend/textnorm.py`, plus the DataForge reference (`X:\\dataforge\\workers\\matching`) | `.js` libraries under `shared/normalize`, `shared/cleanup` and `dedupe/` per the [matching engine plan](matching-engine.md); the first port of existing rules is faithful, the engine additions are flag-controlled and measured. |\n| Contacts/geography/text/job age |')

# roadmap
R = 'implementation-roadmap.md'
s = open(R, encoding='utf-8').read()
marker = '| R1-35 | 8 |'
add = (
 '| R1-55 | 1 | Shared normalization library (`tidy`, Arabic-aware `fold`, e-mail, phone via libphonenumber-js, URL, company key, fingerprints) with parity against the Python and DataForge reference on a shared corpus | R1-04 | M | Exact parity on normalization outputs; Arabic cases pass |\n'
 '| R1-56 | 3 | Engine library: blocking, evidence, decide, constrained clustering, canonical selection, metrics ([matching engine](matching-engine.md)); unit and property tests | R1-55 | L | Golden pair set decisions identical to the reference; properties hold |\n'
 '| R1-57 | 7 | Offline evaluation harness on the restored copy: duplicate-rate measurement, labeled-pair sampling, precision and recall report | R1-56, R1-34 | M | Duplicate rate recorded; decides whether the tier is activated |\n'
 '| R1-58 | 1a | Dedupe schema (`job_keys`, `job_dupes`, `dedupe_constraints`, `canonical_id`) and `app_settings` flags, created empty with mode `off` | R1-08, R1-56 | S | Migrations tested; no behavior change |\n')
if marker in s:
    s = s.replace(marker, add + marker, 1)
else:
    print('roadmap R1 marker missing')
r2marker = '| R2-10 |'
add2 = '| R2-11 | Recipient quality gate: syntax, placeholder and no-reply verdicts, typo-domain suggestions, optional cached MX check, wired into admission and preview ([matching engine plan](matching-engine.md#10-recipient-quality-gate-release-2)) | R2-03, R1-55 | M | Refusal and suggestion cases tested; no silent correction |\n'
if r2marker in s:
    s = s.replace(r2marker, add2 + r2marker, 1)
else:
    print('roadmap R2 marker missing')
tail = (
 '\n## 4b. Deduplication tier (post-parity, flag-controlled)\n\n'
 'Built offline in Release 1 (tasks R1-55 to R1-58), activated only after the gates in the [matching engine plan](matching-engine.md#9-activation-gates). Tasks once Release 1 is stable:\n\n'
 '| ID | Task | Gate |\n| --- | --- | --- |\n'
 '| D-01 | Shadow mode for at least 14 days in production; record duplicate rate, block sizes, review volume | Mode `shadow` |\n'
 '| D-02 | Admin Duplicates panel (review queue, side-by-side evidence, confirm/keep separate/split/lock/undo) | Panel tests |\n'
 '| D-03 | Label 300 pairs; compute precision and recall; calibrate thresholds | No false merge in 300 sampled auto-matches |\n'
 '| D-04 | Scoring and feed migration to read `canonical_id IS NULL`, with flag-off parity tests; activate | Duplicate rate above 5% and D-03 met |\n'
 '| D-05 | Likelihood and learned queue ordering | 100 reviewed pairs, 20 labels with both outcomes |\n'
 '| D-06 | Data-quality variant report and alias table for company, city and title spellings | Operator review |\n')
anchor = '\n## 5. Release 2: platform mail'
if anchor in s:
    s = s.replace(anchor, tail + anchor, 1)
else:
    print('roadmap anchor missing')
open(R, 'w', encoding='utf-8').write(s)

sub('review-and-questions.md', 'with 71 tasks,', 'with 76 tasks plus 6 post-parity tasks,')
sub('review-and-questions.md', '| 35 | `X:\\dataforge` to be mined for useful parts |',
    '| 36 | The DataForge cleaning and deduplication engine itself (your clarification, 2026-10-15) | Dedicated engine plan: what it does, what Autolinky gains (job de-duplication, company keys, contact quality, recipient gate, review tools), the Arabic adaptation it needs, job evidence model, incremental design, data model, admin panel, activation gates, tests | [matching-engine.md](matching-engine.md) |\n| 35 | `X:\\dataforge` to be mined for useful parts |')
print('done')
