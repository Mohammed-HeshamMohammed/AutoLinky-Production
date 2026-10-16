-- Auth owns Firebase identity policy. Cross-domain SQL-first cleanup is an
-- atomic Data API operation protected by a separate auth-only service key.
GRANT EXECUTE ON FUNCTION public.delete_user_data(uuid) TO autolinky_data;
REVOKE EXECUTE ON FUNCTION public.delete_user_data(uuid) FROM autolinky_auth;
