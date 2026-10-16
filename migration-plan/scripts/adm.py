def sub(path, old, new):
    s=open(path,encoding='utf-8').read()
    if old not in s:
        print('MISSING in',path,':',old[:70]); return
    open(path,'w',encoding='utf-8').write(s.replace(old,new,1))
A='admin-dashboard.md'
sub(A,'| Collector status | viewer | Heartbeat, current cycle, per-source progress, throttle state, account health (valid, needs login, rate limited; never the cookies) |','| Collector status | viewer | Heartbeat, current cycle, per-source progress, throttle state, account health (valid, needs login, rate limited; never the cookies), requests per minute against each cap, lane queue depths and ages, worker-pool utilization and restarts, time to first result for live searches, **parser health** (field coverage per cycle against its baseline, drift alerts) |')
sub(A,'| Collector paused | on/off | operator | See collector |','| Collector paused | on/off | operator | See collector |\n| Search concurrency (`collector.jobs_workers`, `posts_workers_per_account`, `parse_threads`, `ai_concurrency`, lane weights, queue factor) | integers within the code-enforced maxima in the [parallel search pipeline](search-concurrency.md) | owner | Applied at the next cycle; the request-rate settings stay separate and capped at the tested maxima; every change audited and notified |')
sub(A,'Services up or down with heartbeat age;','Services up or down with heartbeat age; **diagnostics export** (owner: versions, schema fingerprint, redacted configuration, recent error counts, queue and pool state, last migration; no secrets, record values or logs unless redacted);')
sub(A,'- Performance: overview and user list','- Collector controls: changing concurrency settings takes effect without a restart and never raises the request rate; pause during a run stops at a checkpoint; parser-health alert shown after a seeded coverage drop.\n- Performance: overview and user list')
B='backend-after-migration.md'
sub(B,'Set a memory limit on every container.','Set a memory limit on every container. CPU: at least 2 vCPU (4 comfortable), because the collector\'s worker-thread pool, PostgreSQL and the API share the cores; the pool size is derived from `os.availableParallelism()` and capped as described in the [parallel search pipeline](search-concurrency.md).')
E='database-efficiency.md'
sub(E,'Related: [SQL mapping](sql-mapping.md) (schema and migrations),','Related: [parallel search pipeline](search-concurrency.md) (concurrency), [DataForge adoption](dataforge-adoption.md), [SQL mapping](sql-mapping.md) (schema and migrations),')
