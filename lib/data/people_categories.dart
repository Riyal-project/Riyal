import 'package:flutter/material.dart';

import 'tracked_category.dart';

class PeopleCategories {
  PeopleCategories._();

  static const household = TrackedCategory(
    'household',
    Icons.cleaning_services_outlined,
  );
  static const childcare = TrackedCategory(
    'childcare',
    Icons.child_care_outlined,
  );
  static const driving = TrackedCategory(
    'driving',
    Icons.directions_car_outlined,
  );
  static const security = TrackedCategory('security', Icons.shield_outlined);
  static const allowance = TrackedCategory(
    'allowance',
    Icons.savings_outlined,
  );
  static const other = TrackedCategory('other', Icons.more_horiz_rounded);

  /// Placeholder role for a person auto-added from a recurring bank
  /// payment with no catalog match — the payee name and payment history
  /// are known, but their actual role (driver, nanny, ...) isn't, so it's
  /// left for the user to fill in from the item's details page instead of
  /// guessed.
  static const unassigned = TrackedCategory(
    'unassigned',
    Icons.help_outline_rounded,
  );

  static const values = [
    household,
    childcare,
    driving,
    security,
    allowance,
    other,
    unassigned,
  ];
}
