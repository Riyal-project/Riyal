import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'catalog_entry.dart';
import 'people_categories.dart';

const List<CatalogEntry> peopleCatalog = [
  CatalogEntry(
    name: 'Driver',
    icon: Icons.directions_car_outlined,
    iconColor: AppColors.peopleDriving,
    category: PeopleCategories.driving,
  ),
  CatalogEntry(
    name: 'Housekeeper',
    icon: Icons.cleaning_services_outlined,
    iconColor: AppColors.peopleHousekeeping,
    category: PeopleCategories.household,
  ),
  CatalogEntry(
    name: 'Nanny',
    icon: Icons.child_care_outlined,
    iconColor: AppColors.peopleChildcare,
    category: PeopleCategories.childcare,
  ),
  CatalogEntry(
    name: 'Cook',
    icon: Icons.restaurant_outlined,
    iconColor: AppColors.peopleHousekeeping,
    category: PeopleCategories.household,
  ),
  CatalogEntry(
    name: 'Gardener',
    icon: Icons.grass_outlined,
    iconColor: AppColors.peopleGardening,
    category: PeopleCategories.household,
  ),
  CatalogEntry(
    name: 'Security Guard',
    icon: Icons.shield_outlined,
    iconColor: AppColors.peopleSecurity,
    category: PeopleCategories.security,
  ),
  CatalogEntry(
    name: 'Tutor',
    icon: Icons.school_outlined,
    iconColor: AppColors.peopleTutoring,
    category: PeopleCategories.other,
  ),
  CatalogEntry(
    name: 'Personal Assistant',
    icon: Icons.badge_outlined,
    iconColor: AppColors.peopleAssistant,
    category: PeopleCategories.other,
  ),
  CatalogEntry(
    name: "Children's Allowance",
    icon: Icons.child_friendly_outlined,
    iconColor: AppColors.peopleChildcare,
    category: PeopleCategories.childcare,
  ),
  CatalogEntry(
    name: 'Family Allowance',
    icon: Icons.family_restroom_outlined,
    iconColor: AppColors.peopleAssistant,
    category: PeopleCategories.other,
  ),
];
