-- Identity retries have a separate operator identity. API completion cannot
-- rename or erase a UID tombstone, and operations cannot change its UID either.
REVOKE UPDATE ON public.identity_deletion_queue FROM autolinky_api;
GRANT UPDATE(completed_at) ON public.identity_deletion_queue TO autolinky_api;
GRANT SELECT ON public.identity_deletion_queue TO autolinky_ops;
GRANT UPDATE(attempts,next_attempt_at,completed_at) ON public.identity_deletion_queue TO autolinky_ops;
