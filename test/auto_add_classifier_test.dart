import 'package:flutter_test/flutter_test.dart';
import 'package:riyal/data/auto_add_classifier.dart';
import 'package:riyal/data/people_categories.dart';
import 'package:riyal/data/recurring_detection.dart';
import 'package:riyal/data/subscription.dart';
import 'package:riyal/data/subscription_category.dart';
import 'package:riyal/data/utility_categories.dart';

DetectedSubscription _detected(
  String merchantName, {
  String category = 'other',
  String? logoAsset,
}) => DetectedSubscription(
  merchantName: merchantName,
  amount: 45,
  cycle: BillingCycle.monthly,
  lastDate: DateTime(2026, 1, 1),
  occurrences: 4,
  category: category,
  logoAsset: logoAsset,
);

void main() {
  test('matches a subscription catalog merchant regardless of the raw '
      'transaction category tag', () {
    final result = classifyForAutoAdd(
      _detected('NETFLIX.COM', category: 'other'),
    );
    expect(result.domain, AutoAddDomain.subscription);
    expect(result.category, SubscriptionCategories.entertainment);
    expect(result.logoAsset, isNotNull);
  });

  test('matches a utility catalog merchant', () {
    final result = classifyForAutoAdd(
      _detected('ZAIN MOBILE BILL', category: 'subscription'),
    );
    expect(result.domain, AutoAddDomain.utility);
    expect(result.category, UtilityCategories.mobile);
  });

  test('falls back to People with an unassigned role when neither catalog '
      'matches', () {
    final result = classifyForAutoAdd(
      _detected('HOUSEKEEPER SALARY - FATIMA', category: 'person'),
    );
    expect(result.domain, AutoAddDomain.person);
    expect(result.category, PeopleCategories.unassigned);
  });

  test('prefers the transaction\'s own logo over the catalog guess', () {
    final result = classifyForAutoAdd(
      _detected(
        'NETFLIX.COM',
        logoAsset: 'lib/assets/logos/custom-netflix.png',
      ),
    );
    expect(result.logoAsset, 'lib/assets/logos/custom-netflix.png');
  });

  test('the auto-add threshold is 4 occurrences', () {
    expect(RecurringDetectionEngine.autoAddOccurrences, 4);
  });

  test(
    'matches a catalog entry spelled with "+" against a merchant that '
    'spells it out as the word "PLUS" (regression: Disney+ was wrongly '
    'falling through to People over this)',
    () {
      final result = classifyForAutoAdd(_detected('DISNEY PLUS'));
      expect(result.domain, AutoAddDomain.subscription);
      expect(result.category, SubscriptionCategories.entertainment);
    },
  );

  test('matches other "+"-named catalog entries the same way', () {
    expect(
      classifyForAutoAdd(_detected('APPLE TV PLUS SUBSCRIPTION')).domain,
      AutoAddDomain.subscription,
    );
    expect(
      classifyForAutoAdd(_detected('ICLOUD PLUS')).domain,
      AutoAddDomain.subscription,
    );
  });
}
