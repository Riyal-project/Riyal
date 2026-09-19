import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'id_generator.dart';
import 'people_categories.dart';
import 'subscription.dart' show BillingCycle;
import 'tracked_item.dart';

class PeopleStore {
  PeopleStore._();

  static final TrackedItemsStore instance = TrackedItemsStore(_seed());

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
