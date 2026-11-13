-- Create the delivery_routes table in Supabase.
-- Run this once in the Supabase SQL editor if the table doesn't exist yet.
-- The Flutter app's sync engine will then push/pull routes automatically.

CREATE TABLE IF NOT EXISTS public.delivery_routes (
  id          bigserial PRIMARY KEY,
  uuid        text        NOT NULL UNIQUE,
  route_name  text        NOT NULL,
  municipality text       NOT NULL DEFAULT '',
  assigned_rep_name text  NULL,
  delivery_days text      NOT NULL DEFAULT '',
  customer_count integer  NOT NULL DEFAULT 0,
  status      text        NOT NULL DEFAULT 'active',
  is_deleted  boolean     NOT NULL DEFAULT false,
  sync_status text        NOT NULL DEFAULT 'synced',
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

-- Enable RLS (consistent with all other tables in this project)
ALTER TABLE public.delivery_routes ENABLE ROW LEVEL SECURITY;

-- Allow any authenticated session to read routes
CREATE POLICY "Authenticated users can read delivery_routes"
  ON public.delivery_routes FOR SELECT
  TO authenticated
  USING (true);

-- Allow any authenticated session to insert/update routes
-- (Admin-only restriction is enforced app-side; tighten here if needed)
CREATE POLICY "Authenticated users can upsert delivery_routes"
  ON public.delivery_routes FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Authenticated users can update delivery_routes"
  ON public.delivery_routes FOR UPDATE
  TO authenticated
  USING (true);
