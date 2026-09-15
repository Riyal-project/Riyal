# Riyal on Supabase

Postgres holds everything: subscriptions, the mock bank catalog, each
user's connected mock banks, and the canned transaction history behind
them. There's no external banking integration and no Edge Function — bank
connections are entirely simulated for this student project, and every
table is read/written directly from the Flutter app via `supabase_flutter`.

## Setup

Since there's no `supabase` CLI available in this environment, apply the
migrations by hand: open your project's SQL editor at
`https://supabase.com/dashboard/project/<your-project-ref>/sql/new` and run
`supabase/migrations/0001_init.sql`, `0002_subscriptions_no_customer_fk.sql`,
and `0003_mock_banking.sql`, in that order (0001/0002 only apply if this is
a fresh project that never had them — an existing project that already
went through the old Lean setup only needs 0003).

If you do have the CLI available elsewhere:

```bash
supabase login
supabase link --project-ref <your-project-ref>
supabase db push
```

## Free trials

Apply `supabase/migrations/0013_subscription_free_trials.sql` in the
Supabase SQL editor before using the updated subscription forms. It adds
the nullable `trial_start_date` and `trial_duration` fields; existing
subscriptions retain their billing details. Trials use seven calendar
days or one calendar month (clamped to the last day of the next month).

Trial-ending reminders appear in the app's notification inbox five days
before the end date, respecting the global reminder switch and the item's
notification switch. The inbox refreshes when the app resumes and while
its notification button is mounted. These are in-app reminders.

## Auth

The app requires a real Supabase Auth account (email/password) to reach
Home — see `lib/data/auth_store.dart`. In the dashboard, **Authentication →
Providers → Email**, you can toggle "Confirm email" off for faster manual
testing; with it on, a new sign-up needs to click the confirmation link
before `signInWithPassword` will succeed.

## Pointing the Flutter app at it

Add to the app's `.env` (gitignored):

```
SUPABASE_URL=https://<your-project-ref>.supabase.co
SUPABASE_ANON_KEY=<your anon/public key, from Project Settings -> API>
```

The anon key is meant to be public-ish — it only grants what the
row-level-security policies below allow.

## Tables

- `subscriptions` — read/written directly by the app, keyed by a
  locally-generated device id (`lib/data/device_id_store.dart`) rather than
  the signed-in user, since subscriptions/utilities/staff entries aren't
  part of the bank-connection flow and predate real auth.
- `mock_banks` — a fixed catalog of 5 fake banks (name, brand color).
  Publicly readable.
- `user_bank_accounts` — one row per bank a signed-in user has "connected"
  via the mock connect flow (`lib/screens/connect_bank_screen.dart`).
  Scoped by `auth.uid()`.
- `mock_transactions` — a canned transaction history per bank, seeded once
  by `0003_mock_banking.sql`. Publicly readable; the app filters it by the
  banks a user has connected.
