import 'package:flutter/material.dart';

import 'tracked_category.dart';

class SubscriptionCategories {
  SubscriptionCategories._();

  static const entertainment = TrackedCategory(
    'entertainment',
    Icons.movie_outlined,
  );
  static const ai = TrackedCategory('ai', Icons.smart_toy_outlined);
  static const productivity = TrackedCategory(
    'productivity',
    Icons.work_outline_rounded,
  );
  static const cloudStorage = TrackedCategory(
    'cloud_storage',
    Icons.cloud_outlined,
  );
  static const fitnessWellness = TrackedCategory(
    'fitness_wellness',
    Icons.fitness_center_rounded,
  );
  static const education = TrackedCategory('education', Icons.school_outlined);
  static const shoppingDelivery = TrackedCategory(
    'shopping_delivery',
    Icons.local_shipping_outlined,
  );
  static const other = TrackedCategory('other', Icons.more_horiz_rounded);
  static const freeTrial = TrackedCategory(
    'free_trial',
    Icons.hourglass_top_rounded,
  );
  static const filterValues = [...values, freeTrial];

  static const values = [
    entertainment,
    ai,
    productivity,
    cloudStorage,
    fitnessWellness,
    education,
    shoppingDelivery,
    other,
  ];
}
