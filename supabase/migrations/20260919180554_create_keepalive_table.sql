CREATE TABLE IF NOT EXISTS public._keepalive (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  pinged_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public._keepalive ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "anon_select_keepalive" ON public._keepalive;
CREATE POLICY "anon_select_keepalive"
  ON public._keepalive
  FOR SELECT
  TO anon
  USING (true);

GRANT SELECT ON public._keepalive TO anon;

INSERT INTO public._keepalive DEFAULT VALUES;;
