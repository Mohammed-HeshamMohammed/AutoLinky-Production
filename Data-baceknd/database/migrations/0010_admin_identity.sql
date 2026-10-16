ALTER TABLE public.admin_accounts
 ADD COLUMN failed_logins integer NOT NULL DEFAULT 0 CHECK(failed_logins>=0),
 ADD COLUMN failed_window_at timestamptz NOT NULL DEFAULT now(),
 ADD COLUMN locked_until timestamptz,
 ADD COLUMN last_totp_step bigint NOT NULL DEFAULT -1;
CREATE TABLE public.admin_sessions(
 id uuid PRIMARY KEY,
 admin_id uuid NOT NULL REFERENCES public.admin_accounts(id) ON DELETE CASCADE,
 token_hash text NOT NULL UNIQUE CHECK(length(token_hash)=64),
 session_epoch integer NOT NULL,
 expires_at timestamptz NOT NULL,
 created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX admin_session_expiry ON public.admin_sessions(expires_at);
REVOKE ALL ON public.admin_sessions FROM PUBLIC;
GRANT SELECT,INSERT,UPDATE ON public.admin_accounts TO autolinky_auth;
GRANT SELECT,INSERT,DELETE ON public.admin_sessions TO autolinky_auth;
GRANT INSERT ON public.admin_log TO autolinky_auth;
GRANT USAGE,SELECT ON SEQUENCE public.admin_log_id_seq TO autolinky_auth;
