import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'item_status.dart';
import 'people_store.dart';
import 'subscriptions_store.dart';
import 'utilities_store.dart';

enum BudgetDomain { subscriptions, utilities, people }

enum BudgetLevel { normal, near, exceeded }

extension BudgetDomainKey on BudgetDomain {
  String get categoryKey => switch (this) {
    BudgetDomain.subscriptions => 'Subscriptions',
    BudgetDomain.utilities => 'Utilities',
    BudgetDomain.people => 'People',
  };
  static BudgetDomain fromCategory(String key) =>
      BudgetDomain.values.firstWhere((domain) => domain.categoryKey == key);
}

class BudgetSnapshot {
  const BudgetSnapshot({required this.limit, required this.committed});
  final double limit;
  final double committed;
  double get fraction =>
      limit == 0 ? (committed > 0 ? 1 : 0) : committed / limit;
  BudgetLevel get level => fraction >= 1 && (limit > 0 || committed > 0)
      ? BudgetLevel.exceeded
      : fraction >= 0.8
      ? BudgetLevel.near
      : BudgetLevel.normal;
}

class BudgetAlert {
  const BudgetAlert({
    required this.id,
    required this.domain,
    required this.level,
    required this.committed,
    required this.limit,
    required this.createdAt,
  });
  final String id;
  final BudgetDomain domain;
  final BudgetLevel level;
  final double committed;
  final double limit;
  final DateTime createdAt;
  Map<String, dynamic> toJson() => {
    'id': id,
    'domain': domain.name,
    'level': level.name,
    'committed': committed,
    'limit': limit,
    'createdAt': createdAt.toIso8601String(),
  };
  factory BudgetAlert.fromJson(Map<String, dynamic> json) => BudgetAlert(
    id: json['id'] as String,
    domain: BudgetDomain.values.byName(json['domain'] as String),
    level: BudgetLevel.values.byName(json['level'] as String),
    committed: (json['committed'] as num).toDouble(),
    limit: (json['limit'] as num).toDouble(),
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}

/// Budgets follow the account email used by the app's current login flow.
/// Monthly usage is the current active recurring commitments, not bank debits.
class BudgetStore {
  BudgetStore._() {
    SubscriptionsStore.instance.subscriptions.addListener(recalculate);
    UtilitiesStore.instance.items.addListener(recalculate);
    PeopleStore.instance.items.addListener(recalculate);
  }
  static final instance = BudgetStore._();
  final revision = ValueNotifier<int>(0);
  SharedPreferencesAsync get _prefs => SharedPreferencesAsync();
  String? _account;
  Map<BudgetDomain, double> _limits = {};
  List<BudgetAlert> _alerts = [];
  Future<void> _pendingWrite = Future.value();
  bool get configured => _limits.length == BudgetDomain.values.length;
  String? get account => _account;
  List<BudgetAlert> get alerts => List.unmodifiable(_alerts);
  double? limitFor(BudgetDomain domain) => _limits[domain];
  String _profileKey(String account) =>
      'riyal.budgets.v1.${base64Url.encode(utf8.encode(account))}';

  Future<void> load() async {
    final account = await _prefs.getString('riyal.budgets.active');
    await activate(account ?? 'device');
  }

  Future<void> activate(String account) async {
    await _pendingWrite;
    final normalized = account.trim().toLowerCase();
    final raw = await _prefs.getString(_profileKey(normalized));
    final data = raw == null
        ? <String, dynamic>{}
        : jsonDecode(raw) as Map<String, dynamic>;
    final storedLimits = data['limits'] as Map<String, dynamic>? ?? {};
    final limits = <BudgetDomain, double>{};
    for (final domain in BudgetDomain.values) {
      final value = storedLimits[domain.name];
      if (value is num && value.isFinite && value >= 0) {
        limits[domain] = value.toDouble();
      }
    }
    await _prefs.setString('riyal.budgets.active', normalized);
    _account = normalized;
    _limits = limits;
    _alerts = (data['alerts'] as List<dynamic>? ?? [])
        .map((row) => BudgetAlert.fromJson(row as Map<String, dynamic>))
        .toList();
    recalculate();
  }

  BudgetSnapshot snapshot([BudgetDomain? domain]) {
    bool active(ItemStatus status) =>
        status == ItemStatus.active || status == ItemStatus.trial;
    double total(BudgetDomain domain) => switch (domain) {
      BudgetDomain.subscriptions =>
        SubscriptionsStore.instance.subscriptions.value
            .where((item) => active(item.status))
            .fold(0.0, (sum, item) => sum + item.monthlyAmount),
      BudgetDomain.utilities =>
        UtilitiesStore.instance.items.value
            .where((item) => active(item.status))
            .fold(0.0, (sum, item) => sum + item.monthlyAmount),
      BudgetDomain.people =>
        PeopleStore.instance.items.value
            .where(
              (item) =>
                  active(item.status) &&
                  !(item.pausedUntil?.isAfter(DateTime.now()) ?? false),
            )
            .fold(0.0, (sum, item) => sum + item.monthlyAmount),
    };
    final domains = domain == null ? BudgetDomain.values : [domain];
    return BudgetSnapshot(
      limit: domains.fold(0.0, (sum, domain) => sum + (_limits[domain] ?? 0)),
      committed: domains.fold(0.0, (sum, domain) => sum + total(domain)),
    );
  }

  String _encode(Map<BudgetDomain, double> limits, List<BudgetAlert> alerts) =>
      jsonEncode({
        'limits': {
          for (final entry in limits.entries) entry.key.name: entry.value,
        },
        'alerts': alerts.map((alert) => alert.toJson()).toList(),
      });

  Future<void> save(Map<BudgetDomain, double> limits) async {
    if (_account == null ||
        limits.length != BudgetDomain.values.length ||
        limits.values.any((value) => !value.isFinite || value < 0)) {
      throw ArgumentError(
        'Valid budgets for all domains and an account are required.',
      );
    }
    await _pendingWrite;
    await _prefs.setString(_profileKey(_account!), _encode(limits, _alerts));
    _limits = Map.of(limits);
    recalculate();
    await _pendingWrite;
  }

  void recalculate({DateTime? at}) {
    if (configured) {
      final now = at ?? DateTime.now();
      final period = '${now.year}-${now.month}';
      var changed = false;
      for (final domain in BudgetDomain.values) {
        final current = snapshot(domain);
        if (current.level == BudgetLevel.normal) continue;
        final id =
            'budget:${base64Url.encode(utf8.encode(_account!))}:$period:${domain.name}:${current.level.name}:${current.limit}';
        if (_alerts.any((alert) => alert.id == id)) continue;
        _alerts.add(
          BudgetAlert(
            id: id,
            domain: domain,
            level: current.level,
            committed: current.committed,
            limit: current.limit,
            createdAt: now,
          ),
        );
        changed = true;
      }
      if (changed) {
        final key = _profileKey(_account!);
        final encoded = _encode(_limits, _alerts);
        _pendingWrite = _pendingWrite
            .then((_) => _prefs.setString(key, encoded))
            .catchError((Object error) {
              debugPrint('Budget alert save failed: $error');
            });
      }
    }
    revision.value++;
  }
}
