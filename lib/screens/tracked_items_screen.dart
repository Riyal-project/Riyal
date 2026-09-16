import 'package:flutter/material.dart';

import '../data/item_status.dart';
import '../data/monthly_review.dart';
import '../data/people_domain.dart';
import '../data/tracked_domain.dart';
import '../data/tracked_item.dart';
import '../l10n/strings.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../widgets/capsule_tab_selector.dart';
import '../widgets/circle_icon_button.dart';
import '../widgets/inline_search_field.dart';
import '../widgets/item_filter_sheet.dart';
import '../widgets/logo_image.dart';
import 'add_tracked_item_sheet.dart';
import 'analytics_screen.dart';
import 'tracked_item_view_screen.dart';

enum _PageTab { items, analytics }

/// The Utilities/People tabs' content — same layout as the Subscriptions
/// page ([SubscriptionsBody]), driven by a [TrackedDomain] instead.
class TrackedItemsScreen extends StatefulWidget {
  const TrackedItemsScreen({super.key, required this.domain});

  final TrackedDomain domain;

  @override
  State<TrackedItemsScreen> createState() => _TrackedItemsScreenState();
}

class _TrackedItemsScreenState extends State<TrackedItemsScreen> {
  _PageTab _tab = _PageTab.items;
  ItemFilterState _filter = const ItemFilterState();
  bool _searching = false;
  String _query = '';

  void _stopSearching() => setState(() {
    _searching = false;
    _query = '';
  });

  ReviewDomain get _reviewDomain => identical(widget.domain, peopleDomain)
      ? ReviewDomain.people
      : ReviewDomain.utility;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_searching)
                  InlineSearchField(
                    autofocus: true,
                    hintText: widget.domain.searchHint,
                    onChanged: (v) => setState(() => _query = v),
                    onClose: _stopSearching,
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: CapsuleTabSelector<_PageTab>(
                          options: [
                            CapsuleTabOption(
                              widget.domain.displayTitle,
                              _PageTab.items,
                            ),
                            CapsuleTabOption(
                              Strings.t('analytics_tab'),
                              _PageTab.analytics,
                            ),
                          ],
                          selected: _tab,
                          onChanged: (t) => setState(() => _tab = t),
                        ),
                      ),
                      if (_tab == _PageTab.items) ...[
                        const SizedBox(width: 12),
                        CircleIconButton(
                          icon: Icons.search_rounded,
                          onTap: () => setState(() => _searching = true),
                        ),
                      ],
                    ],
                  ),
                if (_tab == _PageTab.items) ...[
                  const SizedBox(height: 16),
                  MultiCategoryChipsRow(
                    categories: widget.domain.categories,
                    state: _filter,
                    onChanged: (f) => setState(() => _filter = f),
                  ),
                ],
                const SizedBox(height: 16),
                Expanded(
                  child: _tab == _PageTab.items
                      ? _TrackedItemsList(
                          domain: widget.domain,
                          reviewDomain: _reviewDomain,
                          filter: _filter,
                          query: _query,
                        )
                      : AnalyticsContent(
                          category: widget.domain.analyticsCategoryKey,
                          showCategoryPicker: false,
                          horizontalPadding: 0,
                          bottomPadding: 120,
                        ),
                ),
              ],
            ),
          ),
          if (_tab == _PageTab.items)
            Positioned(
              right: 20,
              bottom: 130,
              child: CircleIconButton(
                icon: Icons.add_rounded,
                background: AppColors.gold,
                iconColor: AppColors.goldForeground,
                size: 44,
                onTap: () => showAddTrackedItemSheet(context, widget.domain),
              ),
            ),
        ],
      ),
    );
  }
}

class _TrackedItemsList extends StatelessWidget {
  const _TrackedItemsList({
    required this.domain,
    required this.reviewDomain,
    required this.filter,
    this.query = '',
  });

  final TrackedDomain domain;
  final ReviewDomain reviewDomain;
  final ItemFilterState filter;
  final String query;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<TrackedItem>>(
      valueListenable: domain.store.items,
      builder: (context, allItems, _) {
        var items = allItems.where((s) => filter.matches(s.category)).toList();
        if (!filter.showCancelled) {
          items = items.where((s) => s.status != ItemStatus.cancelled).toList();
        }
        if (query.trim().isNotEmpty) {
          items = items
              .where(
                (s) =>
                    s.name.toLowerCase().contains(query.trim().toLowerCase()),
              )
              .toList();
        }
        switch (filter.sortMode) {
          case ItemSortMode.newest:
            items = items.reversed.toList();
          case ItemSortMode.mostUsed:
          case ItemSortMode.leastUsed:
            final ranked = items
                .map((i) => (i, usageRank(reviewDomain, i.name)))
                .toList();
            ranked.sort((a, b) {
              if (a.$2 == null && b.$2 == null) return 0;
              if (a.$2 == null) return 1;
              if (b.$2 == null) return -1;
              return filter.sortMode == ItemSortMode.mostUsed
                  ? b.$2!.compareTo(a.$2!)
                  : a.$2!.compareTo(b.$2!);
            });
            items = ranked.map((r) => r.$1).toList();
          case null:
            break;
        }

        if (allItems.isEmpty) {
          return Center(
            child: Text(
              Strings.emptyDomainMessage(domain.itemNounPlural),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          );
        }
        if (items.isEmpty) {
          final categoryLabel = filter.categories.isEmpty
              ? null
              : filter.categories.map((c) => c.label).join(', ');
          return Center(
            child: Text(
              query.trim().isNotEmpty
                  ? Strings.noMatchMessage(domain.itemNounPlural, query)
                  : categoryLabel != null
                  ? Strings.noCategoryMessage(
                      categoryLabel,
                      domain.itemNounPlural,
                    )
                  : Strings.emptyDomainMessage(domain.itemNounPlural),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.only(bottom: 190),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, i) =>
              _TrackedItemTile(domain: domain, item: items[i]),
        );
      },
    );
  }
}

class _TrackedItemTile extends StatelessWidget {
  const _TrackedItemTile({required this.domain, required this.item});

  final TrackedDomain domain;
  final TrackedItem item;

  @override
  Widget build(BuildContext context) {
    final s = item;
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => TrackedItemViewScreen(domain: domain, itemId: s.id),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            LogoImage(
              assetPath: s.logoAsset,
              icon: s.icon,
              iconColor: s.iconColor,
              size: 44,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    Strings.renewsIn(s.renewsInDays),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '⃁${s.amount.toStringAsFixed(0)}',
              style: AppTypography.amount(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
