-- Run once as the private PostgreSQL cluster administrator before migrations.
-- LOGIN credentials are provisioned separately; no passwords belong in this file.
DO $roles$
DECLARE r text;
BEGIN
  FOREACH r IN ARRAY ARRAY['autolinky_migrator','autolinky_api','autolinky_collector','autolinky_sender','autolinky_ops','autolinky_admin',
    'autolinky_auth','autolinky_app','autolinky_messaging','autolinky_fetching','autolinky_data'] LOOP
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = r) THEN
      EXECUTE format('CREATE ROLE %I NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION', r);
    END IF;
  END LOOP;
END;
$roles$;
REVOKE CREATE ON SCHEMA public FROM PUBLIC;
ALTER SCHEMA public OWNER TO autolinky_migrator;
GRANT CREATE, USAGE ON SCHEMA public TO autolinky_migrator;
CREATE SCHEMA IF NOT EXISTS extensions AUTHORIZATION autolinky_migrator;
CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA extensions;
-- Grant database CREATE to the migrator during bootstrap for its private ledger schema.
DO $db$ BEGIN
  EXECUTE format('GRANT CREATE ON DATABASE %I TO autolinky_migrator', current_database());
END $db$;
