import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:riyal/data/budget_store.dart';
import 'package:riyal/data/notifications_store.dart';
import 'package:riyal/data/people_categories.dart';
import 'package:riyal/data/people_store.dart';
import 'package:riyal/data/profile_store.dart';
import 'package:riyal/data/subscription.dart';
import 'package:riyal/data/subscription_category.dart';
import 'package:riyal/data/tracked_item.dart';
import 'package:riyal/data/subscriptions_store.dart';
import 'package:riyal/data/utilities_store.dart';
import 'package:riyal/data/utility_categories.dart';
import 'package:riyal/services/gemini_api.dart';
import 'package:riyal/services/riyal_bot_context.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    PeopleStore.reset();
    UtilitiesStore.reset();
  });

  test(
    'snapshot has profile, subscriptions, bills, people and budgets',
    () async {
      await ProfileStore.instance.save('Full name', 'Sara Alharbi');
      SubscriptionsStore.instance.subscriptions.value = [
        Subscription(
          id: '1',
          name: 'Netflix',
          logoAsset: 'lib/assets/logos/Netflix_icon.svg',
          amount: 45,
          cycle: BillingCycle.monthly,
          nextBillingDate: DateTime(2026, 9, 22),
          category: SubscriptionCategories.entertainment,
        ),
      ];
      final due = DateTime.now().add(const Duration(days: 5));
      UtilitiesStore.instance.add(
        TrackedItem(
          id: 'u1',
          name: 'Saudi Electricity Company',
          amount: 1189,
          cycle: BillingCycle.monthly,
          nextBillingDate: due,
          category: UtilityCategories.electricity,
        ),
      );
      PeopleStore.instance.add(
        TrackedItem(
          id: 'p1',
          name: 'Nanny',
          amount: 3000,
          cycle: BillingCycle.monthly,
          nextBillingDate: due,
          category: PeopleCategories.childcare,
        ),
      );
      await BudgetStore.instance.activate('bot-context@test.com');
      await BudgetStore.instance.save({
        for (final d in BudgetDomain.values) d: 5000,
      });

      final text = await buildRiyalBotContext(now: DateTime(2026, 9, 19));

      expect(text, contains('Full name: Sara Alharbi'));
      expect(
        text,
        contains(
          'Netflix | 45.00 SAR monthly | next payment 2026-09-22 (in 3 days)',
        ),
      );
      expect(text, contains('Saudi Electricity Company | 1189.00 SAR monthly'));
      expect(text, contains('Nanny | 3000.00 SAR monthly'));
      expect(text, contains('People: limit 5000.00, committed 3000.00'));
      expect(text, contains('Connected banks: none'));
    },
  );

  test('an account with nothing added has empty lists', () async {
    PeopleStore.reset();
    UtilitiesStore.reset();
    SubscriptionsStore.instance.subscriptions.value = [];
    NotificationsStore.instance.reset();
    final text = await buildRiyalBotContext();
    expect(text, contains('Subscriptions (0):\n- none'));
    expect(text, isNot(contains('Nanny')));
  });

  test('context is added to the system instruction, not the history', () async {
    final systems = <String>[];
    final client = MockClient((request) async {
      final body = jsonDecode(request.body) as Map;
      systems.add(
        ((body['systemInstruction'] as Map)['parts'] as List).first['text']
            as String,
      );
      return http.Response(
        jsonEncode({
          'candidates': [
            {
              'finishReason': 'STOP',
              'content': {
                'parts': [
                  {'text': 'ok'},
                ],
              },
            },
          ],
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    var n = 0;
    final api = GeminiApi(
      apiKey: 'k',
      model: 'm',
      systemInstruction: 'BASE',
      contextProvider: () async {
        n++;
        if (n == 2) throw StateError('store unavailable');
        return 'USER DATA #$n';
      },
      client: client,
    );
    await api.sendMessage('hi');
    await api.sendMessage('again');
    expect(systems, ['BASE\n\nUSER DATA #1', 'BASE']);
    expect(api.history.map((m) => m.text), ['hi', 'ok', 'again', 'ok']);
  });
}
