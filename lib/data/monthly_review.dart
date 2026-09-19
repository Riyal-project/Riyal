import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_locale.dart';
import 'device_id_store.dart';
import 'people_store.dart';
import 'subscription.dart';
import 'subscriptions_store.dart';
import 'utilities_store.dart';

enum ReviewDomain { subscription, utility, people }

enum ReviewActivity { none, low, medium, high }

enum ReviewNeed { keep, unsure, stop }

enum RecommendationType { cancel, pause, annualPlan, reviewPlan, keep }

/// Read-only display wording for a subscription's own check-in answer
/// (see the "Still using this?" card on [SubscriptionViewScreen]) — kept
/// separate from [MonthlyReviewScreen]'s own per-domain question labels
/// since those are scoped private to that screen's survey flow, while this
/// is just showing a past answer back, always in the subscription-domain
/// wording (this screen only ever displays subscriptions).
extension ReviewNeedDisplay on ReviewNeed {
  String get subscriptionLabel {
    final isArabic = AppLocale.locale.value.languageCode == 'ar';
    return switch (this) {
      ReviewNeed.keep => isArabic ? 'نعم' : 'Yes',
      ReviewNeed.unsure => isArabic ? 'غير متأكد' : 'Not sure',
      ReviewNeed.stop => isArabic ? 'لا' : 'No',
    };
  }
}

extension ReviewActivityDisplay on ReviewActivity {
  String get subscriptionLabel {
    final isArabic = AppLocale.locale.value.languageCode == 'ar';
    return switch (this) {
      ReviewActivity.none => isArabic ? 'ولا مرة' : 'Never',
      ReviewActivity.low => isArabic ? '1–2 يوم' : '1–2 days',
      ReviewActivity.medium => isArabic ? '3–4 أيام' : '3–4 days',
      ReviewActivity.high => isArabic ? '5+ أيام' : '5+ days',
    };
  }
}

class MonthlyReviewItem {
  const MonthlyReviewItem({
    required this.id,
    required this.name,
    required this.domain,
    required this.monthlyAmount,
    required this.cycle,
    this.logoAsset,
    this.icon,
    this.iconColor,
  });

  final String id;
  final String name;
  final ReviewDomain domain;
  final double monthlyAmount;
  final BillingCycle cycle;

  /// The item's own logo/icon — carried over from the real [Subscription]/
  /// [TrackedItem] this was built from, so the check-in shows the same
  /// branding as everywhere else instead of one generic icon per domain.
  final String? logoAsset;
  final IconData? icon;
  final Color? iconColor;

  static List<MonthlyReviewItem> currentItems() {
    String id(ReviewDomain domain, String name) =>
        '${domain.name}:${name.trim().toLowerCase()}';

    return [
      for (final item in SubscriptionsStore.instance.subscriptions.value)
        MonthlyReviewItem(
          id: id(ReviewDomain.subscription, item.name),
          name: item.name,
          domain: ReviewDomain.subscription,
          monthlyAmount: item.monthlyAmount,
          cycle: item.cycle,
          logoAsset: item.logoAsset,
        ),
      for (final item in UtilitiesStore.instance.items.value)
        MonthlyReviewItem(
          id: id(ReviewDomain.utility, item.name),
          name: item.name,
          domain: ReviewDomain.utility,
          monthlyAmount: item.monthlyAmount,
          cycle: item.cycle,
          logoAsset: item.logoAsset,
          icon: item.icon,
          iconColor: item.iconColor,
        ),
      for (final item in PeopleStore.instance.items.value)
        MonthlyReviewItem(
          id: id(ReviewDomain.people, item.name),
          name: item.name,
          domain: ReviewDomain.people,
          monthlyAmount: item.monthlyAmount,
          cycle: item.cycle,
          logoAsset: item.logoAsset,
          icon: item.icon,
          iconColor: item.iconColor,
        ),
    ];
  }
}

class MonthlyReviewAnswer {
  const MonthlyReviewAnswer({
    required this.item,
    required this.activity,
    required this.need,
    required this.continueForYear,
  });

  final MonthlyReviewItem item;
  final ReviewActivity activity;
  final ReviewNeed need;
  final bool continueForYear;

  Map<String, Object> toJson() => {
    'id': item.id,
    'name': item.name,
    'domain': item.domain.name,
    'monthlyAmount': item.monthlyAmount,
    'cycle': item.cycle.name,
    'activity': activity.name,
    'need': need.name,
    'continueForYear': continueForYear,
  };
}

class SavingRecommendation {
  const SavingRecommendation({
    required this.item,
    required this.type,
    required this.monthlySaving,
  });

  final MonthlyReviewItem item;
  final RecommendationType type;
  final double monthlySaving;

  double get annualSaving => monthlySaving * 12;
}

class MonthlyReviewSnapshot {
  const MonthlyReviewSnapshot({
    required this.completedAt,
    required this.answers,
    required this.recommendations,
  });

  final DateTime completedAt;
  final List<MonthlyReviewAnswer> answers;
  final List<SavingRecommendation> recommendations;
}

class MonthlyReviewEngine {
  const MonthlyReviewEngine._();

  static List<SavingRecommendation> evaluate(
    Iterable<MonthlyReviewAnswer> answers,
  ) {
    return answers.map(_evaluateOne).toList();
  }

  static SavingRecommendation _evaluateOne(MonthlyReviewAnswer answer) {
    final item = answer.item;
    switch (item.domain) {
      case ReviewDomain.subscription:
        if (answer.need == ReviewNeed.stop ||
            answer.activity == ReviewActivity.none) {
          return SavingRecommendation(
            item: item,
            type: RecommendationType.cancel,
            monthlySaving: item.monthlyAmount,
          );
        }
        if (answer.activity == ReviewActivity.high &&
            answer.continueForYear &&
            item.cycle == BillingCycle.monthly) {
          return SavingRecommendation(
            item: item,
            type: RecommendationType.annualPlan,
            monthlySaving: 0,
          );
        }
        if (answer.need == ReviewNeed.unsure ||
            answer.activity == ReviewActivity.low) {
          return SavingRecommendation(
            item: item,
            type: RecommendationType.reviewPlan,
            monthlySaving: 0,
          );
        }
        break;
      case ReviewDomain.utility:
        if (answer.need == ReviewNeed.stop) {
          return SavingRecommendation(
            item: item,
            type: RecommendationType.cancel,
            monthlySaving: item.monthlyAmount,
          );
        }
        if (answer.need == ReviewNeed.unsure ||
            answer.activity == ReviewActivity.high) {
          return SavingRecommendation(
            item: item,
            type: RecommendationType.reviewPlan,
            monthlySaving: 0,
          );
        }
        break;
      case ReviewDomain.people:
        if (answer.need == ReviewNeed.stop ||
            answer.activity == ReviewActivity.none) {
          return SavingRecommendation(
            item: item,
            type: RecommendationType.pause,
            monthlySaving: item.monthlyAmount,
          );
        }
        if (answer.need == ReviewNeed.unsure) {
          return SavingRecommendation(
            item: item,
            type: RecommendationType.reviewPlan,
            monthlySaving: 0,
          );
        }
        break;
    }
    return SavingRecommendation(
      item: item,
      type: RecommendationType.keep,
      monthlySaving: 0,
    );
  }
}

class MonthlyReviewStore {
  MonthlyReviewStore._();

  static final instance = MonthlyReviewStore._();
  static const storageKey = 'riyal.monthly_reviews.v1';

  final revision = ValueNotifier<int>(0);
  final Map<String, Map<String, dynamic>> _records = {};
  bool _initialized = false;

  bool get initialized => _initialized;

  static String periodFor(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}';

  String get currentPeriod => periodFor(DateTime.now());
  bool get isCurrentMonthComplete => _records.containsKey(currentPeriod);

  MonthlyReviewSnapshot? get currentSnapshot {
    final record = _records[currentPeriod];
    if (record == null) return null;
    try {
      final answerRows = record['answers'] as List;
      final answers = <MonthlyReviewAnswer>[];
      for (final raw in answerRows.whereType<Map>()) {
        final row = Map<String, dynamic>.from(raw);
        final item = MonthlyReviewItem(
          id: row['id'] as String,
          name: row['name'] as String,
          domain: ReviewDomain.values.byName(row['domain'] as String),
          monthlyAmount: (row['monthlyAmount'] as num).toDouble(),
          cycle: BillingCycle.values.byName(row['cycle'] as String),
        );
        answers.add(
          MonthlyReviewAnswer(
            item: item,
            activity: ReviewActivity.values.byName(row['activity'] as String),
            need: ReviewNeed.values.byName(row['need'] as String),
            continueForYear: row['continueForYear'] as bool,
          ),
        );
      }
      final byId = {for (final answer in answers) answer.item.id: answer.item};
      final recommendations = <SavingRecommendation>[];
      final recommendationRows = record['recommendations'] as List;
      for (final raw in recommendationRows.whereType<Map>()) {
        final row = Map<String, dynamic>.from(raw);
        final item = byId[row['itemId']];
        if (item == null) continue;
        recommendations.add(
          SavingRecommendation(
            item: item,
            type: RecommendationType.values.byName(row['type'] as String),
            monthlySaving: (row['monthlySaving'] as num).toDouble(),
          ),
        );
      }
      return MonthlyReviewSnapshot(
        completedAt: DateTime.parse(record['completedAt'] as String),
        answers: answers,
        recommendations: recommendations,
      );
    } catch (error) {
      debugPrint('Monthly review record is invalid: $error');
      return null;
    }
  }

  /// Drops the previous account's check-ins and loads the active account's.
  Future<void> switchAccount() {
    _records.clear();
    _initialized = false;
    return initialize();
  }

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      final raw = await SharedPreferencesAsync().getString(
        await DeviceIdStore.instance.scoped(storageKey),
      );
      if (raw != null) {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          for (final entry in decoded.entries) {
            if (entry.value is Map) {
              _records[entry.key] = Map<String, dynamic>.from(
                entry.value as Map,
              );
            }
          }
        }
      }
    } catch (error) {
      debugPrint('Monthly review load failed: $error');
    }
    _initialized = true;
    revision.value++;
  }

  Future<void> complete({
    required List<MonthlyReviewAnswer> answers,
    required List<SavingRecommendation> recommendations,
  }) async {
    final now = DateTime.now();
    _records[periodFor(now)] = {
      'completedAt': now.toIso8601String(),
      'answers': answers.map((answer) => answer.toJson()).toList(),
      'recommendations': [
        for (final recommendation in recommendations)
          {
            'itemId': recommendation.item.id,
            'type': recommendation.type.name,
            'monthlySaving': recommendation.monthlySaving,
          },
      ],
    };
    revision.value++;
    try {
      await SharedPreferencesAsync().setString(
        await DeviceIdStore.instance.scoped(storageKey),
        jsonEncode(_records),
      );
    } catch (error) {
      debugPrint('Monthly review save failed: $error');
    }
  }
}
