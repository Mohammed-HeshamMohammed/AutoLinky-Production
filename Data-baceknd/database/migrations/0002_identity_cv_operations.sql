ALTER TABLE public.app_users ALTER COLUMN id SET DEFAULT gen_random_uuid();
ALTER TABLE public.app_users ADD COLUMN firebase_uid text UNIQUE;
ALTER TABLE public.app_users ADD COLUMN email_verified boolean NOT NULL DEFAULT false;
-- Profile writes update demand through a trigger, without granting catalog writes to the API.
ALTER FUNCTION public.user_profiles_search_titles_changed() SECURITY DEFINER;

CREATE TABLE public.user_cv_files (
  user_id uuid PRIMARY KEY REFERENCES public.user_cvs(user_id) ON DELETE CASCADE,
  bytes bytea NOT NULL CHECK (octet_length(bytes) BETWEEN 1 AND 4194304),
  sha256 text NOT NULL CHECK (sha256 ~ '^[a-f0-9]{64}$') CHECK (sha256=encode(extensions.digest(bytes,'sha256'),'hex')),
  created_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.user_cv_files ALTER COLUMN bytes SET STORAGE EXTERNAL;
ALTER TABLE public.user_cvs ALTER COLUMN storage_path DROP NOT NULL;

CREATE TABLE public.ops_metrics (
  service text NOT NULL,
  metric text NOT NULL,
  bucket timestamptz NOT NULL,
  value double precision NOT NULL,
  labels jsonb NOT NULL DEFAULT '{}',
  PRIMARY KEY (service,metric,bucket,labels)
);
CREATE TABLE public.app_settings (
  key text PRIMARY KEY,
  value jsonb NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now(),
  updated_by text
);
CREATE TABLE public.admin_accounts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  username text NOT NULL UNIQUE,
  password_hash text NOT NULL,
  totp_secret text NOT NULL,
  role text NOT NULL CHECK (role IN ('owner','operator','viewer')),
  enabled boolean NOT NULL DEFAULT true,
  session_epoch integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.admin_log ADD COLUMN actor_id uuid;
ALTER TABLE public.admin_log ADD COLUMN request_id text;
ALTER TABLE public.admin_log ADD COLUMN before_state jsonb;
ALTER TABLE public.admin_log ADD COLUMN after_state jsonb;

CREATE TABLE public.identity_deletion_queue (
  firebase_uid text PRIMARY KEY,
  requested_at timestamptz NOT NULL DEFAULT now(),
  attempts integer NOT NULL DEFAULT 0,
  next_attempt_at timestamptz NOT NULL DEFAULT now(),
  completed_at timestamptz
);

CREATE FUNCTION public.bind_firebase_user(p_uid text,p_email text,p_verified boolean)
RETURNS SETOF public.app_users LANGUAGE plpgsql SET search_path=pg_catalog,public,pg_temp AS $$
BEGIN
  PERFORM pg_advisory_xact_lock(hashtextextended('identity:'||p_uid,0));
  IF EXISTS(SELECT FROM public.identity_deletion_queue WHERE firebase_uid=p_uid) THEN RETURN; END IF;
  RETURN QUERY INSERT INTO public.app_users(firebase_uid,email,email_verified) VALUES(p_uid,p_email,p_verified)
    ON CONFLICT(firebase_uid) DO UPDATE SET email=EXCLUDED.email,email_verified=EXCLUDED.email_verified,
      last_seen_at=CASE WHEN app_users.last_seen_at<now()-interval '5 minutes' THEN now() ELSE app_users.last_seen_at END
    RETURNING app_users.*;
END;
$$;

ALTER TABLE public.auto_apply DROP CONSTRAINT auto_apply_pause_reason_check;
ALTER TABLE public.auto_apply ADD CONSTRAINT auto_apply_pause_reason_check
  CHECK (pause_reason IN ('gmail_limit','gmail_busy','admin'));

CREATE FUNCTION public.delete_user_data(p_user uuid) RETURNS jsonb
  LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public, pg_temp AS $$
DECLARE v_uid text; n integer;
BEGIN
  SELECT firebase_uid INTO v_uid FROM public.app_users WHERE id=p_user;
  IF v_uid IS NOT NULL THEN PERFORM pg_advisory_xact_lock(hashtextextended('identity:'||v_uid,0)); END IF;
  PERFORM 1 FROM public.app_users WHERE id=p_user FOR UPDATE;
  IF EXISTS (SELECT FROM public.applications WHERE user_id=p_user AND status='sending') THEN
    RAISE EXCEPTION 'deletion_blocked' USING ERRCODE='P0001';
  END IF;
  IF v_uid IS NOT NULL THEN
    INSERT INTO public.identity_deletion_queue(firebase_uid) VALUES(v_uid) ON CONFLICT DO NOTHING;
  END IF;
  -- Internal FKs retain their ON DELETE CASCADE behavior; subscriptions are email keyed and remain.
  DELETE FROM public.app_users WHERE id=p_user;
  GET DIAGNOSTICS n = ROW_COUNT;
  RETURN jsonb_build_object('deleted',n);
END;
$$;
REVOKE ALL ON FUNCTION public.delete_user_data(uuid) FROM PUBLIC;

CREATE FUNCTION public.security_report()
RETURNS TABLE(kind text,name text,rls boolean,anon_access boolean,user_access boolean)
LANGUAGE sql STABLE SET search_path = pg_catalog, public, pg_temp AS $$
  SELECT CASE c.relkind WHEN 'v' THEN 'view' ELSE 'table' END::text,c.relname::text,
    c.relrowsecurity,
    EXISTS(SELECT FROM aclexplode(coalesce(c.relacl,acldefault('r',c.relowner))) a WHERE a.grantee=0),
    has_table_privilege('autolinky_api',c.oid,'SELECT, INSERT, UPDATE, DELETE')
  FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
  WHERE n.nspname='public' AND c.relkind IN ('r','p','v','m')
  UNION ALL
  SELECT 'function',p.proname||'('||pg_get_function_identity_arguments(p.oid)||')',NULL,
    EXISTS(SELECT FROM aclexplode(coalesce(p.proacl,acldefault('f',p.proowner))) a WHERE a.grantee=0),
    has_function_privilege('autolinky_api',p.oid,'EXECUTE')
  FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname='public'
  ORDER BY 1,2;
$$;

CREATE FUNCTION public.housekeeping(p_batch integer DEFAULT 1000) RETURNS jsonb
LANGUAGE plpgsql SET search_path = pg_catalog, public, pg_temp AS $$
DECLARE rate_count integer; download_count integer;
BEGIN
  IF p_batch NOT BETWEEN 1 AND 10000 THEN RAISE EXCEPTION 'invalid batch'; END IF;
  DELETE FROM public.api_rate_limits WHERE ctid IN
    (SELECT ctid FROM public.api_rate_limits WHERE window_start < now()-interval '2 days' LIMIT p_batch);
  GET DIAGNOSTICS rate_count = ROW_COUNT;
  DELETE FROM public.app_downloads WHERE ctid IN
    (SELECT ctid FROM public.app_downloads WHERE created_at < now()-interval '400 days' LIMIT p_batch);
  GET DIAGNOSTICS download_count = ROW_COUNT;
  DELETE FROM public.ops_metrics WHERE ctid IN
    (SELECT ctid FROM public.ops_metrics WHERE bucket < now()-interval '30 days' LIMIT p_batch);
  DELETE FROM public.user_searches WHERE ctid IN
    (SELECT ctid FROM public.user_searches WHERE done_at < now()-interval '7 days' LIMIT p_batch);
  RETURN jsonb_build_object('rate_limits',rate_count,'downloads',download_count);
END;
$$;
