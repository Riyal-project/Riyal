import 'tracked_item.dart';
import 'utility_catalog.dart';
import 'utility_categories.dart';

class UtilitiesStore {
  UtilitiesStore._();

  /// Starts empty: cards only come from the user, or from recurring
  /// payments detected in a connected bank's real transactions.
  static final TrackedItemsStore instance = TrackedItemsStore(
    <TrackedItem>[],
    storageKey: 'riyal.utilities_items.v1',
    categories: UtilityCategories.values,
    icons: () => [
      for (final entry in utilityCatalog)
        if (entry.icon != null) entry.icon!,
      for (final category in UtilityCategories.values) category.icon,
    ],
  );

  /// In-memory reset (nothing is saved).
  static void reset() => instance.replaceSilently(<TrackedItem>[]);

  /// Loads the active account's saved utilities.
  static Future<void> restore() => instance.restore();
}
