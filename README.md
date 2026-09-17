<p align="center">
  <img src="assets/icon/app_icon.png" alt="Riyal app icon" width="120" />
</p>

<h1 align="center">Riyal</h1>

<p align="center">
  <strong>Know where your money goes.</strong><br />
  A bilingual mobile app for understanding recurring spending, planning budgets,
  and staying ahead of upcoming payments.
</p>

## About Riyal

Riyal brings subscriptions, utility bills, and people-related payments into one
clear financial view. It helps users understand their monthly commitments,
compare spending with their budgets, and receive useful alerts before a payment
or free trial becomes a surprise.

The app was created as a student project and uses a simulated bank connection
flow with seeded transaction data. It does not connect to real bank accounts.

## Features

- **Unified recurring payments** — manage subscriptions, utilities, and
  people-related commitments in one place.
- **Budget onboarding** — new users can set a separate monthly budget for every
  spending domain.
- **Budget monitoring** — progress indicators turn orange near the limit and red
  when the budget is reached or exceeded.
- **Spending analytics** — view total and category-level spending, trends, and
  budget progress.
- **Free-trial tracking** — create weekly or monthly trials and receive an
  in-app reminder five days before they end.
- **Smart notifications** — get alerts for upcoming payments, budget limits,
  subscription price increases, trial endings, and monthly reviews.
- **Recurring-payment detection** — identify repeating charges in simulated
  bank transactions and add them to the appropriate category.
- **Flexible bank setup** — connect a simulated bank or skip the step and add
  commitments manually.
- **Riyal Bot** — ask budgeting and recurring-payment questions through a
  Gemini-powered assistant.
- **Arabic and English** — switch between fully localized RTL and LTR
  experiences.
- **Responsive interface** — a dark green and gold design built for different
  mobile screen sizes.

## App Tour

| Area | What it provides |
| --- | --- |
| Overview | Monthly recurring spend and a breakdown by domain |
| Analytics | Total and category-level budgets, progress, and trends |
| Subscriptions | Subscription details, free trials, renewals, and price history |
| Utilities | Recurring household bills and payment tracking |
| People | Salaries, allowances, and other people-related payments |
| Accounts | Simulated bank accounts and detected recurring transactions |
| Notifications | Payment, trial, budget, and price-change alerts |
| Riyal Bot | AI-assisted guidance for budgets and recurring commitments |

## Technology

- Flutter and Dart
- Supabase Authentication and PostgreSQL
- Gemini API for Riyal Bot
- Shared Preferences for local settings and read state
- `flutter_svg` for scalable icons and logos

## Getting Started

### Prerequisites

- Flutter SDK with Dart `3.10.8` or newer
- A Supabase project
- A Gemini API key if you want to enable Riyal Bot
- An Android emulator, iOS simulator, or physical device

### 1. Clone the repository

```bash
git clone https://github.com/Danah-R/Riyal.git
cd Riyal
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Configure environment variables

Copy `.env.example` to a new `.env` file:

```bash
cp .env.example .env
```

On Windows PowerShell, use:

```powershell
Copy-Item .env.example .env
```

Then add your project values:

```env
SUPABASE_URL=https://<your-project-ref>.supabase.co
SUPABASE_ANON_KEY=<your-supabase-anon-key>

GEMINI_API_KEY=<your-gemini-api-key>
GEMINI_MODEL=gemini-3.8-flash
```

The Gemini fields are optional. Riyal Bot requires them, while the rest of the
app can still run without them.

### 4. Prepare Supabase

Apply the SQL migrations in `supabase/migrations` in numeric order. With the
Supabase CLI installed, run:

```bash
supabase login
supabase link --project-ref <your-project-ref>
supabase db push
```

Alternatively, open the SQL Editor in the Supabase dashboard and run each
migration file manually in numeric order.

The app uses Supabase email and password authentication. For faster local
testing, email confirmation can be disabled from **Authentication > Providers >
Email** in the Supabase dashboard.

### 5. Run the app

```bash
flutter run
```

## Quality Checks

Run static analysis:

```bash
flutter analyze
```

Run the test suite:

```bash
flutter test
```

The tests cover responsive layouts, authentication screens, budget behavior,
free trials, notification generation, recurring-payment detection, item views,
and Riyal Bot rendering.

## Project Structure

```text
lib/
├── data/       Data models, stores, budgets, detection, and Supabase access
├── l10n/       Arabic and English localization
├── screens/    Application screens and user flows
├── services/   Gemini API integration and Riyal Bot configuration
├── theme/      Colors, typography, and application theme
└── widgets/    Shared responsive UI components

supabase/
└── migrations/ Database schema, policies, and seeded demo data

test/           Widget and unit tests
```

## Developers

| Arabic | English |
| --- | --- |
| فلوة اليحيى | Fulwah Alyahya |
| دانه التميمي | Danah Altamimi |
