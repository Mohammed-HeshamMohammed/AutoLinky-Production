-- SELECT ... FOR UPDATE serializes delivery against account deletion. A single
-- activity column permits row locking without granting identity/status writes.
GRANT UPDATE(last_seen_at) ON public.app_users TO autolinky_messaging,autolinky_sender;
