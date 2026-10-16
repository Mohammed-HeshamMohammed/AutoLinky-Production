-- Run bootstrap.sql as cluster administrator first to create the NOLOGIN roles.
-- Credentials are provisioned independently; services never receive DDL rights.
GRANT USAGE ON SCHEMA public,extensions TO autolinky_auth,autolinky_app,autolinky_messaging,autolinky_fetching,autolinky_data;
GRANT SELECT ON public.app_users,public.identity_deletion_queue TO autolinky_auth;
GRANT INSERT,UPDATE ON public.app_users TO autolinky_auth;
GRANT UPDATE(completed_at) ON public.identity_deletion_queue TO autolinky_auth;
GRANT EXECUTE ON FUNCTION public.bind_firebase_user(text,text,boolean),public.delete_user_data(uuid) TO autolinky_auth;
GRANT EXECUTE ON FUNCTION public.api_hit(text,integer,integer) TO autolinky_auth,autolinky_app,autolinky_messaging;
GRANT SELECT,INSERT,UPDATE,DELETE ON public.api_rate_limits TO autolinky_auth,autolinky_app,autolinky_messaging;

GRANT SELECT ON public.job_fields,public.job_roles,public.skills,public.skill_candidates,
 public.skill_implications,public.field_relations,public.opportunities,public.hiring_posts,
 public.post_contacts,public.linkedin_jobs,public.search_titles,public.role_affinity,
 public.role_skill_stats,public.skill_stats,public.job_requirements,public.match_cache,
 public.match_cache_meta,public.match_cache_state,public.match_cache_queue,public.title_classifications,
 public.app_settings,public.applications TO autolinky_app;
GRANT SELECT,INSERT,UPDATE,DELETE ON public.user_profiles,public.user_cvs,public.user_cv_files,
 public.user_searches,public.match_cache,public.match_cache_state TO autolinky_app;
GRANT INSERT ON public.app_downloads,public.ops_metrics TO autolinky_app;

GRANT SELECT ON public.app_users,public.user_profiles,public.user_cvs,public.user_cv_files,
 public.user_limits,public.subscriptions,public.user_plans,public.app_settings,
 public.opportunities,public.hiring_posts,public.post_contacts,public.linkedin_jobs,
 public.skills,public.job_roles,public.job_fields,public.job_requirements,public.skill_stats,
 public.role_affinity,public.role_skill_stats,public.match_cache,public.match_cache_state,
 public.match_cache_meta,public.match_cache_queue TO autolinky_messaging;
GRANT SELECT,INSERT,UPDATE,DELETE ON public.applications,public.auto_apply,public.mail_accounts,
 public.cover_letters,public.app_devices,public.worker_heartbeats,public.ops_metrics,
 public.match_cache,public.match_cache_state TO autolinky_messaging;
GRANT EXECUTE ON FUNCTION public.opportunity_feed(text,text[],text[],text[],text[],text[],text[],text[],text[],text[],timestamptz,timestamptz,uuid,integer),
 public.opportunity_facets(timestamptz),public.plan_email(text),public.search_title_key(text),public.search_title_keys(text[]),
 public.match_opportunities(uuid,timestamptz,integer,integer,text[],text[],text[],integer),
 public.match_profile(jsonb,timestamptz,integer,integer,text[],text[],text[],integer,uuid[]),
 public.scope_profile(jsonb),public.scope_countries(text),public.scope_work_modes(text,text[]),
 public.match_cache_since(),public.match_cache_job_columns(jsonb),public.match_cache_rebuild(uuid,boolean)
 TO autolinky_app,autolinky_messaging;
GRANT USAGE,SELECT ON ALL SEQUENCES IN SCHEMA public TO autolinky_app,autolinky_messaging;

CREATE TABLE public.ingestion_batches(
 id uuid PRIMARY KEY DEFAULT extensions.gen_random_uuid(),
 provider text NOT NULL CHECK(provider ~ '^[a-z0-9_-]{1,80}$'),
 payload_hash text NOT NULL CHECK(length(payload_hash)=64),
 payload jsonb NOT NULL CHECK(jsonb_typeof(payload)='array' AND jsonb_array_length(payload)<=500),
 status text NOT NULL DEFAULT 'pending' CHECK(status IN ('pending','processed')),
 accepted integer NOT NULL DEFAULT 0,skipped integer NOT NULL DEFAULT 0,
 created_at timestamptz NOT NULL DEFAULT now(),processed_at timestamptz,
 UNIQUE(provider,payload_hash)
);
CREATE INDEX ingestion_pending ON public.ingestion_batches(created_at,id) WHERE status='pending';
CREATE INDEX ingestion_retention ON public.ingestion_batches(processed_at) WHERE status='processed';
CREATE TABLE public.provider_records(
 provider text NOT NULL,record_key text NOT NULL,
 content jsonb NOT NULL,content_hash text NOT NULL CHECK(length(content_hash)=64),
 batch_id uuid REFERENCES public.ingestion_batches(id) ON DELETE SET NULL,
 created_at timestamptz NOT NULL DEFAULT now(),updated_at timestamptz NOT NULL DEFAULT now(),
 PRIMARY KEY(provider,record_key)
);
REVOKE ALL ON public.ingestion_batches,public.provider_records FROM PUBLIC;
GRANT SELECT,INSERT ON public.ingestion_batches TO autolinky_fetching;
GRANT UPDATE(provider) ON public.ingestion_batches TO autolinky_fetching;
GRANT SELECT,UPDATE,DELETE,MAINTAIN ON public.ingestion_batches TO autolinky_data;
GRANT SELECT,INSERT,UPDATE,DELETE,MAINTAIN ON public.provider_records TO autolinky_data;
