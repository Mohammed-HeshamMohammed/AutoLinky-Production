-- Reference dashboard 9901aa4: aggregate analytics, safe support metadata and
-- coordinated pause controls. No legacy provider credentials are imported.
CREATE FUNCTION public.console_overview(p_days integer DEFAULT 30) RETURNS jsonb
LANGUAGE sql STABLE SECURITY DEFINER SET search_path=pg_catalog,public,pg_temp
AS $$ SELECT public.admin_overview(greatest(7,least(p_days,90))); $$;
REVOKE ALL ON FUNCTION public.console_overview(integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.console_overview(integer) TO autolinky_console_data;
GRANT SELECT(file_name,file_type,file_size,pages,created_at) ON public.user_cvs TO autolinky_console_data;
GRANT SELECT(address,sender_name,error,checked_at) ON public.mail_accounts TO autolinky_console_data;
GRANT SELECT(user_id,headline,level,years_experience,search_scope) ON public.user_profiles TO autolinky_console_data;
GRANT SELECT(recipient,error,job) ON public.applications TO autolinky_console_data;
GRANT SELECT ON public.search_titles,public.search_queries TO autolinky_console_data;
GRANT INSERT,UPDATE,DELETE ON public.search_titles TO autolinky_console_data;
GRANT UPDATE(next_run_at) ON public.search_queries TO autolinky_console_data;
GRANT EXECUTE ON FUNCTION public.search_title_key(text) TO autolinky_console_data;
CREATE TABLE public.console_service_control(
 service text PRIMARY KEY CHECK(service IN ('collector','sender')),
 paused boolean NOT NULL DEFAULT false,
 version bigint NOT NULL DEFAULT 1,
 updated_at timestamptz NOT NULL DEFAULT now(),
 updated_by text
);
INSERT INTO public.console_service_control(service) VALUES('collector'),('sender');
REVOKE ALL ON public.console_service_control FROM PUBLIC;
GRANT SELECT,UPDATE ON public.console_service_control TO autolinky_console_data;
GRANT SELECT(service,paused) ON public.console_service_control TO autolinky_data,autolinky_messaging,autolinky_sender,autolinky_api;
CREATE FUNCTION public.sender_reservation_allowed() RETURNS boolean
LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path=pg_catalog,public,pg_temp
AS $$ BEGIN
 RETURN coalesce((SELECT NOT paused FROM public.console_service_control WHERE service='sender' FOR SHARE),false);
END; $$;
REVOKE ALL ON FUNCTION public.sender_reservation_allowed() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.sender_reservation_allowed() TO autolinky_messaging,autolinky_sender,autolinky_api;
