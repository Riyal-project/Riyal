import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'demo_mode.dart';
import 'id_generator.dart';
import 'people_catalog.dart';
import 'people_categories.dart';
import 'subscription.dart' show BillingCycle;
import 'tracked_item.dart';

class PeopleStore {
  PeopleStore._();

  static final TrackedItemsStore instance = TrackedItemsStore(
    DemoMode.enabled ? _seed() : <TrackedItem>[],
    storageKey: 'riyal.people_items.v1',
    categories: PeopleCategories.values,
    icons: () => [
      for (final entry in peopleCatalog)
        if (entry.icon != null) entry.icon!,
      for (final category in PeopleCategories.values) category.icon,
      for (final item in _seed())
        if (item.icon != null) item.icon!,
    ],
  );

  /// In-memory reset (nothing is saved): the demo data, or nothing.
  static void reset() =>
      instance.replaceSilently(DemoMode.enabled ? _seed() : <TrackedItem>[]);

  /// Loads the active account's saved people; the very first time, the demo
  /// data for the demo login and nothing for a new sign-up.
  static Future<void> restore() =>
      instance.restore(DemoMode.enabled ? _seed() : <TrackedItem>[]);

  static List<TrackedItem> _seed() {
    final now = DateTime.now();
    return [
      TrackedItem(
        id: IdGenerator.uuidV4(),
        name: 'Driver',
        icon: Icons.directions_car_outlined,
        iconColor: AppColors.peopleDriving,
        amount: 2200,
        cycle: BillingCycle.monthly,
        nextBillingDate: now.add(const Duration(days: 10)),
        category: PeopleCategories.driving,
      ),
      TrackedItem(
        id: IdGenerator.uuidV4(),
        name: 'Housekeeper',
        icon: Icons.cleaning_services_outlined,
        iconColor: AppColors.peopleHousekeeping,
        amount: 1800,
        cycle: BillingCycle.monthly,
        nextBillingDate: now.add(const Duration(days: 18)),
        category: PeopleCategories.household,
      ),
      TrackedItem(
        id: IdGenerator.uuidV4(),
        name: 'Nanny',
        icon: Icons.child_care_outlined,
        iconColor: AppColors.peopleChildcare,
        amount: 3000,
        cycle: BillingCycle.monthly,
        nextBillingDate: now.add(const Duration(days: 22)),
        category: PeopleCategories.childcare,
      ),
    ];
  }
}
