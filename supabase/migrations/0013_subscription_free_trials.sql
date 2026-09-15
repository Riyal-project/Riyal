alter table public.subscriptions
  add column if not exists trial_start_date date,
  add column if not exists trial_duration text
    check (trial_duration in ('week', 'month'));

alter table public.subscriptions
  add constraint subscriptions_trial_fields_together
    check ((trial_start_date is null) = (trial_duration is null));
