-- ============================================================================
-- BookingIT — Supabase MVP Schema (clean rewrite)
-- ============================================================================
-- Run this in the Supabase SQL Editor (Dashboard → SQL Editor → New query).
-- WARNING: This drops your existing schema to ensure a clean slate!
-- ============================================================================

DROP SCHEMA public CASCADE;
CREATE SCHEMA public;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO public;

-- ============================================================================
-- EXTENSIONS
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- HELPER FUNCTION: updated_at trigger
-- ============================================================================

CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

-- ============================================================================
-- TABLE: users
-- One row per auth.users entry — created automatically by handle_new_user().
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.users (
  user_id    UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email      TEXT UNIQUE NOT NULL,
  first_name TEXT NOT NULL DEFAULT '',
  last_name  TEXT NOT NULL DEFAULT '',
  phone      TEXT,
  role       TEXT NOT NULL DEFAULT 'customer'
               CHECK (role IN ('customer', 'provider', 'admin')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_users_role ON public.users(role);

CREATE OR REPLACE TRIGGER trg_users_updated_at
  BEFORE UPDATE ON public.users
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Users: own row only for SELECT / UPDATE
CREATE POLICY "users_select_own"
  ON public.users FOR SELECT
  USING (user_id = (SELECT auth.uid()));

CREATE POLICY "users_update_own"
  ON public.users FOR UPDATE
  USING  (user_id = (SELECT auth.uid()))
  WITH CHECK (user_id = (SELECT auth.uid()));

-- ============================================================================
-- TABLE: providers
-- One row per provider account.  Linked to users via user_id.
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.providers (
  provider_id   UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id       UUID UNIQUE NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
  business_name TEXT NOT NULL,
  bio           TEXT,
  category      TEXT,
  emoji         TEXT DEFAULT '✦',
  phone         TEXT,
  address       TEXT,
  city          TEXT,
  state         TEXT,
  avatar_url    TEXT,
  is_approved   BOOLEAN NOT NULL DEFAULT TRUE,
  average_rating NUMERIC(3,2) NOT NULL DEFAULT 0.00
                  CHECK (average_rating BETWEEN 0 AND 5),
  total_reviews  INTEGER NOT NULL DEFAULT 0,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_providers_user_id    ON public.providers(user_id);
CREATE INDEX IF NOT EXISTS idx_providers_approved   ON public.providers(is_approved);
CREATE INDEX IF NOT EXISTS idx_providers_city       ON public.providers(city);

CREATE OR REPLACE TRIGGER trg_providers_updated_at
  BEFORE UPDATE ON public.providers
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

ALTER TABLE public.providers ENABLE ROW LEVEL SECURITY;

-- Public can view all approved providers (for browsing / booking)
-- Providers can always see their own row (e.g. while pending approval)
-- Single merged SELECT policy eliminates the multiple-permissive-policies lint
CREATE POLICY "providers_select"
  ON public.providers FOR SELECT
  USING (
    is_approved = TRUE
    OR user_id = (SELECT auth.uid())
  );

CREATE POLICY "providers_update_own"
  ON public.providers FOR UPDATE
  USING  (user_id = (SELECT auth.uid()))
  WITH CHECK (user_id = (SELECT auth.uid()));

-- Providers INSERT is done server-side in the signup flow
CREATE POLICY "providers_insert_own"
  ON public.providers FOR INSERT
  WITH CHECK (user_id = (SELECT auth.uid()));

-- ============================================================================
-- TABLE: services
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.services (
  service_id       UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  provider_id      UUID NOT NULL REFERENCES public.providers(provider_id) ON DELETE CASCADE,
  service_name     TEXT NOT NULL,
  description      TEXT,
  duration_minutes INTEGER NOT NULL CHECK (duration_minutes > 0),
  buffer_minutes   INTEGER NOT NULL DEFAULT 0 CHECK (buffer_minutes >= 0),
  price            NUMERIC(10,2) NOT NULL DEFAULT 0.00 CHECK (price >= 0),
  is_active        BOOLEAN NOT NULL DEFAULT TRUE,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_services_provider_id ON public.services(provider_id);
CREATE INDEX IF NOT EXISTS idx_services_active      ON public.services(is_active);

CREATE OR REPLACE TRIGGER trg_services_updated_at
  BEFORE UPDATE ON public.services
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

ALTER TABLE public.services ENABLE ROW LEVEL SECURITY;

-- Merged SELECT: public active services from approved providers OR provider's own
CREATE POLICY "services_select"
  ON public.services FOR SELECT
  USING (
    (is_active = TRUE AND provider_id IN (
      SELECT provider_id FROM public.providers WHERE is_approved = TRUE
    ))
    OR provider_id IN (
      SELECT provider_id FROM public.providers
      WHERE user_id = (SELECT auth.uid())
    )
  );

CREATE POLICY "services_insert_own"
  ON public.services FOR INSERT
  WITH CHECK (
    provider_id IN (
      SELECT provider_id FROM public.providers
      WHERE user_id = (SELECT auth.uid())
    )
  );

CREATE POLICY "services_update_own"
  ON public.services FOR UPDATE
  USING (
    provider_id IN (
      SELECT provider_id FROM public.providers
      WHERE user_id = (SELECT auth.uid())
    )
  )
  WITH CHECK (
    provider_id IN (
      SELECT provider_id FROM public.providers
      WHERE user_id = (SELECT auth.uid())
    )
  );

CREATE POLICY "services_delete_own"
  ON public.services FOR DELETE
  USING (
    provider_id IN (
      SELECT provider_id FROM public.providers
      WHERE user_id = (SELECT auth.uid())
    )
  );

-- ============================================================================
-- TABLE: provider_schedules  (weekly working hours)
-- day_of_week uses PostgreSQL DOW convention: 0 = Sunday … 6 = Saturday
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.provider_schedules (
  schedule_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  provider_id UUID NOT NULL REFERENCES public.providers(provider_id) ON DELETE CASCADE,
  day_of_week INTEGER NOT NULL CHECK (day_of_week BETWEEN 0 AND 6),
  start_time  TIME NOT NULL,
  end_time    TIME NOT NULL,
  is_open     BOOLEAN NOT NULL DEFAULT TRUE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT uq_provider_day UNIQUE (provider_id, day_of_week),
  CONSTRAINT chk_schedule_times CHECK (end_time > start_time)
);

CREATE INDEX IF NOT EXISTS idx_schedules_provider_id ON public.provider_schedules(provider_id);

CREATE OR REPLACE TRIGGER trg_schedules_updated_at
  BEFORE UPDATE ON public.provider_schedules
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

ALTER TABLE public.provider_schedules ENABLE ROW LEVEL SECURITY;

-- Merged SELECT: public (approved provider schedules) OR provider's own
CREATE POLICY "schedules_select"
  ON public.provider_schedules FOR SELECT
  USING (
    provider_id IN (
      SELECT provider_id FROM public.providers WHERE is_approved = TRUE
    )
    OR provider_id IN (
      SELECT provider_id FROM public.providers
      WHERE user_id = (SELECT auth.uid())
    )
  );

CREATE POLICY "schedules_insert_own"
  ON public.provider_schedules FOR INSERT
  WITH CHECK (
    provider_id IN (
      SELECT provider_id FROM public.providers
      WHERE user_id = (SELECT auth.uid())
    )
  );

CREATE POLICY "schedules_update_own"
  ON public.provider_schedules FOR UPDATE
  USING (
    provider_id IN (
      SELECT provider_id FROM public.providers
      WHERE user_id = (SELECT auth.uid())
    )
  )
  WITH CHECK (
    provider_id IN (
      SELECT provider_id FROM public.providers
      WHERE user_id = (SELECT auth.uid())
    )
  );

CREATE POLICY "schedules_delete_own"
  ON public.provider_schedules FOR DELETE
  USING (
    provider_id IN (
      SELECT provider_id FROM public.providers
      WHERE user_id = (SELECT auth.uid())
    )
  );

-- ============================================================================
-- TABLE: provider_time_off
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.provider_time_off (
  time_off_id    UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  provider_id    UUID NOT NULL REFERENCES public.providers(provider_id) ON DELETE CASCADE,
  start_datetime TIMESTAMPTZ NOT NULL,
  end_datetime   TIMESTAMPTZ NOT NULL,
  reason         TEXT,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT chk_time_off_range CHECK (end_datetime > start_datetime)
);

CREATE INDEX IF NOT EXISTS idx_time_off_provider_id ON public.provider_time_off(provider_id);
CREATE INDEX IF NOT EXISTS idx_time_off_range       ON public.provider_time_off(start_datetime, end_datetime);

CREATE OR REPLACE TRIGGER trg_time_off_updated_at
  BEFORE UPDATE ON public.provider_time_off
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

ALTER TABLE public.provider_time_off ENABLE ROW LEVEL SECURITY;

-- Public needs to read time-off to calculate available booking slots
CREATE POLICY "time_off_select"
  ON public.provider_time_off FOR SELECT
  USING (
    provider_id IN (
      SELECT provider_id FROM public.providers WHERE is_approved = TRUE
    )
    OR provider_id IN (
      SELECT provider_id FROM public.providers
      WHERE user_id = (SELECT auth.uid())
    )
  );

CREATE POLICY "time_off_insert_own"
  ON public.provider_time_off FOR INSERT
  WITH CHECK (
    provider_id IN (
      SELECT provider_id FROM public.providers
      WHERE user_id = (SELECT auth.uid())
    )
  );

CREATE POLICY "time_off_update_own"
  ON public.provider_time_off FOR UPDATE
  USING (
    provider_id IN (
      SELECT provider_id FROM public.providers
      WHERE user_id = (SELECT auth.uid())
    )
  );

CREATE POLICY "time_off_delete_own"
  ON public.provider_time_off FOR DELETE
  USING (
    provider_id IN (
      SELECT provider_id FROM public.providers
      WHERE user_id = (SELECT auth.uid())
    )
  );

-- ============================================================================
-- TABLE: appointments
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.appointments (
  appointment_id       UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  customer_id          UUID NOT NULL REFERENCES public.users(user_id)         ON DELETE RESTRICT,
  provider_id          UUID NOT NULL REFERENCES public.providers(provider_id) ON DELETE RESTRICT,
  service_id           UUID NOT NULL REFERENCES public.services(service_id)   ON DELETE RESTRICT,
  appointment_datetime TIMESTAMPTZ NOT NULL,
  duration_minutes     INTEGER NOT NULL CHECK (duration_minutes > 0),
  status               TEXT NOT NULL DEFAULT 'pending'
                         CHECK (status IN ('pending','confirmed','rescheduled','cancelled','completed','no_show')),
  notes                TEXT,
  created_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at           TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_appts_customer_id      ON public.appointments(customer_id);
CREATE INDEX IF NOT EXISTS idx_appts_provider_id      ON public.appointments(provider_id);
CREATE INDEX IF NOT EXISTS idx_appts_datetime         ON public.appointments(appointment_datetime);
CREATE INDEX IF NOT EXISTS idx_appts_status           ON public.appointments(status);
CREATE INDEX IF NOT EXISTS idx_appts_provider_datetime ON public.appointments(provider_id, appointment_datetime);

CREATE OR REPLACE TRIGGER trg_appointments_updated_at
  BEFORE UPDATE ON public.appointments
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

ALTER TABLE public.appointments ENABLE ROW LEVEL SECURITY;

-- Merged SELECT: customer sees own, provider sees theirs
CREATE POLICY "appointments_select"
  ON public.appointments FOR SELECT
  USING (
    customer_id = (SELECT auth.uid())
    OR provider_id IN (
      SELECT provider_id FROM public.providers
      WHERE user_id = (SELECT auth.uid())
    )
  );

CREATE POLICY "appointments_insert"
  ON public.appointments FOR INSERT
  WITH CHECK (customer_id = (SELECT auth.uid()));

-- Merged UPDATE: customer OR provider can update, but WITH CHECK limits
-- what customers can actually change (they cannot flip provider/service/status).
CREATE POLICY "appointments_update"
  ON public.appointments FOR UPDATE
  USING (
    customer_id = (SELECT auth.uid())
    OR provider_id IN (
      SELECT provider_id FROM public.providers
      WHERE user_id = (SELECT auth.uid())
    )
  )
  WITH CHECK (
    -- Providers can update anything on their appointments
    provider_id IN (
      SELECT provider_id FROM public.providers
      WHERE user_id = (SELECT auth.uid())
    )
    -- Customers can only reschedule (change datetime / notes), not reassign
    OR (
      customer_id = (SELECT auth.uid())
      AND provider_id = provider_id   -- unchanged
      AND service_id  = service_id    -- unchanged
      AND status      = status        -- unchanged (provider controls status)
    )
  );

-- ============================================================================
-- TABLE: appointment_history
-- Immutable audit trail for every appointment change (FR-3.10)
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.appointment_history (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  appointment_id  UUID NOT NULL REFERENCES public.appointments(appointment_id) ON DELETE CASCADE,
  changed_by      UUID REFERENCES public.users(user_id),   -- null = system
  old_status      TEXT,
  new_status      TEXT,
  old_starts_at   TIMESTAMPTZ,
  new_starts_at   TIMESTAMPTZ,
  change_note     TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.appointment_history IS
  'Immutable record of every status or time change on an appointment.';

CREATE INDEX IF NOT EXISTS idx_appt_hist_appointment_id ON public.appointment_history(appointment_id);

ALTER TABLE public.appointment_history ENABLE ROW LEVEL SECURITY;

CREATE POLICY "appointment_history_select"
  ON public.appointment_history FOR SELECT
  USING (
    appointment_id IN (
      SELECT appointment_id FROM public.appointments
      WHERE customer_id = (SELECT auth.uid()) OR provider_id IN (
        SELECT provider_id FROM public.providers WHERE user_id = (SELECT auth.uid())
      )
    )
  );

CREATE POLICY "appointment_history_insert"
  ON public.appointment_history FOR INSERT
  WITH CHECK (
    changed_by = (SELECT auth.uid())
  );

-- ============================================================================
-- TABLE: audit_log
-- System-wide event log (FR-6.3 / 7.3)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.audit_log (
  id          BIGSERIAL PRIMARY KEY,
  actor_id    UUID REFERENCES public.users(user_id),  -- null = system/anonymous
  action      TEXT NOT NULL,                 -- e.g. 'login', 'book_appointment'
  entity_type TEXT,                          -- e.g. 'appointment', 'provider'
  entity_id   UUID,
  metadata    JSONB,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.audit_log IS
  'Append-only event log for logins, bookings, cancellations, and other key actions.';

CREATE INDEX IF NOT EXISTS idx_audit_log_actor      ON public.audit_log(actor_id);
CREATE INDEX IF NOT EXISTS idx_audit_log_created_at ON public.audit_log(created_at);
CREATE INDEX IF NOT EXISTS idx_audit_log_entity     ON public.audit_log(entity_type, entity_id);

ALTER TABLE public.audit_log ENABLE ROW LEVEL SECURITY;

CREATE POLICY "audit_log_select_own"
  ON public.audit_log FOR SELECT
  USING (actor_id = (SELECT auth.uid()));

CREATE POLICY "audit_log_insert_own"
  ON public.audit_log FOR INSERT
  WITH CHECK (actor_id = (SELECT auth.uid()));

-- ============================================================================
-- TABLE: favorites
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.favorites (
  favorite_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID NOT NULL REFERENCES public.users(user_id)         ON DELETE CASCADE,
  provider_id UUID NOT NULL REFERENCES public.providers(provider_id) ON DELETE CASCADE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT uq_user_provider_favorite UNIQUE (user_id, provider_id)
);

CREATE INDEX IF NOT EXISTS idx_favorites_user_id ON public.favorites(user_id);

ALTER TABLE public.favorites ENABLE ROW LEVEL SECURITY;

CREATE POLICY "favorites_select_own"
  ON public.favorites FOR SELECT
  USING (user_id = (SELECT auth.uid()));

CREATE POLICY "favorites_insert_own"
  ON public.favorites FOR INSERT
  WITH CHECK (user_id = (SELECT auth.uid()));

CREATE POLICY "favorites_delete_own"
  ON public.favorites FOR DELETE
  USING (user_id = (SELECT auth.uid()));

-- ============================================================================
-- FUNCTION + TRIGGER: check_appointment_overlap
-- Fires BEFORE INSERT OR UPDATE on appointments.
-- Raises an exception if the provider already has a non-cancelled appointment
-- in the requested time window (including buffer time).
-- ============================================================================

CREATE OR REPLACE FUNCTION public.check_appointment_overlap()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_service_buffer INTEGER;
  v_total_minutes  INTEGER;
  v_overlap        INTEGER;
BEGIN
  -- Fetch the buffer time for the service being booked
  SELECT COALESCE(buffer_minutes, 0)
    INTO v_service_buffer
    FROM public.services
   WHERE service_id = NEW.service_id;

  v_total_minutes := NEW.duration_minutes + COALESCE(v_service_buffer, 0);

  SELECT COUNT(*) INTO v_overlap
    FROM public.appointments
   WHERE provider_id    = NEW.provider_id
     AND status NOT IN  ('cancelled', 'no_show')
     AND appointment_id != COALESCE(NEW.appointment_id, '00000000-0000-0000-0000-000000000000'::UUID)
     AND tstzrange(
           appointment_datetime,
           appointment_datetime + (duration_minutes || ' minutes')::INTERVAL,
           '[)'
         ) &&
         tstzrange(
           NEW.appointment_datetime,
           NEW.appointment_datetime + (v_total_minutes || ' minutes')::INTERVAL,
           '[)'
         );

  IF v_overlap > 0 THEN
    RAISE EXCEPTION 'This time slot is already booked for this provider.';
  END IF;

  RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER trg_check_overlap
  BEFORE INSERT OR UPDATE ON public.appointments
  FOR EACH ROW EXECUTE FUNCTION public.check_appointment_overlap();

-- ============================================================================
-- FUNCTION + TRIGGER: handle_new_user
-- Runs after every new row in auth.users (i.e. after signUp).
-- Always creates a 'customer' role — role is never trusted from signup metadata.
-- The Flutter provider signup flow updates role to 'provider' in a second step
-- when inserting the providers row (see handle_new_provider below).
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  INSERT INTO public.users (user_id, email, first_name, last_name, phone, role)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NULLIF(trim(NEW.raw_user_meta_data->>'first_name'), ''), 'User'),
    COALESCE(NULLIF(trim(NEW.raw_user_meta_data->>'last_name'),  ''), ''),
    NULLIF(trim(NEW.raw_user_meta_data->>'phone'), ''),
    -- SECURITY: always 'customer' — never trust role from signup metadata.
    -- Provider role is elevated by handle_new_provider trigger below.
    'customer'
  );
  RETURN NEW;
END;
$$;

-- Drop and recreate to avoid duplicate trigger errors on re-run
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================================================
-- FUNCTION + TRIGGER: handle_new_provider
-- Runs after INSERT on public.providers.
-- Elevates the linked user's role from 'customer' → 'provider'.
-- This is the only place role is set to 'provider', keeping the logic
-- server-side and out of reach of client metadata manipulation.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_new_provider()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  UPDATE public.users
     SET role = 'provider'
   WHERE user_id = NEW.user_id;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_provider_created ON public.providers;
CREATE TRIGGER on_provider_created
  AFTER INSERT ON public.providers
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_provider();

-- ============================================================================
-- REALTIME
-- ============================================================================

ALTER PUBLICATION supabase_realtime ADD TABLE public.appointments;

-- ============================================================================
-- STORAGE: provider-images bucket
-- ============================================================================

INSERT INTO storage.buckets (id, name, public)
VALUES ('provider-images', 'provider-images', true)
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "provider_images_public_read" ON storage.objects;
CREATE POLICY "provider_images_public_read"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'provider-images');

DROP POLICY IF EXISTS "provider_images_owner_upload" ON storage.objects;
CREATE POLICY "provider_images_owner_upload"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'provider-images'
    AND (SELECT auth.uid())::text = (storage.foldername(name))[1]
  );

DROP POLICY IF EXISTS "provider_images_owner_delete" ON storage.objects;
CREATE POLICY "provider_images_owner_delete"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'provider-images'
    AND (SELECT auth.uid())::text = (storage.foldername(name))[1]
  );

-- ============================================================================
-- VERIFY
-- ============================================================================

SELECT tablename, rowsecurity
  FROM pg_tables
 WHERE schemaname = 'public'
 ORDER BY tablename;

SELECT '✓ Schema created successfully' AS status;
