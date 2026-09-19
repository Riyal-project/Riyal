import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'device_id_store.dart';
import 'item_status.dart';
import 'subscription.dart' show BillingCycle;
import 'tracked_category.dart';

/// A recurring cost being tracked — a utility bill or a person's pay,
/// mirroring [Subscription]'s shape so the Utilities/People pages can reuse
/// the same UI as the Subscriptions page.
class TrackedItem {
  const TrackedItem({
    required this.id,
    required this.name,
    required this.amount,
    required this.cycle,
    required this.nextBillingDate,
    required this.category,
    this.logoAsset,
    this.icon,
    this.iconColor,
    this.status = ItemStatus.active,
    this.notes,
    this.pausedUntil,
    this.notificationsEnabled = true,
  });

  final String id;
  final String name;
  final String? logoAsset;
  final IconData? icon;
  final Color? iconColor;
  final double amount;
  final BillingCycle cycle;
  final DateTime nextBillingDate;
  final TrackedCategory category;
  final ItemStatus status;

  /// Free-text notes — surfaced on the People details page; harmless
  /// and simply unused for Utilities, which don't render it.
  final String? notes;

  /// When set (and still in the future), this person's allowance/pay is
  /// paused until this date — the People details page's pause
  /// scheduling control reads and writes this.
  final DateTime? pausedUntil;
  final bool notificationsEnabled;

  int get renewsInDays => nextBillingDate.difference(DateTime.now()).inDays;

  double get monthlyAmount =>
      cycle == BillingCycle.monthly ? amount : amount / 12;

  TrackedItem copyWith({
    double? amount,
    BillingCycle? cycle,
    DateTime? nextBillingDate,
    TrackedCategory? category,
    ItemStatus? status,
    String? notes,
    bool clearNotes = false,
    DateTime? pausedUntil,
    bool clearPausedUntil = false,
    bool? notificationsEnabled,
  }) => TrackedItem(
    id: id,
    name: name,
    logoAsset: logoAsset,
    icon: icon,
    iconColor: iconColor,
    amount: amount ?? this.amount,
    cycle: cycle ?? this.cycle,
    nextBillingDate: nextBillingDate ?? this.nextBillingDate,
    category: category ?? this.category,
    status: status ?? this.status,
    notes: clearNotes ? null : (notes ?? this.notes),
    pausedUntil: clearPausedUntil ? null : (pausedUntil ?? this.pausedUntil),
    notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
  );
}

/// Holds the list of tracked items for one domain (Utilities, People, ...).
class TrackedItemsStore {
  /// With a [storageKey], the cards are saved per account whenever they
  /// change and brought back by [restore]. [categories] and [icons] let a
  /// saved card find its (const) category and icon again.
  TrackedItemsStore(
    List<TrackedItem> seed, {
    this.storageKey,
    this.categories = const [],
    this.icons,
  }) : items = ValueNotifier(seed) {
    if (storageKey != null) items.addListener(_persist);
  }

  final ValueNotifier<List<TrackedItem>> items;
  final String? storageKey;
  final List<TrackedCategory> categories;
  final Iterable<IconData> Function()? icons;
  bool _silent = false;
  Future<void> _writes = Future.value();

  /// Swaps the cards without saving — for in-memory resets.
  void replaceSilently(List<TrackedItem> next) {
    _silent = true;
    items.value = next;
    _silent = false;
  }

  /// Waits (briefly) for pending saves, so switching account can't lose an
  /// edit — and a stuck save can never block signing in.
  Future<void> flush() => _writes.timeout(
    const Duration(seconds: 2),
    onTimeout: () => _writes = Future.value(),
  );

  /// Loads the active account's saved cards (none, the first time).
  Future<void> restore() async {
    List<TrackedItem>? saved;
    try {
      final key = await DeviceIdStore.instance.scoped(storageKey!);
      final raw = await SharedPreferencesAsync().getString(key);
      if (raw != null) saved = _decode(raw);
    } catch (error) {
      debugPrint('Tracked items load failed: $error');
    }
    replaceSilently(saved ?? <TrackedItem>[]);
  }

  void _persist() {
    final id = DeviceIdStore.instance.cachedId;
    if (_silent || storageKey == null || id == null) return;
    final json = _encode(items.value);
    _writes = _writes.then((_) async {
      try {
        await SharedPreferencesAsync().setString('$storageKey.$id', json);
      } catch (error) {
        debugPrint('Tracked items save failed: $error');
      }
    });
  }

  String _encode(List<TrackedItem> list) => jsonEncode([
    for (final i in list)
      {
        'id': i.id,
        'name': i.name,
        'logoAsset': i.logoAsset,
        'icon': i.icon?.codePoint,
        'iconColor': i.iconColor?.toARGB32(),
        'amount': i.amount,
        'cycle': i.cycle.name,
        'next': i.nextBillingDate.toIso8601String(),
        'category': i.category.key,
        'status': i.status.name,
        'notes': i.notes,
        'pausedUntil': i.pausedUntil?.toIso8601String(),
        'notifications': i.notificationsEnabled,
      },
  ]);

  List<TrackedItem> _decode(String raw) {
    final known = icons?.call().toList() ?? const <IconData>[];
    return [
      for (final row in (jsonDecode(raw) as List).cast<Map<String, dynamic>>())
        TrackedItem(
          id: row['id'] as String,
          name: row['name'] as String,
          logoAsset: row['logoAsset'] as String?,
          icon: [
            for (final icon in known)
              if (icon.codePoint == row['icon']) icon,
          ].firstOrNull,
          iconColor: row['iconColor'] == null
              ? null
              : Color(row['iconColor'] as int),
          amount: (row['amount'] as num).toDouble(),
          cycle: BillingCycle.values.byName(row['cycle'] as String),
          nextBillingDate: DateTime.parse(row['next'] as String),
          category: categories.firstWhere(
            (c) => c.key == row['category'],
            orElse: () => categories.firstWhere(
              (c) => c.key == 'other',
              orElse: () => categories.first,
            ),
          ),
          status: ItemStatus.values.byName(row['status'] as String),
          notes: row['notes'] as String?,
          pausedUntil: row['pausedUntil'] == null
              ? null
              : DateTime.parse(row['pausedUntil'] as String),
          notificationsEnabled: row['notifications'] as bool? ?? true,
        ),
    ];
  }

  void add(TrackedItem item) {
    items.value = [...items.value, item];
  }

  void update(TrackedItem item) {
    items.value = [
      for (final existing in items.value)
        if (existing.id == item.id) item else existing,
    ];
  }

  void remove(String id) {
    items.value = items.value.where((item) => item.id != id).toList();
  }
}
