REVOKE ALL ON ALL TABLES IN SCHEMA public FROM PUBLIC;
REVOKE ALL ON ALL FUNCTIONS IN SCHEMA public FROM PUBLIC;
REVOKE ALL ON ALL SEQUENCES IN SCHEMA public FROM PUBLIC;
ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC;
GRANT USAGE ON SCHEMA public,extensions TO autolinky_api,autolinky_collector,autolinky_sender,autolinky_ops,autolinky_admin;
GRANT SELECT ON public.job_fields,public.job_roles,public.skills,public.skill_candidates,
 public.skill_implications,public.field_relations,public.opportunities,public.hiring_posts,
 public.post_contacts,public.linkedin_jobs,public.search_titles,public.role_affinity,
 public.role_skill_stats,public.skill_stats,public.job_requirements,public.match_cache,
 public.match_cache_meta,public.match_cache_state,public.match_cache_queue,public.title_classifications,
 public.app_settings TO autolinky_api;
GRANT SELECT,INSERT,UPDATE ON public.app_users TO autolinky_api;
GRANT SELECT,INSERT,UPDATE,DELETE ON public.user_profiles,public.user_cvs,public.user_cv_files,
 public.applications,public.auto_apply,public.cover_letters,public.mail_accounts,public.app_devices,
 public.user_searches,public.api_rate_limits TO autolinky_api;
GRANT SELECT ON public.user_limits,public.subscriptions,public.user_plans,public.worker_heartbeats TO autolinky_api;
GRANT INSERT ON public.app_downloads,public.ops_metrics TO autolinky_api;
GRANT SELECT,UPDATE ON public.identity_deletion_queue TO autolinky_api;
GRANT SELECT,INSERT,UPDATE,DELETE ON public.hiring_posts,public.post_contacts,public.post_verdicts,
 public.linkedin_jobs,public.opportunities,public.job_requirements,public.requirements_skipped,
 public.title_classifications,public.search_titles,public.search_locations,public.search_queries,
 public.job_fields,public.job_roles,public.skills,public.skill_candidates,public.skill_implications,
 public.field_relations,public.role_affinity,public.role_skill_stats,public.skill_stats,
 public.match_cache,public.match_cache_meta,public.match_cache_queue,public.match_cache_state,
 public.user_searches,public.worker_heartbeats,public.ops_metrics,public.api_rate_limits TO autolinky_collector;
GRANT SELECT ON public.user_profiles,public.app_users,public.app_settings TO autolinky_collector;
GRANT SELECT ON public.app_users,public.user_profiles,public.user_cvs,public.user_cv_files,
 public.user_limits,public.subscriptions,public.user_plans,public.app_settings,
 public.opportunities,public.hiring_posts,public.post_contacts,public.linkedin_jobs,
 public.skills,public.job_roles,public.job_fields,public.job_requirements,public.skill_stats,
 public.role_affinity,public.role_skill_stats,public.match_cache,public.match_cache_state,
 public.match_cache_meta,public.match_cache_queue TO autolinky_sender;
GRANT SELECT,INSERT,UPDATE,DELETE ON public.applications,public.auto_apply,public.mail_accounts,
 public.cover_letters,public.api_rate_limits,public.worker_heartbeats,public.ops_metrics TO autolinky_sender;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO autolinky_ops,autolinky_admin;
REVOKE ALL ON public.mail_accounts,public.user_cv_files,public.admin_accounts FROM autolinky_ops;
GRANT INSERT,UPDATE,DELETE ON public.admin_accounts,public.app_settings,public.user_limits,
 public.subscriptions,public.auto_apply,public.app_devices,public.app_users,
 public.user_cvs,public.user_cv_files,public.search_titles,public.search_locations,
 public.opportunities,public.skills,public.skill_candidates TO autolinky_admin;
GRANT INSERT ON public.admin_log TO autolinky_admin;
GRANT USAGE,SELECT ON ALL SEQUENCES IN SCHEMA public TO autolinky_api,autolinky_collector,autolinky_admin;
GRANT EXECUTE ON FUNCTION public.delete_user_data(uuid) TO autolinky_api,autolinky_admin;
GRANT EXECUTE ON FUNCTION public.bind_firebase_user(text,text,boolean) TO autolinky_api;
GRANT EXECUTE ON FUNCTION public.api_hit(text,integer,integer), public.touch_app_user(uuid,text),
 public.opportunity_feed(text,text[],text[],text[],text[],text[],text[],text[],text[],text[],timestamptz,timestamptz,uuid,integer),
 public.opportunity_facets(timestamptz), public.plan_email(text),public.search_title_key(text),public.search_title_keys(text[]),
 public.match_opportunities(uuid,timestamptz,integer,integer,text[],text[],text[],integer),
 public.match_profile(jsonb,timestamptz,integer,integer,text[],text[],text[],integer,uuid[]),
 public.scope_profile(jsonb),public.scope_countries(text),public.scope_work_modes(text,text[]),
 public.match_cache_since(),public.match_cache_job_columns(jsonb)
 TO autolinky_api,autolinky_sender;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO autolinky_collector;
REVOKE EXECUTE ON FUNCTION public.delete_user_data(uuid),public.admin_overview(integer),
 public.admin_users(text,text,text,integer,integer) FROM autolinky_collector;
GRANT EXECUTE ON FUNCTION public.security_report(),public.admin_overview(integer),
 public.admin_users(text,text,text,integer,integer) TO autolinky_admin,autolinky_ops;
-- Matching lazily rebuilds disposable cache rows, including on an API read.
GRANT SELECT,INSERT,UPDATE,DELETE ON public.match_cache,public.match_cache_state TO autolinky_api,autolinky_sender;
GRANT EXECUTE ON FUNCTION public.match_cache_rebuild(uuid,boolean) TO autolinky_api,autolinky_sender;
