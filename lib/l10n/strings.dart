import 'app_locale.dart';

/// A hand-rolled string table covering the app's Arabic translation.
/// Looked up by [AppLocale.locale] rather than `BuildContext` so call sites
/// stay a plain `Strings.t(key)`; switching languages rebuilds [MainApp]
/// from the root, which re-runs every descendant's `build()` and picks up
/// the new table.
///
/// Scope: all app chrome (labels, buttons, hints, empty states, errors)
/// translates. Brand/product names (Netflix, STC, Zain, ...) and bank-style
/// merchant strings stay as written — that matches how real banking/
/// subscription apps render them even in Arabic locales, and translating a
/// proper noun isn't really "translation". Amount displays use the "⃁"
/// currency symbol instead of a locale-dependent word, so they read the
/// same in both languages.
///
/// A handful of sentences interpolate a dynamic word (a count, a category
/// name, a period) where English and Arabic word order differ enough that
/// naive interpolation would produce a broken mixed-order sentence. Those
/// are built as small helper functions below (e.g. [renewsIn],
/// [emptyDomainMessage]) that branch on locale internally instead of via
/// [t], and screens with many such cases (analytics) branch inline with
/// `AppLocale.locale.value.languageCode == 'ar'`.
class Strings {
  Strings._();

  static bool get _isArabic => AppLocale.locale.value.languageCode == 'ar';

  static String t(String key) {
    final table = _isArabic ? _ar : _en;
    return table[key] ?? _en[key] ?? key;
  }

  /// [t] with the first `%s` in the template replaced by [value]. For
  /// templates with a single dynamic fragment where English/Arabic word
  /// order around it otherwise matches (e.g. "SAR %s left").
  static String f(String key, String value) => t(key).replaceFirst('%s', value);

  // ---- Helpers for sentences with a dynamic, order-sensitive fragment ----

  static String renewsIn(int days) {
    if (days <= 0) return t('renews_today');
    return _isArabic ? 'يتجدد خلال $days يومًا' : 'Renews in $days days';
  }

  static String inDays(int days) =>
      _isArabic ? 'خلال $days يومًا' : 'in $days days';

  static String addA(String noun) => _isArabic ? 'أضف $noun' : 'Add a $noun';

  static String daysAgo(int days) =>
      _isArabic ? 'منذ $days يوم' : '${days}d ago';

  static String reminderLeadNote(int leadDays) => _isArabic
      ? 'تذكير: $leadDays أيام قبل الدفع.'
      : 'Reminder: $leadDays days before payment.';

  static String utilityAnomalyMessage({
    required String name,
    required double currentAmount,
    required double averageAmount,
    required int percentAbove,
  }) {
    final current = currentAmount.toStringAsFixed(2);
    final average = averageAmount.toStringAsFixed(2);
    return _isArabic
        ? 'فاتورة $name هذا الشهر (ريال $current) أعلى بنسبة $percentAbove% من متوسطك (ريال $average) — تحقق من وجود تسرب'
        : 'Your $name this month (SAR $current) is $percentAbove% higher than your average (SAR $average) — check for leaks';
  }

  static String emptyDomainMessage(String pluralNoun) => _isArabic
      ? 'لا يوجد $pluralNoun حتى الآن.\nاضغط + لإضافة واحد.'
      : 'No $pluralNoun yet.\nTap + to add one.';

  static String noMatchMessage(String pluralNoun, String query) => _isArabic
      ? 'لا توجد نتائج لـ "$query" ضمن $pluralNoun.'
      : 'No $pluralNoun match "$query".';

  static String noCategoryMessage(String categoryLabel, String pluralNoun) =>
      _isArabic
      ? 'لا يوجد $pluralNoun من فئة $categoryLabel حتى الآن.'
      : 'No ${categoryLabel.toLowerCase()} $pluralNoun yet.';

  static const _monthsEn = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  static const _monthsAr = [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];

  /// [month1to12] is 1-indexed (January = 1).
  static String monthAbbrev(int month1to12) =>
      (_isArabic ? _monthsAr : _monthsEn)[month1to12 - 1];

  static const _weekdaysEn = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  static const _weekdaysAr = ['أحد', 'إثن', 'ثلا', 'أرب', 'خمي', 'جمع', 'سبت'];

  /// [sundayIndex0to6] is 0-indexed starting from Sunday.
  static String weekdayAbbrev(int sundayIndex0to6) =>
      (_isArabic ? _weekdaysAr : _weekdaysEn)[sundayIndex0to6];

  /// Display text for the three top-level analytics/spending categories.
  /// The underlying value ('Subscriptions'/'Utilities'/'People') stays
  /// English wherever it's used as a lookup key or compared for equality —
  /// this is purely for what's shown on screen.
  static String categoryDisplay(String category) => switch (category) {
    'Subscriptions' => t('nav_subscriptions'),
    'Utilities' => t('nav_utilities'),
    'People' => t('nav_people'),
    _ => category,
  };

  static String subscriptionPriceIncreaseMessage({
    required String name,
    required double previousAmount,
    required double newAmount,
  }) {
    final previous = previousAmount.toStringAsFixed(2);
    final current = newAmount.toStringAsFixed(2);
    return _isArabic
        ? 'ارتفع سعر اشتراك $name من $previous ر.س إلى $current ر.س.'
        : '$name increased from SAR $previous to SAR $current.';
  }

  /// "We noticed Netflix charges you 49 SAR monthly — added to your
  /// Subscriptions." — used when a recurring bank charge crosses the
  /// auto-add occurrence threshold and is matched against the
  /// subscription/utility reference catalog.
  static String autoAddedItemMessage({
    required String name,
    required double amount,
    required bool isMonthly,
    required String categoryDisplay,
  }) {
    final cadence = isMonthly
        ? (_isArabic ? 'شهريًا' : 'monthly')
        : (_isArabic ? 'سنويًا' : 'yearly');
    final amountText = amount.toStringAsFixed(0);
    return _isArabic
        ? 'لاحظنا أن $name يحصّل منك ريال $amountText $cadence — تمت إضافته إلى $categoryDisplay.'
        : 'We noticed $name charges you $amountText SAR $cadence — added to your $categoryDisplay.';
  }

  /// "We noticed a recurring payment to [payee] — added to People, tap to
  /// fill in details." — used when a recurring bank charge crosses the
  /// auto-add threshold but matches neither reference catalog.
  static String autoAddedPersonMessage(String name) => _isArabic
      ? 'لاحظنا دفعة متكررة إلى $name — تمت إضافته إلى الأفراد، اضغط لإكمال التفاصيل.'
      : 'We noticed a recurring payment to $name — added to People, tap to fill in details.';

  /// Display text for analytics demo "group" names (finer-grained than the
  /// three top-level categories, e.g. 'Streaming', 'Fitness').
  static String groupDisplay(String group) => t('group_${_slug(group)}');

  static String _slug(String s) => s.toLowerCase().replaceAll(' ', '_');

  static const _en = <String, String>{
    'connect_bank_optional_subtitle':
        'Connect a bank now, or skip and add one later from Accounts.',
    'skip_bank_now': 'Skip now',
    'skip_bank_manual_hint': 'Add manually from scratch',
    'notice_subscription_price_increase': 'Subscription price increased',
    'total_spend_this_month': 'Total spend this month',
    'compared_with_last_month': '%s vs. last month',
    'budget_setup_title': 'Your monthly budgets',
    'budget_setup_intro':
        'How much would you like to budget for each category?',
    'budget_setup_note':
        'Set a monthly limit for subscriptions, bills, and salaries / allowances. Zero means no planned spending. We will warn you at 80% and when you reach your limit.',
    'budget_invalid_amount': 'Enter a valid amount of zero or more.',
    'budget_save_error': 'Could not save your budgets. Please try again.',
    'budget_save': 'Save budgets',
    'budget_monthly': 'Monthly budget',
    'budget_committed': 'Monthly commitments',
    'budget_edit': 'Edit',
    'budget_set': 'Set budget',
    'budget_not_set': 'Set your budgets to track monthly commitments.',
    'budget_near': 'Approaching your budget',
    'budget_reached': 'Budget reached or exceeded',
    'budget_within': 'Within your budget',
    'budget_near_notice': 'You are approaching your budget',
    'budget_exceeded_notice': 'Your budget has been reached or exceeded',
    'free_trial': 'Free Trial',
    'category_free_trial': 'Free Trial',
    'trial_duration': 'Free trial duration',
    'trial_week': 'One week',
    'trial_month': 'One month',
    'trial_start_date': 'Trial start date',
    'trial_end_date': 'Trial ends',
    'trial_amount': 'Renewal amount after trial (SAR)',
    'trial_renewal_amount': 'After trial: %s',
    'trial_ending_note': 'Reminder: five days before your trial ends.',
    'trial_cycle': 'Billing cycle after trial',
    'trial_reminder_hint':
        'A notification will appear five days before your trial ends.',
    'trial_ending_title': 'Your free trial is ending soon',
    'trial_ending_message': '%s · Your free trial ends on',
    'trial_added_message': '%s · Free trial ends on',
    'trial_ended': 'Free trial ended',
    'invalid_subscription_amount': 'Enter a valid amount of zero or more.',
    // Bottom nav
    'nav_home': 'Home',
    'nav_subscriptions': 'Subscriptions',
    'nav_utilities': 'Utilities',
    'nav_people': 'People',

    // Shared / generic
    'renews_today': 'Renews today',
    'analytics_tab': 'Analytics',
    'accounts_tab': 'Accounts',
    'recurring_payments_found_count': '%s recurring payments found',
    'no_recurring_payments_found': 'No recurring payments found yet',
    'add_suggestion_where_title': 'Add this as…',
    'add_suggestion_where_sub':
        'Choose where it belongs, and adjust anything before saving.',
    'general': 'General',
    'upcoming_renewals': 'Upcoming renewals',
    'see_all': 'See all',
    'cancel': 'Cancel',
    'save': 'Save',
    'close': 'Close',
    'back': 'Back',

    // Settings (kept for reference; settings_screen.dart already uses these)
    'settings_title': 'Settings',
    'settings_header_title': 'Make Riyal yours',
    'settings_header_subtitle': 'A few preferences for your everyday payments.',
    'payment_reminders_section': 'PAYMENT REMINDERS',
    'monthly_review_setting': 'Monthly money check-in',
    'monthly_review_setting_sub':
        'Get one reminder each month to review all commitments.',
    'monthly_review_day': 'Review reminder day',
    'day_of_month': 'Day %s',
    'monthly_review_card_title': 'Monthly money check-in',
    'monthly_review_card_sub':
        'Review your commitments and find saving opportunities.',
    'monthly_review_completed': 'Monthly review completed',
    'monthly_review_completed_sub':
        'View your suggestions. Your next check-in is next month.',
    'upcoming_payments': 'Upcoming payments',
    'upcoming_payments_sub': 'Renewals, utility bills and people payments.',
    'remind_before_payment': 'Remind me before payment',
    'day_singular': 'day',
    'day_plural': 'days',
    'reminder_note':
        'Applies to new reminders in your in-app inbox. Existing messages '
        'stay in your history. New-item notifications remain enabled.',
    'personal_details': 'Personal details',
    'personal_details_sub': 'Name, email and phone number',
    'currency': 'Currency',
    'currency_sub': 'Saudi riyal',
    'appearance': 'Appearance',
    'appearance_sub': 'Riyal dark theme',
    'language': 'Language',
    'language_sub': 'Choose your app language',
    'language_english': 'English',
    'language_arabic': 'العربية',
    'data_on_device_title': 'Your data, on your device',
    'data_on_device_body':
        'Profile edits, preferences and notification read status are saved '
        'locally on this device.',
    'help_feedback': 'Help & feedback',
    'help_feedback_sub': 'Quick answers and suggestions',
    'settings_footer': 'RIYAL',
    'settings_saved': 'Settings saved',
    'settings_save_failed': 'Could not save settings. Please try again.',

    // Home
    'greeting_hi': 'Hi, %s',
    'overview': 'Overview',
    'spending_heading': "This month's spending\non recurring payments",
    'of_sar_budget': 'of ⃁%s budget',
    'sar_left': '⃁%s left',
    'no_subscriptions_yet_short': 'No subscriptions yet.',

    // Category labels
    'category_entertainment': 'Entertainment',
    'category_ai': 'AI',
    'category_productivity': 'Productivity',
    'category_cloud_storage': 'Cloud & Storage',
    'category_fitness_wellness': 'Fitness & Wellness',
    'category_education': 'Education',
    'category_shopping_delivery': 'Shopping & Delivery',
    'category_other': 'Other',
    'category_electricity': 'Electricity',
    'category_water': 'Water',
    'category_internet': 'Internet',
    'category_mobile': 'Mobile',
    'category_gas': 'Gas',
    'category_household': 'Household',
    'category_childcare': 'Childcare',
    'category_allowance': 'Allowance',
    'category_driving': 'Driving',
    'category_security': 'Security',
    'category_unassigned': 'Role not set',
    'category_all': 'All',

    // Analytics groups (finer-grained demo groupings)
    'group_streaming': 'Streaming',
    'group_productivity': 'Productivity',
    'group_fitness': 'Fitness',
    'group_learning': 'Learning',
    'group_electricity': 'Electricity',
    'group_internet': 'Internet',
    'group_water': 'Water',
    'group_household': 'Household',
    'group_transport': 'Transport',

    // Domain nouns (Utilities / People)
    'noun_singular_utility_bill': 'utility bill',
    'noun_plural_utility_bill': 'utility bills',
    'add_from_scratch_utility_bill': 'Choose a provider',
    'noun_singular_people_member': 'person',
    'noun_plural_people_member': 'people',
    'add_from_scratch_people_member': 'Choose a role',
    'search_hint_utilities': 'Search utilities',
    'search_hint_people': 'Search people',
    'search_hint_subscriptions': 'Search subscriptions',

    // Analytics
    'analytics_general_title': 'General analytics',
    'illustrative_estimates':
        'Illustrative estimates based on your monthly data.',
    'category_split': 'Category split',
    'spending_breakdown': 'Spending breakdown',
    'overall_budget_vs_actual': 'Overall budget vs. actual',
    'category_budget_vs_actual': 'Category budget vs. actual',
    'combined_budget_note': 'Combined budget, separate from category limits.',
    'highest_cost_item': 'Highest-cost item',
    'highest_cost_items_tied': 'Highest-cost items · tied',
    'spend_over_time': 'Spend over time',
    'remaining': 'remaining',
    'over_budget': 'over budget',
    'each': 'each',
    'active_items': 'active items',
    'week_ending': 'Week ending',
    'period_week': 'Week',
    'period_month': 'Month',
    'period_year': 'Year',
    'period_adj_weekly': 'Weekly',
    'period_adj_monthly': 'Monthly',
    'period_adj_yearly': 'Yearly',

    // Add flows
    'add_a_subscription': 'Add a subscription',
    'how_would_you_add': 'How would you like to add it?',
    'from_previous_transaction': 'From a previous transaction',
    'pick_from_recent_charges': 'Pick from your recent charges',
    'from_scratch': 'From scratch',
    'choose_app_enter_details': 'Choose an app and enter the details',
    'add_other_app': 'Add another app',
    'custom_app_name': 'App name',
    'add_app_continue': 'Continue',
    'choose_an_app': 'Choose an app',
    'search_apps': 'Search apps',
    'no_apps_found': 'No apps found',
    'search_generic': 'Search',
    'no_results_found': 'No results found',
    'recent_transactions': 'Recent transactions',
    'tap_charge_to_track_item': 'Tap a charge to turn it into a tracked item',
    'tap_charge_to_track_subscription':
        'Tap a charge to turn it into a tracked subscription',
    'days_ago_suffix': 'd ago',

    // Details / add-item forms
    'subscription_details': 'Subscription details',
    'details': 'Details',
    'more_details_action': 'More details',
    'amount_sar': 'Amount (⃁)',
    'billing_cycle': 'Billing cycle',
    'monthly': 'Monthly',
    'yearly': 'Yearly',
    'category_field': 'Category',
    'filter_sheet_title': 'Filter & sort',
    'show_cancelled_label': 'Show cancelled',
    'sort_by_label': 'Sort by',
    'sort_newest': 'Newest',
    'sort_most_used': 'Most used',
    'sort_least_used': 'Least used',
    'next_billing_date': 'Next billing date',
    'add_subscription_button': 'Add subscription',

    // Profile
    'profile_title': 'Profile',
    'profile_load_failed':
        'Could not load saved profile. Showing default info.',
    'profile_field_updated': '%s updated',
    'profile_save_failed': 'Could not save changes. Please try again.',
    'your_profile': 'Your profile',
    'your_personal_details': 'Your personal details',
    'details_complete': 'Your details are complete',
    'complete_your_profile': 'Complete your profile',
    'details_added_count': '%s of 3 details added',
    'add_field': 'Add %s',
    'not_available': 'Not available',
    'add_your_field': 'Add your %s',
    'edit_field_tooltip': 'Edit %s',
    'profile_local_note': 'Your profile details are saved on this device.',
    'change_password': 'Change password',
    'edit_field_title': 'Edit %s',
    'field_full_name': 'Full name',
    'field_email': 'Email',
    'field_phone_number': 'Phone number',
    'field_joined_on': 'Joined on',

    // Profile validation
    'validation_required': 'This field is required',
    'validation_name_length': 'Enter a name between 2 and 80 characters',
    'validation_email': 'Enter a valid email',
    'validation_phone_local': 'Use 05XXXXXXXX or +9665XXXXXXXX',
    'validation_phone_country_code':
        'Include your country code, e.g. +9665XXXXXXXX',

    // Login / signup
    'brand_tagline': 'Your spending, in balance.',
    'login_heading': 'Login',
    'signin_subtitle': 'Sign in to your account',
    'username': 'Username',
    'email': 'Email',
    'password': 'Password',
    'sign_in_button': 'SIGN IN',
    'no_account_signup': "Don't have an account? Sign up",
    'finances_on_device': 'Your finances stay on your device',
    'enter_your_field': 'Enter your %s',
    'show_password': 'Show password',
    'hide_password': 'Hide password',
    'signup_heading': 'Sign up',
    'create_account_subtitle': 'Create your Riyal account',
    'full_name': 'Full name',
    'confirm_password': 'Confirm password',
    'create_account_button': 'CREATE ACCOUNT',
    'have_account_signin': 'Already have an account? Sign in',
    'valid_email_error': 'Enter a valid email',
    'password_length_error': 'Use at least 8 characters',
    'passwords_no_match': 'Passwords do not match',
    'sign_in_generic_error': 'Could not sign in. Please try again.',
    'sign_up_generic_error': 'Could not create your account. Please try again.',
    'check_email_to_confirm':
        'Check your email to confirm your account, then sign in.',

    // Splash
    'splash_tagline': 'Know where your money goes.',

    // Help
    'contact_us_title': 'Help',
    'contact_header_title': 'We are here to help',
    'contact_header_subtitle':
        'Have a question or an idea for Riyal? Start here.',
    'quick_answers': 'QUICK ANSWERS',
    'faq_q1': 'How do I add a payment?',
    'faq_a1':
        'Open Subscriptions, Utilities or People and use the add option. '
        'Choose an existing provider or enter the payment details.',
    'faq_q2': 'When will I get a reminder?',
    'faq_a2':
        'The default is five days before a payment. You can choose one, '
        'three, five or seven days in Settings. Reminders appear in the '
        'app while it is running or when you return to it.',
    'share_feedback': 'Share your feedback',
    'share_feedback_sub': 'Prepare a message to copy and share.',
    'topic': 'Topic',
    'topic_suggestion': 'Suggestion',
    'topic_report_issue': 'Report an issue',
    'topic_question': 'Question',
    'your_message': 'Your message',
    'message_hint': 'Tell us what could be better...',
    'message_min_length': 'Please write at least 10 characters.',
    'copying': 'Copying...',
    'copy_message': 'Copy message',
    'message_copied': 'Message copied. You can share it with the Riyal team.',
    'copy_failed': 'Could not copy. Select and copy the message manually.',
    'thank_you_feedback': 'Thank you for helping improve Riyal.',
    'feedback_message_header': 'Riyal feedback',

    // Change password
    'current_password': 'Current password',
    'new_password': 'New password',
    'confirm_new_password': 'Confirm new password',
    'enter_a_password': 'Enter a password',
    'choose_different_password': 'Choose a different password',
    'password_updated': 'Password updated',

    // Notifications
    'notifications_title': 'Notifications',
    'no_notifications_yet': 'No notifications yet',
    'all_notifications': 'All notifications',
    'show_less': 'Show less',
    'unread_notifications': 'Unread notifications',
    'account_menu': 'Account menu',
    'account': 'Account',
    'profile_menu_item': 'Profile',
    'settings_menu_item': 'Settings',
    'contact_us_menu_item': 'Help',
    'about_us_menu_item': 'About us',
    'about_us_menu_subtitle': 'Learn more about Riyal',
    'about_us_title': 'About us',
    'about_header_title': 'Meet Riyal',
    'about_header_subtitle':
        'A clearer way to understand and manage your recurring money.',
    'about_our_purpose': 'OUR PURPOSE',
    'about_our_purpose_body':
        'Riyal brings your subscriptions, utility bills and people payments '
        'together, so you can see what is due and make confident decisions.',
    'about_track_title': 'Everything in one place',
    'about_track_body':
        'Keep recurring commitments organized and easy to review.',
    'about_plan_title': 'Plan with your budget',
    'about_plan_body':
        'Compare spending with your limits before costs catch you by surprise.',
    'about_reminders_title': 'Stay one step ahead',
    'about_reminders_body':
        'Receive useful reminders for payments, trials and price changes.',
    'about_ai_title': 'Ask Riyal AI',
    'about_ai_body':
        'Get quick, friendly answers about your budgeting and spending, in Arabic or English.',
    'about_developers_title': 'APP DEVELOPERS',
    'linkedin_profile': 'LinkedIn',
    'about_made_for_you': 'Made with 💚 for the Saudi consumer',
    'log_out': 'Log out',

    // Bank accounts (mocked — see supabase/migrations/0003_mock_banking.sql)
    'accounts_title': 'Bank accounts',
    'accounts_sub': 'Connect and manage your bank accounts',
    'add_account': 'Add account',
    'no_accounts_yet': 'No bank accounts connected yet.\nTap + to connect one.',
    'disconnect': 'Disconnect',
    'connected_bank': 'Connected bank',
    'suggested_subscriptions': 'Needs your confirmation',
    'suggested_subscriptions_sub':
        'Charges we\'re not confident enough about yet to add automatically.',
    'add_suggestion': 'Add',
    'occurrences_count': '%s charges seen',

    // Mock bank connect flow
    'connect_bank_title': 'Connect a bank',
    'connect_bank_forced_title': 'Connect your first bank',
    'connect_bank_forced_subtitle':
        'Connect at least one bank account to continue to Riyal.',
    'choose_your_bank': 'Choose your bank',
    'bank_login_username_hint': 'National ID / Username',
    'bank_login_button': 'Log in',
    'connecting_to_bank': 'Connecting to %s…',
    'bank_connected_title': 'Bank connected!',
    'bank_connected_body': '%s has been linked to your Riyal account.',
    'bank_connect_failed': 'Could not connect. Please try again.',
    'continue_button': 'Continue',
    'done_button': 'Done',

    // Notification-generated text
    'notice_new_subscription': 'New subscription',
    'notice_new_commitment': 'New payment commitment',
    'notice_renewal_reminder': 'Subscription renewal reminder',
    'notice_payment_reminder': 'Payment reminder',
    'notice_utility_anomaly_title': 'Unusual bill',
    'notice_auto_added_title': 'Added automatically',
    'monthly_review_notice_title': 'Your monthly money check-in is ready',
    'monthly_review_notice_message':
        'Review your subscriptions and payment commitments to find saving opportunities.',

    // Item details page (Subscriptions / Utilities / People)
    'status_active': 'Active',
    'status_trial': 'Trial',
    'status_cancelled': 'Cancelled',
    'status_paused': 'Paused',
    'total_paid_to_date': 'Total paid to date',
    'still_using_this': 'Still using this?',
    'not_reviewed_this_month': 'Not reviewed yet this month',
    'price_history': 'Price history',
    'payment_history': 'Payment history',
    'no_payment_history_yet': 'No payment history yet',
    'purpose_tag_label': 'Purpose / notes',
    'reminder_date_label': 'Reminder date',
    'no_reminder_set': 'No reminder set',
    'amount_history': 'Amount history',
    'average_monthly_spend': 'Average monthly spend',
    'vs_last_bill': 'vs last bill',
    'not_enough_history': 'Not enough history yet',
    'role_label': 'Role',
    'notes_label': 'Notes',
    'add_notes_hint': 'Add a note…',
    'pause_allowance': 'Pause allowance',
    'resume_now': 'Resume now',
    'edit_confirm_title': 'Save changes?',
    'edit_confirm_message': 'Do you want to save these changes?',
    'logout_confirm_title': 'Log out?',
    'logout_confirm_message': 'Are you sure you want to log out?',
    'disconnect_confirm_title': 'Disconnect this card?',
    'disconnect_confirm_message':
        'Are you sure you want to disconnect this bank account?',
    'edit_action': 'Edit',
    'save_action': 'Save',
    'pause_action': 'Pause',
    'resume_action': 'Resume',
    'cancel_subscription_action': 'Cancel subscription',
    'delete_action': 'Delete',
    'delete_confirm_title': 'Delete this?',
    'delete_confirm_message':
        'Are you sure? You won\'t be able to recover it.',
    'delete_account_menu_item': 'Delete account',
    'delete_account_action': 'Delete account',
    'delete_account_confirm_title': 'Delete your account?',
    'delete_account_confirm_message':
        'Are you sure? Your profile and saved data on this device will be removed.',
    'delete_account_final_title': 'Delete your account for good?',
    'delete_account_final_message':
        'This is your last chance to cancel — after this, there\'s no way to get your account back.',
    'cancel_confirm_title': 'Cancel this subscription?',
    'cancel_confirm_message': 'You can still see it here, marked as cancelled.',
    'notifications_toggle_label': 'Notifications',
    'yearly_plan_nudge_title': 'Switch to yearly and save',
    'unusual_spike_label': 'Unusual spike',
    'check_for_leak_label': 'Check for leak/fault',
    'edit_subscription_title': 'Edit subscription',
    'edit_details_title': 'Edit details',
    'clear_action': 'Clear',
    'select_date_action': 'Select date',
    'not_set': 'Not set',
  };

  static const _ar = <String, String>{
    'connect_bank_optional_subtitle':
        'اربط حسابًا بنكيًا الآن، أو تخطَّ وأضفه لاحقًا من صفحة الحسابات.',
    'skip_bank_now': 'تخطي الآن',
    'skip_bank_manual_hint': 'أضفه يدويًا من البداية',
    'notice_subscription_price_increase': 'ارتفع سعر الاشتراك',
    'total_spend_this_month': 'إجمالي الإنفاق هذا الشهر',
    'compared_with_last_month': '%s مقارنة بالشهر الماضي',
    'budget_setup_title': 'ميزانياتك الشهرية',
    'budget_setup_intro': 'كم الميزانية اللي تبي تخصصها لكل قسم؟',
    'budget_setup_note':
        'حدد ميزانية شهرية للاشتراكات والفواتير والرواتب والبدلات. الصفر يعني ما خصصت مصروفًا للقسم. بننبهك عند ٨٠٪ وعند الوصول للميزانية.',
    'budget_invalid_amount': 'أدخل مبلغًا صحيحًا يساوي صفرًا أو أكثر.',
    'budget_save_error': 'تعذر حفظ الميزانيات، حاول مرة ثانية.',
    'budget_save': 'حفظ الميزانيات',
    'budget_monthly': 'الميزانية الشهرية',
    'budget_committed': 'الالتزامات الشهرية',
    'budget_edit': 'تعديل',
    'budget_set': 'حدد الميزانية',
    'budget_not_set': 'حدد ميزانياتك لمتابعة الالتزامات الشهرية.',
    'budget_near': 'اقتربت من ميزانيتك',
    'budget_reached': 'وصلت للميزانية أو تجاوزتها',
    'budget_within': 'ضمن الميزانية',
    'budget_near_notice': 'اقتربت من ميزانيتك',
    'budget_exceeded_notice': 'وصلت لميزانيتك أو تجاوزتها',
    'free_trial': 'تجربة مجانية',
    'category_free_trial': 'تجربة مجانية',
    'trial_duration': 'مدة التجربة المجانية',
    'trial_week': 'أسبوع',
    'trial_month': 'شهر',
    'trial_start_date': 'تاريخ بداية التجربة',
    'trial_end_date': 'تنتهي التجربة',
    'trial_amount': 'مبلغ التجديد بعد التجربة (ر.س)',
    'trial_renewal_amount': 'بعد التجربة: %s',
    'trial_ending_note': 'تذكير: قبل نهاية التجربة بخمسة أيام.',
    'trial_cycle': 'دورة الدفع بعد التجربة',
    'trial_reminder_hint': 'سيظهر تنبيه قبل نهاية التجربة بخمسة أيام.',
    'trial_ending_title': 'تجربتك المجانية تنتهي قريبًا',
    'trial_ending_message': '%s · تنتهي تجربتك المجانية بتاريخ',
    'trial_added_message': '%s · تنتهي التجربة المجانية بتاريخ',
    'trial_ended': 'انتهت التجربة المجانية',
    'invalid_subscription_amount': 'أدخل مبلغًا صحيحًا يساوي صفرًا أو أكثر.',
    'nav_home': 'الرئيسية',
    'nav_subscriptions': 'الاشتراكات',
    'nav_utilities': 'المرافق',
    'nav_people': 'الأفراد',

    'renews_today': 'يتجدد اليوم',
    'analytics_tab': 'التحليلات',
    'accounts_tab': 'الحسابات',
    'recurring_payments_found_count': 'تم رصد %s مدفوعات متكررة',
    'no_recurring_payments_found': 'لم يتم رصد مدفوعات متكررة بعد',
    'add_suggestion_where_title': 'أضف هذا كـ...',
    'add_suggestion_where_sub':
        'اختر التصنيف المناسب، وعدّل أي تفاصيل قبل الحفظ.',
    'general': 'عام',
    'upcoming_renewals': 'التجديدات القادمة',
    'see_all': 'عرض الكل',
    'cancel': 'إلغاء',
    'save': 'حفظ',
    'close': 'إغلاق',
    'back': 'رجوع',

    'settings_title': 'الإعدادات',
    'settings_header_title': 'اجعل ريال خاصًا بك',
    'settings_header_subtitle': 'بعض التفضيلات لمدفوعاتك اليومية.',
    'payment_reminders_section': 'تذكيرات الدفع',
    'monthly_review_setting': 'المراجعة المالية الشهرية',
    'monthly_review_setting_sub':
        'استلم تذكيرًا واحدًا كل شهر لمراجعة جميع التزاماتك.',
    'monthly_review_day': 'يوم تذكير المراجعة',
    'day_of_month': 'يوم %s',
    'monthly_review_card_title': 'مراجعتك المالية الشهرية',
    'monthly_review_card_sub': 'راجع التزاماتك واكتشف فرص التوفير.',
    'monthly_review_completed': 'اكتملت مراجعة هذا الشهر',
    'monthly_review_completed_sub':
        'اعرض اقتراحاتك. ستتوفر المراجعة القادمة الشهر المقبل.',
    'upcoming_payments': 'المدفوعات القادمة',
    'upcoming_payments_sub': 'التجديدات وفواتير المرافق ومدفوعات الأفراد.',
    'remind_before_payment': 'ذكّرني قبل الدفع',
    'day_singular': 'يوم',
    'day_plural': 'أيام',
    'reminder_note':
        'ينطبق على التذكيرات الجديدة في صندوق الوارد داخل التطبيق. '
        'الرسائل الحالية تبقى في سجلك. تظل إشعارات العناصر الجديدة مفعّلة.',
    'personal_details': 'البيانات الشخصية',
    'personal_details_sub': 'الاسم والبريد الإلكتروني ورقم الهاتف',
    'currency': 'العملة',
    'currency_sub': 'ريال سعودي',
    'appearance': 'المظهر',
    'appearance_sub': 'مظهر ريال الداكن',
    'language': 'اللغة',
    'language_sub': 'اختر لغة التطبيق',
    'language_english': 'English',
    'language_arabic': 'العربية',
    'data_on_device_title': 'بياناتك، على جهازك',
    'data_on_device_body':
        'يتم حفظ تعديلات الملف الشخصي والتفضيلات وحالة قراءة الإشعارات '
        'محليًا على هذا الجهاز.',
    'help_feedback': 'المساعدة والملاحظات',
    'help_feedback_sub': 'إجابات سريعة واقتراحات',
    'settings_footer': 'ريال',
    'settings_saved': 'تم حفظ الإعدادات',
    'settings_save_failed': 'تعذر حفظ الإعدادات. حاول مرة أخرى.',

    'greeting_hi': 'مرحبًا، %s',
    'overview': 'نظرة عامة',
    'spending_heading': 'إنفاق هذا الشهر\nعلى المدفوعات المتكررة',
    'of_sar_budget': 'من ميزانية %s ريال',
    'sar_left': 'متبقٍ %s ريال',
    'no_subscriptions_yet_short': 'لا توجد اشتراكات بعد.',

    'category_entertainment': 'ترفيه',
    'category_ai': 'الذكاء الاصطناعي',
    'category_productivity': 'الإنتاجية',
    'category_cloud_storage': 'التخزين السحابي',
    'category_fitness_wellness': 'اللياقة والعافية',
    'category_education': 'التعليم',
    'category_shopping_delivery': 'التسوق والتوصيل',
    'category_other': 'أخرى',
    'category_electricity': 'الكهرباء',
    'category_water': 'المياه',
    'category_internet': 'الإنترنت',
    'category_mobile': 'الجوال',
    'category_gas': 'الغاز',
    'category_household': 'المنزل',
    'category_childcare': 'رعاية الأطفال',
    'category_allowance': 'المصروف',
    'category_driving': 'القيادة',
    'category_security': 'الأمن',
    'category_unassigned': 'الدور غير محدد',
    'category_all': 'الكل',

    'group_streaming': 'البث',
    'group_productivity': 'الإنتاجية',
    'group_fitness': 'اللياقة',
    'group_learning': 'التعلم',
    'group_electricity': 'الكهرباء',
    'group_internet': 'الإنترنت',
    'group_water': 'المياه',
    'group_household': 'المنزل',
    'group_transport': 'المواصلات',

    'noun_singular_utility_bill': 'فاتورة مرافق',
    'noun_plural_utility_bill': 'فواتير المرافق',
    'add_from_scratch_utility_bill': 'اختر مزود الخدمة',
    'noun_singular_people_member': 'فرد',
    'noun_plural_people_member': 'أفراد',
    'add_from_scratch_people_member': 'اختر الدور',
    'search_hint_utilities': 'ابحث في المرافق',
    'search_hint_people': 'ابحث عن الأفراد',
    'search_hint_subscriptions': 'ابحث في الاشتراكات',

    'analytics_general_title': 'التحليلات العامة',
    'illustrative_estimates': 'تقديرات توضيحية استنادًا إلى بياناتك الشهرية.',
    'category_split': 'تقسيم الفئات',
    'spending_breakdown': 'تفصيل الإنفاق',
    'overall_budget_vs_actual': 'الميزانية الإجمالية مقابل الفعلي',
    'category_budget_vs_actual': 'ميزانية الفئة مقابل الفعلي',
    'combined_budget_note': 'ميزانية مجمعة، منفصلة عن حدود الفئات.',
    'highest_cost_item': 'العنصر الأعلى تكلفة',
    'highest_cost_items_tied': 'العناصر الأعلى تكلفة · متعادلة',
    'spend_over_time': 'الإنفاق عبر الزمن',
    'remaining': 'متبقٍ',
    'over_budget': 'تجاوز الميزانية',
    'each': 'لكل واحد',
    'active_items': 'عنصر نشط',
    'week_ending': 'الأسبوع المنتهي في',
    'period_week': 'أسبوع',
    'period_month': 'شهر',
    'period_year': 'سنة',
    'period_adj_weekly': 'الأسبوعي',
    'period_adj_monthly': 'الشهري',
    'period_adj_yearly': 'السنوي',

    'add_a_subscription': 'إضافة اشتراك',
    'how_would_you_add': 'كيف تود إضافته؟',
    'from_previous_transaction': 'من معاملة سابقة',
    'pick_from_recent_charges': 'اختر من عملياتك الأخيرة',
    'from_scratch': 'من البداية',
    'choose_app_enter_details': 'اختر تطبيقًا وأدخل التفاصيل',
    'add_other_app': 'إضافة تطبيق آخر',
    'custom_app_name': 'اسم التطبيق',
    'add_app_continue': 'متابعة',
    'choose_an_app': 'اختر تطبيقًا',
    'search_apps': 'ابحث عن التطبيقات',
    'no_apps_found': 'لم يتم العثور على تطبيقات',
    'search_generic': 'بحث',
    'no_results_found': 'لا توجد نتائج',
    'recent_transactions': 'المعاملات الأخيرة',
    'tap_charge_to_track_item': 'اضغط على عملية لتحويلها إلى عنصر متابَع',
    'tap_charge_to_track_subscription':
        'اضغط على عملية لتحويلها إلى اشتراك متابَع',
    'days_ago_suffix': 'ي مضت',

    'subscription_details': 'تفاصيل الاشتراك',
    'details': 'التفاصيل',
    'more_details_action': 'مزيد من التفاصيل',
    'amount_sar': 'المبلغ (ريال)',
    'billing_cycle': 'دورة الفوترة',
    'monthly': 'شهري',
    'yearly': 'سنوي',
    'category_field': 'الفئة',
    'filter_sheet_title': 'التصفية والترتيب',
    'show_cancelled_label': 'إظهار الملغاة',
    'sort_by_label': 'ترتيب حسب',
    'sort_newest': 'الأحدث',
    'sort_most_used': 'الأكثر استخدامًا',
    'sort_least_used': 'الأقل استخدامًا',
    'next_billing_date': 'تاريخ الفوترة القادم',
    'add_subscription_button': 'إضافة اشتراك',

    'profile_title': 'الملف الشخصي',
    'profile_load_failed':
        'تعذر تحميل الملف الشخصي المحفوظ. جارٍ عرض البيانات الافتراضية.',
    'profile_field_updated': 'تم تحديث %s',
    'profile_save_failed': 'تعذر حفظ التغييرات. حاول مرة أخرى.',
    'your_profile': 'ملفك الشخصي',
    'your_personal_details': 'بياناتك الشخصية',
    'details_complete': 'بياناتك مكتملة',
    'complete_your_profile': 'أكمل ملفك الشخصي',
    'details_added_count': 'تمت إضافة %s من أصل 3 بيانات',
    'add_field': 'أضف %s',
    'not_available': 'غير متاح',
    'add_your_field': 'أضف %s',
    'edit_field_tooltip': 'تعديل %s',
    'profile_local_note': 'تُحفظ بيانات ملفك الشخصي على هذا الجهاز.',
    'change_password': 'تغيير كلمة المرور',
    'edit_field_title': 'تعديل %s',
    'field_full_name': 'الاسم الكامل',
    'field_email': 'البريد الإلكتروني',
    'field_phone_number': 'رقم الهاتف',
    'field_joined_on': 'تاريخ الانضمام',

    'validation_required': 'هذا الحقل مطلوب',
    'validation_name_length': 'أدخل اسمًا يتراوح بين 2 و80 حرفًا',
    'validation_email': 'أدخل بريدًا إلكترونيًا صحيحًا',
    'validation_phone_local': 'استخدم 05XXXXXXXX أو +9665XXXXXXXX',
    'validation_phone_country_code': 'أدخل رمز الدولة، مثل +9665XXXXXXXX',

    'brand_tagline': 'إنفاقك، في توازن.',
    'login_heading': 'تسجيل الدخول',
    'signin_subtitle': 'سجّل الدخول إلى حسابك',
    'username': 'اسم المستخدم',
    'email': 'البريد الإلكتروني',
    'password': 'كلمة المرور',
    'sign_in_button': 'تسجيل الدخول',
    'no_account_signup': 'ليس لديك حساب؟ أنشئ حسابًا',
    'finances_on_device': 'تبقى بياناتك المالية على جهازك',
    'enter_your_field': 'أدخل %s',
    'show_password': 'إظهار كلمة المرور',
    'hide_password': 'إخفاء كلمة المرور',
    'signup_heading': 'إنشاء حساب',
    'create_account_subtitle': 'أنشئ حساب ريال الخاص بك',
    'full_name': 'الاسم الكامل',
    'confirm_password': 'تأكيد كلمة المرور',
    'create_account_button': 'إنشاء حساب',
    'have_account_signin': 'لديك حساب بالفعل؟ سجّل الدخول',
    'valid_email_error': 'أدخل بريدًا إلكترونيًا صحيحًا',
    'password_length_error': 'استخدم 8 أحرف على الأقل',
    'passwords_no_match': 'كلمتا المرور غير متطابقتين',
    'sign_in_generic_error': 'تعذر تسجيل الدخول. حاول مرة أخرى.',
    'sign_up_generic_error': 'تعذر إنشاء حسابك. حاول مرة أخرى.',
    'check_email_to_confirm':
        'تحقق من بريدك الإلكتروني لتأكيد حسابك، ثم سجّل الدخول.',

    'splash_tagline': 'اعرف إلى أين يذهب مالك.',

    'contact_us_title': 'المساعدة',
    'contact_header_title': 'نحن هنا للمساعدة',
    'contact_header_subtitle': 'لديك سؤال أو فكرة لتطبيق ريال؟ ابدأ هنا.',
    'quick_answers': 'إجابات سريعة',
    'faq_q1': 'كيف أضيف دفعة؟',
    'faq_a1':
        'افتح الاشتراكات أو المرافق أو الأفراد واستخدم خيار الإضافة. '
        'اختر مزودًا موجودًا أو أدخل تفاصيل الدفعة.',
    'faq_q2': 'متى سأحصل على تذكير؟',
    'faq_a2':
        'الافتراضي هو خمسة أيام قبل الدفع. يمكنك اختيار يوم أو ثلاثة أو '
        'خمسة أو سبعة أيام من الإعدادات. تظهر التذكيرات أثناء تشغيل '
        'التطبيق أو عند عودتك إليه.',
    'share_feedback': 'شارك ملاحظاتك',
    'share_feedback_sub': 'جهّز رسالة لنسخها ومشاركتها.',
    'topic': 'الموضوع',
    'topic_suggestion': 'اقتراح',
    'topic_report_issue': 'الإبلاغ عن مشكلة',
    'topic_question': 'سؤال',
    'your_message': 'رسالتك',
    'message_hint': 'أخبرنا بما يمكن تحسينه...',
    'message_min_length': 'يرجى كتابة 10 أحرف على الأقل.',
    'copying': 'جارٍ النسخ...',
    'copy_message': 'نسخ الرسالة',
    'message_copied': 'تم نسخ الرسالة. يمكنك مشاركتها مع فريق ريال.',
    'copy_failed': 'تعذر النسخ. حدد الرسالة وانسخها يدويًا.',
    'thank_you_feedback': 'شكرًا لمساعدتك في تحسين ريال.',
    'feedback_message_header': 'ملاحظات ريال',

    'current_password': 'كلمة المرور الحالية',
    'new_password': 'كلمة المرور الجديدة',
    'confirm_new_password': 'تأكيد كلمة المرور الجديدة',
    'enter_a_password': 'أدخل كلمة مرور',
    'choose_different_password': 'اختر كلمة مرور مختلفة',
    'password_updated': 'تم تحديث كلمة المرور',

    'notifications_title': 'الإشعارات',
    'no_notifications_yet': 'لا توجد إشعارات بعد',
    'all_notifications': 'جميع الإشعارات',
    'show_less': 'عرض أقل',
    'unread_notifications': 'إشعارات غير مقروءة',
    'account_menu': 'قائمة الحساب',
    'account': 'الحساب',
    'profile_menu_item': 'الملف الشخصي',
    'settings_menu_item': 'الإعدادات',
    'contact_us_menu_item': 'المساعدة',
    'about_us_menu_item': 'من نحن',
    'about_us_menu_subtitle': 'تعرّف أكثر على ريال',
    'about_us_title': 'من نحن',
    'about_header_title': 'تعرّف على ريال',
    'about_header_subtitle': 'طريقة أوضح لفهم مصروفاتك المتكررة وإدارتها.',
    'about_our_purpose': 'هدفنا',
    'about_our_purpose_body':
        'يجمع ريال اشتراكاتك وفواتير الخدمات ومدفوعات الأفراد في مكان واحد، '
        'لتعرف ما عليك وتتمكن من اتخاذ قرارات مالية بثقة.',
    'about_track_title': 'كل شيء في مكان واحد',
    'about_track_body': 'نظّم التزاماتك المتكررة وراجعها بسهولة.',
    'about_plan_title': 'خطط حسب ميزانيتك',
    'about_plan_body': 'قارن مصروفاتك بحدود ميزانيتك قبل أن تفاجئك التكاليف.',
    'about_reminders_title': 'كن دائمًا مستعدًا',
    'about_reminders_body':
        'استلم تنبيهات مفيدة للمدفوعات والتجارب المجانية وتغيّر الأسعار.',
    'about_ai_title': 'اسأل ريال الذكي',
    'about_ai_body':
        'احصل على إجابات سريعة وودودة حول ميزانيتك ومصروفاتك، بالعربية أو الإنجليزية.',
    'about_developers_title': 'مطورو التطبيق',
    'linkedin_profile': 'لينكدإن',
    'about_made_for_you': 'صُنع بـ 💚 للمستهلك السعودي',
    'log_out': 'تسجيل الخروج',

    'accounts_title': 'الحسابات البنكية',
    'accounts_sub': 'اربط حساباتك البنكية وأدرها',
    'add_account': 'إضافة حساب',
    'no_accounts_yet': 'لا توجد حسابات بنكية متصلة بعد.\nاضغط + لربط حساب.',
    'disconnect': 'قطع الاتصال',
    'connected_bank': 'بنك متصل',
    'suggested_subscriptions': 'بحاجة إلى تأكيدك',
    'suggested_subscriptions_sub':
        'مدفوعات لسنا واثقين بها بما يكفي لإضافتها تلقائيًا.',
    'add_suggestion': 'إضافة',
    'occurrences_count': 'شوهدت %s مرات',

    // Mock bank connect flow
    'connect_bank_title': 'ربط حساب بنكي',
    'connect_bank_forced_title': 'اربط أول حساب بنكي لك',
    'connect_bank_forced_subtitle':
        'اربط حساباً بنكياً واحداً على الأقل للمتابعة إلى ريال.',
    'choose_your_bank': 'اختر بنكك',
    'bank_login_username_hint': 'رقم الهوية / اسم المستخدم',
    'bank_login_button': 'تسجيل الدخول',
    'connecting_to_bank': 'جارٍ الاتصال بـ %s…',
    'bank_connected_title': 'تم ربط الحساب البنكي!',
    'bank_connected_body': 'تم ربط %s بحسابك في ريال.',
    'bank_connect_failed': 'تعذر الربط. حاول مرة أخرى.',
    'continue_button': 'متابعة',
    'done_button': 'تم',

    'notice_new_subscription': 'اشتراك جديد',
    'notice_new_commitment': 'التزام دفع جديد',
    'notice_renewal_reminder': 'تذكير بتجديد الاشتراك',
    'notice_payment_reminder': 'تذكير بالدفع',
    'notice_utility_anomaly_title': 'فاتورة غير معتادة',
    'notice_auto_added_title': 'أُضيف تلقائيًا',
    'monthly_review_notice_title': 'مراجعتك المالية الشهرية جاهزة',
    'monthly_review_notice_message':
        'راجع اشتراكاتك والتزاماتك المالية واكتشف فرص التوفير.',

    // Item details page (Subscriptions / Utilities / People)
    'status_active': 'نشط',
    'status_trial': 'تجريبي',
    'status_cancelled': 'ملغى',
    'status_paused': 'متوقف مؤقتًا',
    'total_paid_to_date': 'إجمالي المدفوع حتى الآن',
    'still_using_this': 'ألا زلت تستخدم هذا؟',
    'not_reviewed_this_month': 'لم تتم مراجعته هذا الشهر بعد',
    'price_history': 'سجل تغير السعر',
    'payment_history': 'سجل المدفوعات',
    'no_payment_history_yet': 'لا يوجد سجل مدفوعات حتى الآن',
    'purpose_tag_label': 'الغرض / ملاحظات',
    'reminder_date_label': 'تاريخ التذكير',
    'no_reminder_set': 'لا يوجد تذكير محدد',
    'amount_history': 'سجل المبالغ',
    'average_monthly_spend': 'متوسط الإنفاق الشهري',
    'vs_last_bill': 'مقارنة بآخر فاتورة',
    'not_enough_history': 'لا يوجد سجل كافٍ بعد',
    'role_label': 'الدور',
    'notes_label': 'ملاحظات',
    'add_notes_hint': 'أضف ملاحظة…',
    'pause_allowance': 'إيقاف المخصص مؤقتًا',
    'resume_now': 'استئناف الآن',
    'edit_confirm_title': 'تأكيد التعديل',
    'edit_confirm_message': 'هل تريد حفظ هذه التعديلات؟',
    'logout_confirm_title': 'تأكيد تسجيل الخروج',
    'logout_confirm_message': 'هل أنت متأكد من تسجيل الخروج؟',
    'disconnect_confirm_title': 'تأكيد فصل البطاقة',
    'disconnect_confirm_message': 'هل أنت متأكد من فصل هذا الحساب البنكي؟',
    'edit_action': 'تعديل',
    'save_action': 'حفظ',
    'pause_action': 'إيقاف مؤقت',
    'resume_action': 'استئناف',
    'cancel_subscription_action': 'إلغاء الاشتراك',
    'delete_action': 'حذف',
    'delete_confirm_title': 'هل تريد الحذف؟',
    'delete_confirm_message': 'هل أنت متأكد؟ لن تتمكن من استرجاعه.',
    'delete_account_menu_item': 'حذف الحساب',
    'delete_account_action': 'حذف الحساب',
    'delete_account_confirm_title': 'حذف حسابك؟',
    'delete_account_confirm_message':
        'هل أنت متأكد؟ ستتم إزالة ملفك الشخصي وبياناتك المحفوظة على هذا الجهاز.',
    'delete_account_final_title': 'حذف حسابك نهائيًا؟',
    'delete_account_final_message':
        'هذه فرصتك الأخيرة للتراجع — بعدها لن تتمكن من استرجاع حسابك.',
    'cancel_confirm_title': 'هل تريد إلغاء هذا الاشتراك؟',
    'cancel_confirm_message': 'سيبقى ظاهرًا هنا، مُعلَّمًا كملغى.',
    'notifications_toggle_label': 'الإشعارات',
    'yearly_plan_nudge_title': 'التبديل للسنوي يوفر لك',
    'unusual_spike_label': 'ارتفاع غير معتاد',
    'check_for_leak_label': 'تحقق من وجود تسرب أو عطل',
    'edit_subscription_title': 'تعديل الاشتراك',
    'edit_details_title': 'تعديل التفاصيل',
    'clear_action': 'مسح',
    'select_date_action': 'اختر تاريخًا',
    'not_set': 'غير محدد',
  };
}
