import 'demo_mode.dart';
import 'id_generator.dart';
import 'subscription.dart' show BillingCycle;
import 'tracked_item.dart';
import 'utility_catalog.dart';
import 'utility_categories.dart';

class UtilitiesStore {
  UtilitiesStore._();

  static final TrackedItemsStore instance = TrackedItemsStore(
    DemoMode.enabled ? _seed() : <TrackedItem>[],
    storageKey: 'riyal.utilities_items.v1',
    categories: UtilityCategories.values,
    icons: () => [
      for (final entry in utilityCatalog)
        if (entry.icon != null) entry.icon!,
      for (final category in UtilityCategories.values) category.icon,
    ],
  );

  /// In-memory reset (nothing is saved): the demo data, or nothing.
  static void reset() =>
      instance.replaceSilently(DemoMode.enabled ? _seed() : <TrackedItem>[]);

  /// Loads the active account's saved utilities; the very first time, the
  /// demo data for the demo login and nothing for a new sign-up.
  static Future<void> restore() =>
      instance.restore(DemoMode.enabled ? _seed() : <TrackedItem>[]);

  static List<TrackedItem> _seed() {
    final now = DateTime.now();
    return [
      TrackedItem(
        id: IdGenerator.uuidV4(),
        name: 'Saudi Electricity Company',
        logoAsset:
            'lib/assets/logos/1696007538-89-saudi-electricity-company.jpg',
        amount: 1189,
        cycle: BillingCycle.monthly,
        nextBillingDate: now.add(const Duration(days: 5)),
        category: UtilityCategories.electricity,
      ),
      TrackedItem(
        id: IdGenerator.uuidV4(),
        name: 'STC',
        logoAsset: 'lib/assets/logos/stc.jpeg',
        amount: 250,
        cycle: BillingCycle.monthly,
        nextBillingDate: now.add(const Duration(days: 15)),
        category: UtilityCategories.internet,
      ),
      TrackedItem(
        id: IdGenerator.uuidV4(),
        name: 'National Water Company',
        logoAsset: 'lib/assets/logos/saudi water comp.png',
        amount: 234,
        cycle: BillingCycle.monthly,
        nextBillingDate: now.add(const Duration(days: 20)),
        category: UtilityCategories.water,
      ),
      TrackedItem(
        id: IdGenerator.uuidV4(),
        name: 'Zain',
        logoAsset: 'lib/assets/logos/zain.png',
        amount: 150,
        cycle: BillingCycle.monthly,
        nextBillingDate: now.add(const Duration(days: 25)),
        category: UtilityCategories.mobile,
      ),
    ];
  }
}
