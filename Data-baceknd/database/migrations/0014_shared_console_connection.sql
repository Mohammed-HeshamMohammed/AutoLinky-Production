-- Data owns both its internal API and the MFA-gated dashboard data routes.
-- Both use PG_DATABASE_URL. Match the former console pool's limited grants.
GRANT USAGE ON SCHEMA public,extensions TO autolinky_data;
GRANT SELECT(id,email,status,created_at,last_seen_at) ON public.app_users TO autolinky_data;
GRANT UPDATE(status) ON public.app_users TO autolinky_data;
GRANT SELECT(user_id,file_name,file_type,file_size,pages,created_at) ON public.user_cvs TO autolinky_data;
GRANT SELECT(user_id,address,sender_name,status,error,checked_at) ON public.mail_accounts TO autolinky_data;
GRANT SELECT(id,user_id,platform,last_seen_at,created_at) ON public.app_devices TO autolinky_data;
GRANT SELECT(user_id,headline,level,years_experience,search_scope) ON public.user_profiles TO autolinky_data;
GRANT SELECT(user_id,opportunity_id,method,status,created_at,updated_at,auto,sent_at,recipient,error,job) ON public.applications TO autolinky_data;
GRANT SELECT,INSERT,UPDATE,DELETE ON public.user_limits,public.subscriptions TO autolinky_data;
GRANT SELECT ON public.auto_apply,public.worker_heartbeats,public.admin_log TO autolinky_data;
GRANT UPDATE(enabled,updated_at) ON public.auto_apply TO autolinky_data;
GRANT INSERT ON public.admin_log TO autolinky_data;
GRANT USAGE,SELECT ON SEQUENCE public.admin_log_id_seq TO autolinky_data;
GRANT EXECUTE ON FUNCTION public.plan_email(text),public.admin_users(text,text,text,integer,integer),
 public.console_overview(integer),public.search_title_key(text) TO autolinky_data;
GRANT SELECT ON public.search_titles,public.search_queries TO autolinky_data;
GRANT INSERT,UPDATE,DELETE ON public.search_titles TO autolinky_data;
GRANT UPDATE(next_run_at) ON public.search_queries TO autolinky_data;
GRANT SELECT,UPDATE ON public.console_service_control TO autolinky_data;
