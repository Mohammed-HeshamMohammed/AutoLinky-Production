GRANT USAGE ON SCHEMA public,extensions TO autolinky_console_data;
GRANT SELECT(id,email,status,created_at,last_seen_at) ON public.app_users TO autolinky_console_data;
GRANT UPDATE(status) ON public.app_users TO autolinky_console_data;
GRANT SELECT(user_id) ON public.user_cvs TO autolinky_console_data;
GRANT SELECT(user_id,status) ON public.mail_accounts TO autolinky_console_data;
GRANT SELECT(id,user_id,platform,last_seen_at,created_at) ON public.app_devices TO autolinky_console_data;
GRANT SELECT(user_id,opportunity_id,method,status,created_at,updated_at,auto,sent_at) ON public.applications TO autolinky_console_data;
GRANT SELECT,INSERT,UPDATE,DELETE ON public.user_limits,public.subscriptions TO autolinky_console_data;
GRANT SELECT ON public.auto_apply,public.worker_heartbeats,public.admin_log TO autolinky_console_data;
GRANT UPDATE(enabled,updated_at) ON public.auto_apply TO autolinky_console_data;
GRANT SELECT(id,status,created_at) ON public.ingestion_batches TO autolinky_console_data;
GRANT INSERT ON public.admin_log TO autolinky_console_data;
GRANT USAGE,SELECT ON SEQUENCE public.admin_log_id_seq TO autolinky_console_data;
GRANT EXECUTE ON FUNCTION public.plan_email(text),public.admin_users(text,text,text,integer,integer) TO autolinky_console_data;
ALTER FUNCTION public.app_users_status_changed() SECURITY DEFINER;
-- Admin data has no CV bytes/text, Gmail ciphertext, letters, tokens or hashes.
