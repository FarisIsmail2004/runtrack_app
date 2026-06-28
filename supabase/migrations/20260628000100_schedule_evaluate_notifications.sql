-- Invoke evaluate-notifications hourly. pg_cron schedules; pg_net performs the
-- HTTP POST with the shared cron secret the function checks. The function is
-- idempotent via notification_log, so an extra tick never double-sends.

create extension if not exists pg_cron;
create extension if not exists pg_net;

-- Remove any prior schedule with this name (id-safe re-apply).
select cron.unschedule('evaluate-notifications-hourly')
where exists (select 1 from cron.job where jobname = 'evaluate-notifications-hourly');

select cron.schedule(
  'evaluate-notifications-hourly',
  '0 * * * *',
  $$
  select net.http_post(
    url     := 'https://<PROJECT_REF>.supabase.co/functions/v1/evaluate-notifications',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-cron-secret', '<CRON_SECRET>'
    ),
    body    := '{}'::jsonb
  );
  $$
);
