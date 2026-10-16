-- Administrator authority belongs to an explicitly assigned application user.
-- Old standalone credentials and their sessions cannot survive this transition.
ALTER TABLE public.admin_accounts
 ADD COLUMN user_id uuid UNIQUE REFERENCES public.app_users(id) ON DELETE CASCADE,
 ADD COLUMN totp_confirmed_at timestamptz,
 ADD COLUMN totp_pending_until timestamptz,
 ALTER COLUMN password_hash DROP NOT NULL,
 ALTER COLUMN totp_secret DROP NOT NULL;
UPDATE public.admin_accounts SET enabled=false,session_epoch=session_epoch+1;
DELETE FROM public.admin_sessions;
ALTER TABLE public.admin_accounts
 ADD CONSTRAINT admin_enabled_user CHECK(NOT enabled OR user_id IS NOT NULL),
 ADD CONSTRAINT admin_confirmed_factor CHECK(totp_confirmed_at IS NULL OR totp_secret IS NOT NULL);

CREATE FUNCTION public.admin_authority_changed() RETURNS trigger
LANGUAGE plpgsql SET search_path=pg_catalog,public,pg_temp AS $$
BEGIN
 IF (NEW.user_id,NEW.role,NEW.enabled,NEW.totp_secret)
    IS DISTINCT FROM (OLD.user_id,OLD.role,OLD.enabled,OLD.totp_secret) THEN
   NEW.session_epoch=greatest(NEW.session_epoch,OLD.session_epoch+1);
 END IF;
 IF NEW.totp_secret IS DISTINCT FROM OLD.totp_secret THEN
   NEW.totp_confirmed_at=NULL;
   NEW.last_totp_step=-1;
 END IF;
 NEW.updated_at=now();
 RETURN NEW;
END;
$$;
CREATE TRIGGER admin_authority_changed BEFORE UPDATE ON public.admin_accounts
 FOR EACH ROW EXECUTE FUNCTION public.admin_authority_changed();

-- Blocking or rebinding an identity permanently invalidates its old assurance.
CREATE FUNCTION public.admin_user_changed() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog,public,pg_temp AS $$
BEGIN
 IF (NEW.status,NEW.firebase_uid) IS DISTINCT FROM (OLD.status,OLD.firebase_uid) THEN
   UPDATE public.admin_accounts SET session_epoch=session_epoch+1 WHERE user_id=NEW.id;
 END IF;
 RETURN NEW;
END;
$$;
CREATE TRIGGER admin_user_changed AFTER UPDATE OF status,firebase_uid ON public.app_users
 FOR EACH ROW EXECUTE FUNCTION public.admin_user_changed();
REVOKE ALL ON FUNCTION public.admin_authority_changed(),public.admin_user_changed() FROM PUBLIC;
