import 'people_catalog.dart';
import 'people_categories.dart';
import 'tracked_item.dart';

class PeopleStore {
  PeopleStore._();

  /// Starts empty: cards only come from the user, or from recurring
  /// payments detected in a connected bank's real transactions.
  static final TrackedItemsStore instance = TrackedItemsStore(
    <TrackedItem>[],
    storageKey: 'riyal.people_items.v1',
    categories: PeopleCategories.values,
    icons: () => [
      for (final entry in peopleCatalog)
        if (entry.icon != null) entry.icon!,
      for (final category in PeopleCategories.values) category.icon,
    ],
  );

  /// In-memory reset (nothing is saved).
  static void reset() => instance.replaceSilently(<TrackedItem>[]);

  /// Loads the active account's saved people.
  static Future<void> restore() => instance.restore();
}
