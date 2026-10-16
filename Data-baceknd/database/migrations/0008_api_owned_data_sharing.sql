-- Services exchange domain data over authenticated private APIs. No caller can
-- submit SQL to these APIs; runtime roles keep only their owned data access.
GRANT INSERT ON public.ingestion_batches TO autolinky_data;
GRANT UPDATE(provider) ON public.ingestion_batches TO autolinky_data;
REVOKE ALL ON public.ingestion_batches FROM autolinky_fetching;
REVOKE SELECT ON public.applications FROM autolinky_app;
REVOKE SELECT ON public.user_profiles,public.user_cvs,public.user_cv_files,
 public.opportunities,public.hiring_posts,public.post_contacts,public.linkedin_jobs,
 public.skills,public.job_roles,public.job_fields,public.job_requirements,public.skill_stats,
 public.role_affinity,public.role_skill_stats,public.match_cache,public.match_cache_state,
 public.match_cache_meta,public.match_cache_queue FROM autolinky_messaging;
REVOKE INSERT,UPDATE,DELETE ON public.match_cache,public.match_cache_state FROM autolinky_messaging;
REVOKE EXECUTE ON FUNCTION public.opportunity_feed(text,text[],text[],text[],text[],text[],text[],text[],text[],text[],timestamptz,timestamptz,uuid,integer),
 public.opportunity_facets(timestamptz),
 public.match_opportunities(uuid,timestamptz,integer,integer,text[],text[],text[],integer),
 public.match_profile(jsonb,timestamptz,integer,integer,text[],text[],text[],integer,uuid[]),
 public.match_cache_rebuild(uuid,boolean) FROM autolinky_messaging;
