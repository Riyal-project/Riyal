import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../data/budget_store.dart';
import '../widgets/budget_progress_card.dart';
import '../widgets/capsule_tab_selector.dart';
import '../data/analytics_data.dart';
import '../data/people_catalog.dart';
import '../data/subscription_catalog.dart';
import '../l10n/app_locale.dart';
import '../l10n/strings.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../widgets/coin_back_button.dart';
import '../widgets/logo_image.dart';

/// Full-page analytics, reached from Home ("See all" / the chevron on the
/// spending card). Just a thin Scaffold around [AnalyticsContent].
class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key, this.category});
  final String? category;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: const CoinBackButton(),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        title: Text(
          category == null
              ? Strings.t('analytics_general_title')
              : (AppLocale.locale.value.languageCode == 'ar'
                    ? 'تحليلات ${Strings.categoryDisplay(category!)}'
                    : '${Strings.categoryDisplay(category!)} analytics'),
        ),
      ),
      body: AnalyticsContent(category: category),
    );
  }
}

/// The analytics charts/cards themselves, with no Scaffold/AppBar of their
/// own — reused both by [AnalyticsScreen] (full page, from Home) and
/// embedded directly as the "Analytics" tab on the Subscriptions/Utilities/
/// People pages (so switching to it there doesn't leave the page — the
/// bottom nav and the Subscriptions/Analytics pill stay on screen).
class AnalyticsContent extends StatefulWidget {
  const AnalyticsContent({
    super.key,
    this.category,
    this.showCategoryPicker = true,
    this.horizontalPadding = 20,
    this.bottomPadding = 32,
  });

  final String? category;

  /// Whether to show the General/Subscriptions/Utilities/People chooser.
  /// Turned off when embedded in a page that's already scoped to one
  /// category — switching category there would be redundant with the
  /// page's own identity pill.
  final bool showCategoryPicker;

  /// Horizontal padding around the content. Defaults to 20 for the
  /// full-page [AnalyticsScreen]; pages that embed this directly (and
  /// already apply their own side padding) pass 0 so the cards use the
  /// full page width instead of being padded twice.
  final double horizontalPadding;

  /// Bottom padding, so the last card can scroll clear of whatever sits
  /// below. The full-page [AnalyticsScreen] has no floating nav bar so 32
  /// is plenty; pages that embed this directly under the floating bottom
  /// nav pass enough to clear it (matching their own list views), or the
  /// last card is permanently stuck half-hidden behind it.
  final double bottomPadding;

  @override
  State<AnalyticsContent> createState() => _AnalyticsContentState();
}

class _AnalyticsContentState extends State<AnalyticsContent> {
  late String? _category = widget.category;
  String _period = 'Month';
  final DateTime _today = DateTime.now();
  static const _palette = [
    AppColors.subscriptions,
    AppColors.utilities,
    AppColors.gold,
    AppColors.textSecondary,
    AppColors.goldDark,
  ];
  String _money(double amount) => '⃁${amount.toStringAsFixed(0)}';

  Widget _chip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.gold : AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? AppColors.gold : AppColors.cardBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? AppColors.goldForeground
                : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ar = AppLocale.locale.value.languageCode == 'ar';
    String periodDisplay(String p) => switch (p) {
      'Week' => Strings.t('period_week'),
      'Year' => Strings.t('period_year'),
      _ => Strings.t('period_month'),
    };
    String periodAdjDisplay(String p) => switch (p) {
      'Week' => Strings.t('period_adj_weekly'),
      'Year' => Strings.t('period_adj_yearly'),
      _ => Strings.t('period_adj_monthly'),
    };
    final items =
        analyticsItems
            .where((i) => _category == null || i.category == _category)
            .toList()
          ..sort((a, b) => a.days.compareTo(b.days));
    final factor = switch (_period) {
      'Week' => 7 / 30,
      'Year' => 12.0,
      _ => 1.0,
    };
    final total = items.fold(0.0, (sum, item) => sum + item.amount) * factor;
    final monthlyHistory = List.generate(
      6,
      (index) => analyticsHistory.entries
          .where((e) => _category == null || e.key == _category)
          .fold(0.0, (sum, e) => sum + e.value[index]),
    );
    // Illustrative weekly/yearly scenarios, not a live transaction aggregation.
    final history = _period == 'Month'
        ? monthlyHistory
        : (_period == 'Week'
                  ? [0.72, 0.85, 0.78, 0.94, 0.90, 1.0]
                  : [0.55, 0.64, 0.73, 0.81, 0.92, 1.0])
              .map((weight) => total * weight)
              .toList();
    final highest = items.reduce((a, b) => a.amount >= b.amount ? a : b);
    final highestNames = items
        .where((i) => i.amount == highest.amount)
        .map((i) => i.name)
        .join(' & ');
    final breakdown = <String, double>{};
    for (final item in items) {
      final key = _category == null ? item.category : item.group;
      breakdown[key] = (breakdown[key] ?? 0) + item.amount * factor;
    }
    final labels = List.generate(6, (i) {
      if (_period == 'Year') return '${_today.year - 5 + i}';
      if (_period == 'Week') {
        final date = _today.subtract(Duration(days: (5 - i) * 7));
        return '${date.day}/${date.month}';
      }
      return Strings.monthAbbrev(
        DateTime(_today.year, _today.month - 5 + i).month,
      );
    });
    final periodLabel = _period == 'Year'
        ? '${_today.year}'
        : _period == 'Week'
        ? '${Strings.t('week_ending')} ${_today.day} ${Strings.monthAbbrev(_today.month)} ${_today.year}'
        : '${Strings.monthAbbrev(_today.month)} ${_today.year}';
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        widget.horizontalPadding,
        0,
        widget.horizontalPadding,
        widget.bottomPadding,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                periodLabel,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 10),
              CapsuleTabSelector<String>(
                options: [
                  for (final period in ['Week', 'Month', 'Year'])
                    CapsuleTabOption(periodDisplay(period), period),
                ],
                selected: _period,
                onChanged: (p) => setState(() => _period = p),
              ),
              if (widget.showCategoryPicker) ...[
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final category in <String?>[
                      null,
                      'Subscriptions',
                      'Utilities',
                      'People',
                    ])
                      _chip(
                        label: category == null
                            ? Strings.t('general')
                            : Strings.categoryDisplay(category),
                        isSelected: _category == category,
                        onTap: () => setState(() => _category = category),
                      ),
                  ],
                ),
              ],
              if (_period != 'Month') ...[
                const SizedBox(height: 8),
                Text(
                  Strings.t('illustrative_estimates'),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 22),
              BudgetProgressCard(
                domain: _category == null
                    ? null
                    : BudgetDomainKey.fromCategory(_category!),
              ),
              const SizedBox(height: 16),
              _card(
                Strings.t('spend_over_time'),
                Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        ar
                            ? 'الإنفاق ${periodAdjDisplay(_period)} · ريال'
                            : '${periodAdjDisplay(_period)} spend · ⃁',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 190,
                      width: double.infinity,
                      child: CustomPaint(painter: _TrendPainter(history)),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: labels
                          .map(
                            (m) => Expanded(
                              child: Text(
                                m,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.fade,
                                softWrap: false,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _card(
                _category == null
                    ? Strings.t('category_split')
                    : Strings.t('spending_breakdown'),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final chart = SizedBox(
                      width: 160,
                      height: 160,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _SplitPainter(
                                breakdown.values.toList(),
                                _palette,
                              ),
                            ),
                          ),
                          const Text(
                            '100%',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    );
                    final legend = Column(
                      children: [
                        for (var i = 0; i < breakdown.length; i++)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            child: Row(
                              children: [
                                Container(
                                  width: 9,
                                  height: 9,
                                  decoration: BoxDecoration(
                                    color: _palette[i % _palette.length],
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _category == null
                                        ? Strings.categoryDisplay(
                                            breakdown.keys.elementAt(i),
                                          )
                                        : Strings.groupDisplay(
                                            breakdown.keys.elementAt(i),
                                          ),
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${(breakdown.values.elementAt(i) / total * 100).toStringAsFixed(1)}%  ·  ${_money(breakdown.values.elementAt(i))}',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    );
                    return constraints.maxWidth > 580
                        ? Row(
                            children: [
                              chart,
                              const SizedBox(width: 32),
                              Expanded(child: legend),
                            ],
                          )
                        : Column(
                            children: [
                              chart,
                              const SizedBox(height: 16),
                              legend,
                            ],
                          );
                  },
                ),
              ),
              const SizedBox(height: 16),
              _card(
                items.where((i) => i.amount == highest.amount).length > 1
                    ? Strings.t('highest_cost_items_tied')
                    : Strings.t('highest_cost_item'),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      highestNames,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_money(highest.amount * factor)} / ${periodDisplay(_period)}'
                      '${items.where((i) => i.amount == highest.amount).length > 1 ? ' ${Strings.t('each')}' : ''}',
                      style: const TextStyle(color: AppColors.gold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _card(
                Strings.t('upcoming_renewals'),
                Column(
                  children: [
                    for (var i = 0; i < items.length; i++) ...[
                      if (i > 0)
                        const Divider(color: AppColors.cardBorder, height: 24),
                      _renewal(items[i]),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Matches a demo analytics item against the real subscription/people
  /// catalogs so recognizable items (Netflix, ChatGPT Plus, Housekeeper,
  /// ...) show their actual logo/icon instead of one generic icon per
  /// category. Generic item names with no specific brand behind them
  /// (e.g. "Electricity", "Fitness membership") fall through to the
  /// category icon below rather than being guessed at.
  ({String? logoAsset, IconData? icon, Color? iconColor})? _resolveItemVisual(
    AnalyticsItem item,
  ) {
    final name = item.name.toUpperCase();
    for (final app in subscriptionCatalog) {
      if (name == app.name.toUpperCase()) {
        return (logoAsset: app.logoAsset, icon: null, iconColor: null);
      }
    }
    for (final entry in peopleCatalog) {
      if (name.contains(entry.name.toUpperCase())) {
        return (
          logoAsset: entry.logoAsset,
          icon: entry.icon,
          iconColor: entry.iconColor,
        );
      }
    }
    return null;
  }

  Widget _renewal(AnalyticsItem item) {
    final date = DateTime(_today.year, _today.month, _today.day + item.days);
    final visual = _resolveItemVisual(item);
    return Row(
      children: [
        if (visual != null)
          LogoImage(
            assetPath: visual.logoAsset,
            icon: visual.icon,
            iconColor: visual.iconColor,
            size: 44,
          )
        else
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.trackBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              item.category == 'Subscriptions'
                  ? Icons.autorenew
                  : item.category == 'Utilities'
                  ? Icons.bolt_outlined
                  : Icons.person_outline,
              color: AppColors.gold,
            ),
          ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${date.day} ${Strings.monthAbbrev(date.month)} · ${Strings.inDays(item.days)}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          _money(item.amount),
          style: AppTypography.amount(
            color: AppColors.gold,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _card(String title, Widget content) => Container(
    width: double.infinity,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: AppColors.cardBorder),
    ),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 16),
          content,
        ],
      ),
    ),
  );
}

class _TrendPainter extends CustomPainter {
  _TrendPainter(this.values);
  final List<double> values;
  @override
  void paint(Canvas canvas, Size size) {
    final maxValue = (values.reduce(math.max) / 500).ceil() * 500.0;
    final height = size.height - 24;
    final width = size.width - 48;
    for (var i = 0; i <= 2; i++) {
      final y = 12 + height * i / 2;
      canvas.drawLine(
        Offset(42, y),
        Offset(size.width, y),
        Paint()
          ..color = AppColors.cardBorder
          ..strokeWidth = 0.6,
      );
      final label = TextPainter(
        text: TextSpan(
          text: (maxValue * (1 - i / 2)).toStringAsFixed(0),
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      label.paint(canvas, Offset(0, y - 6));
    }
    final points = List.generate(
      values.length,
      (i) => Offset(
        42 + width * i / (values.length - 1),
        12 + height * (1 - values[i] / maxValue),
      ),
    );
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    final area = Path.from(path)
      ..lineTo(points.last.dx, size.height - 12)
      ..lineTo(points.first.dx, size.height - 12)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.gold.withValues(alpha: 0.22),
            AppColors.gold.withValues(alpha: 0),
          ],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.gold
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeJoin = StrokeJoin.round,
    );
    for (final p in points) {
      canvas.drawCircle(p, 4, Paint()..color = AppColors.gold);
    }
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) => true;
}

class _SplitPainter extends CustomPainter {
  _SplitPainter(this.values, this.colors);
  final List<double> values;
  final List<Color> colors;
  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold(0.0, (a, b) => a + b);
    final rect = (Offset.zero & size).deflate(14);
    var start = -math.pi / 2;
    for (var i = 0; i < values.length; i++) {
      final sweep = values[i] / total * math.pi * 2;
      canvas.drawArc(
        rect,
        start + 0.015,
        sweep - 0.03,
        false,
        Paint()
          ..color = colors[i % colors.length]
          ..style = PaintingStyle.stroke
          ..strokeWidth = 20,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _SplitPainter oldDelegate) => true;
}
