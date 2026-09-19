import 'demo_mode.dart';
import 'id_generator.dart';
import 'subscription.dart' show BillingCycle;
import 'tracked_item.dart';
import 'utility_categories.dart';

class UtilitiesStore {
  UtilitiesStore._();

  static final TrackedItemsStore instance = TrackedItemsStore(
    DemoMode.enabled ? _seed() : <TrackedItem>[],
  );

  /// Re-seeds the demo data, or empties it for a new sign-up, when the
  /// active account changes.
  static void reset() =>
      instance.items.value = DemoMode.enabled ? _seed() : <TrackedItem>[];

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
