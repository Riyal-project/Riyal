import '../l10n/strings.dart';
import 'catalog_entry.dart';
import 'tracked_category.dart';
import 'tracked_item.dart';

/// Everything a page needs to reuse the generic Subscriptions-style UI for
/// a different domain (Utilities, People, ...): its catalog, categories,
/// and store.
class TrackedDomain {
  const TrackedDomain({
    required this.routeName,
    required this.nounKey,
    required this.analyticsCategoryKey,
    required this.catalog,
    required this.categories,
    required this.store,
  });

  /// Used to pop the add-flow back to this domain's root screen, and to
  /// look up this domain's search-hint translation.
  final String routeName;

  /// Stable English identifier (e.g. 'utility_bill') used to look up this
  /// domain's noun/title translations — never itself shown on screen.
  final String nounKey;

  /// English key matching [analyticsHistory] and each
  /// [AnalyticsItem.category] ('Utilities' / 'People') — used for lookups
  /// and equality, not for display.
  final String analyticsCategoryKey;

  final List<CatalogEntry> catalog;
  final List<TrackedCategory> categories;
  final TrackedItemsStore store;

  /// e.g. "Utilities" / "المرافق" — the tab/page title.
  String get displayTitle => Strings.t('nav_$routeName');

  /// e.g. "utility bill" / "فاتورة مرافق" — used in empty-state copy.
  String get itemNounSingular => Strings.t('noun_singular_$nounKey');

  /// e.g. "utility bills" / "فواتير المرافق".
  String get itemNounPlural => Strings.t('noun_plural_$nounKey');

  /// e.g. "Choose a provider" / "اختر مزود الخدمة".
  String get addFromScratchTitle => Strings.t('add_from_scratch_$nounKey');

  /// e.g. "Search utilities" / "ابحث في المرافق".
  String get searchHint => Strings.t('search_hint_$routeName');
}
