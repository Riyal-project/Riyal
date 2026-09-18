import 'package:flutter/material.dart';

import '../data/monthly_review.dart';
import '../data/notifications_store.dart';
import '../l10n/app_locale.dart';
import '../services/gemini_api.dart';
import '../services/riyal_bot_config.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../widgets/coin_back_button.dart';
import '../widgets/logo_image.dart';

class MonthlyReviewScreen extends StatefulWidget {
  const MonthlyReviewScreen({super.key});

  @override
  State<MonthlyReviewScreen> createState() => _MonthlyReviewScreenState();
}

class _AnswerDraft {
  ReviewActivity? activity;
  ReviewNeed? need;
  bool? continueForYear;
}

class _MonthlyReviewScreenState extends State<MonthlyReviewScreen> {
  late final List<MonthlyReviewItem> _items;
  late final List<_AnswerDraft> _drafts;
  int _index = 0;
  bool _saving = false;
  List<SavingRecommendation>? _recommendations;
  GeminiApi? _api;
  bool _askingAi = false;
  String? _aiSummary;
  String? _aiError;

  bool get _arabic => AppLocale.locale.value.languageCode == 'ar';
  String t(String ar, String en) => _arabic ? ar : en;

  @override
  void initState() {
    super.initState();
    _items = MonthlyReviewItem.currentItems();
    _drafts = List.generate(_items.length, (_) => _AnswerDraft());
    _recommendations =
        MonthlyReviewStore.instance.currentSnapshot?.recommendations;
    try {
      _api = RiyalBotConfig.isConfigured ? RiyalBotConfig.create() : null;
    } catch (_) {
      _api = null;
    }
  }

  @override
  void dispose() {
    _api?.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    final draft = _drafts[_index];
    if (draft.activity == null ||
        draft.need == null ||
        draft.continueForYear == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            t(
              'اختر إجابة لكل سؤال قبل المتابعة.',
              'Answer each question before continuing.',
            ),
          ),
        ),
      );
      return;
    }
    if (_index < _items.length - 1) {
      setState(() => _index++);
      return;
    }

    setState(() => _saving = true);
    final answers = [
      for (var i = 0; i < _items.length; i++)
        MonthlyReviewAnswer(
          item: _items[i],
          activity: _drafts[i].activity!,
          need: _drafts[i].need!,
          continueForYear: _drafts[i].continueForYear!,
        ),
    ];
    final recommendations = MonthlyReviewEngine.evaluate(answers);
    await MonthlyReviewStore.instance.complete(
      answers: answers,
      recommendations: recommendations,
    );
    NotificationsStore.instance.refresh();
    if (!mounted) return;
    setState(() {
      _recommendations = recommendations;
      _saving = false;
    });
  }

  Future<void> _askAi() async {
    if (_api == null || _recommendations == null || _askingAi) return;
    final actionable = _recommendations!
        .where((r) => r.type != RecommendationType.keep)
        .map(
          (r) =>
              '${r.item.name}: ${r.type.name}; monthly amount SAR ${r.item.monthlyAmount.toStringAsFixed(2)}; calculated removable monthly cost SAR ${r.monthlySaving.toStringAsFixed(2)}',
        )
        .join('\n');
    setState(() {
      _askingAi = true;
      _aiError = null;
    });
    try {
      final response = await _api!.sendMessage('''
The user explicitly asked Riyal to explain these deterministic monthly-review results.
Reply in ${_arabic ? 'Arabic' : 'English'} using at most 120 words. Use only the supplied amounts. Do not invent annual-plan prices or claim that anything was cancelled. Give a short prioritized action plan.

Results:
${actionable.isEmpty ? 'No action recommended; current commitments appear suitable from the answers.' : actionable}
''');
      if (mounted) setState(() => _aiSummary = response);
    } on GeminiApiException catch (error) {
      if (mounted) setState(() => _aiError = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _aiError = t(
            'تعذر الحصول على شرح ريال الآن.',
            'Riyal could not explain the results right now.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _askingAi = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      backgroundColor: AppColors.background,
      leading: const CoinBackButton(),
      title: Text(t('المراجعة الشهرية', 'Monthly review')),
    ),
    body: SafeArea(
      top: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: _items.isEmpty
              ? _EmptyReview(arabic: _arabic)
              : _recommendations == null
              ? _buildSurvey()
              : _buildResults(),
        ),
      ),
    ),
  );

  Widget _buildSurvey() {
    final item = _items[_index];
    final draft = _drafts[_index];
    final progress = (_index + 1) / _items.length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                t(
                  'مراجعة سريعة تساعدك على اكتشاف فرص التوفير.',
                  'A quick check-in to uncover saving opportunities.',
                ),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Text(
              t(
                '${_index + 1} من ${_items.length}',
                '${_index + 1} of ${_items.length}',
              ),
              style: const TextStyle(color: AppColors.gold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: AppColors.trackBackground,
            color: AppColors.gold,
          ),
        ),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  LogoImage(
                    assetPath: item.logoAsset,
                    icon: item.icon ?? _domainIcon(item.domain),
                    iconColor: item.iconColor,
                    size: 56,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 21,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '⃁${item.monthlyAmount.toStringAsFixed(0)} / ${t('شهر', 'month')}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              _Question(
                title: _activityQuestion(item.domain),
                child: _ChoiceWrap<ReviewActivity>(
                  value: draft.activity,
                  values: ReviewActivity.values,
                  label: (value) => _activityLabel(item.domain, value),
                  onChanged: (value) => setState(() => draft.activity = value),
                ),
              ),
              const SizedBox(height: 24),
              _Question(
                title: _needQuestion(item.domain),
                child: _ChoiceWrap<ReviewNeed>(
                  value: draft.need,
                  values: ReviewNeed.values,
                  label: (value) => _needLabel(item.domain, value),
                  onChanged: (value) => setState(() => draft.need = value),
                ),
              ),
              const SizedBox(height: 24),
              _Question(
                title: _continueQuestion(item.domain),
                child: _ChoiceWrap<bool>(
                  value: draft.continueForYear,
                  values: const [true, false],
                  label: (value) => value ? t('نعم', 'Yes') : t('لا', 'No'),
                  onChanged: (value) =>
                      setState(() => draft.continueForYear = value),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            if (_index > 0)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _saving ? null : () => setState(() => _index--),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: Text(t('السابق', 'Back')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.cardBorder),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            if (_index > 0) const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: _saving ? null : _next,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.background,
                        ),
                      )
                    : Icon(
                        _index == _items.length - 1
                            ? Icons.auto_awesome_rounded
                            : Icons.arrow_forward_rounded,
                      ),
                label: Text(
                  _index == _items.length - 1
                      ? t('اعرض اقتراحاتي', 'Show my suggestions')
                      : t('التالي', 'Next'),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.background,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildResults() {
    final recommendations = _recommendations!;
    final actionable = recommendations
        .where((r) => r.type != RecommendationType.keep)
        .toList();
    final monthlySaving = recommendations.fold<double>(
      0,
      (sum, recommendation) => sum + recommendation.monthlySaving,
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.savings_outlined,
                color: AppColors.gold,
                size: 42,
              ),
              const SizedBox(height: 12),
              Text(
                t('اكتملت مراجعتك', 'Your review is complete'),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                t('فرص التوفير المحتملة', 'Potential saving opportunities'),
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              Text.rich(
                TextSpan(
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                  ),
                  children: [
                    TextSpan(
                      text: '⃁${monthlySaving.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontFamily: AppTypography.amountFontFamily,
                      ),
                    ),
                    TextSpan(text: ' / ${t('شهر', 'month')}'),
                  ],
                ),
              ),
              Text.rich(
                TextSpan(
                  style: const TextStyle(color: AppColors.textSecondary),
                  children: [
                    TextSpan(
                      text: '⃁${(monthlySaving * 12).toStringAsFixed(0)}',
                      style: TextStyle(
                        fontFamily: AppTypography.amountFontFamily,
                      ),
                    ),
                    TextSpan(text: ' / ${t('سنة', 'year')}'),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Text(
          t('اقتراحات ريال', 'Riyal suggestions'),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        if (actionable.isEmpty)
          _InfoCard(
            icon: Icons.check_circle_outline,
            title: t(
              'التزاماتك مناسبة حاليًا',
              'Your commitments look suitable',
            ),
            body: t(
              'لم نجد فرصة واضحة للتوفير من إجابات هذا الشهر.',
              'We found no clear saving opportunity from this month’s answers.',
            ),
          )
        else
          for (final recommendation in actionable) ...[
            _RecommendationCard(
              recommendation: recommendation,
              arabic: _arabic,
            ),
            const SizedBox(height: 12),
          ],
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome, color: AppColors.gold),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      t('شرح من ريال', 'Explanation from Riyal'),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                t(
                  'اضغط لإرسال ملخص هذه المراجعة إلى Gemini وصياغة خطة مختصرة. لن تُرسل كلمات مرور أو بيانات بنكية.',
                  'Send this review summary to Gemini for a short action plan. Passwords and bank details are never included.',
                ),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              if (_aiSummary != null) ...[
                const SizedBox(height: 14),
                SelectableText(
                  _aiSummary!,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    height: 1.6,
                  ),
                ),
              ],
              if (_aiError != null) ...[
                const SizedBox(height: 10),
                Text(
                  _aiError!,
                  style: const TextStyle(color: AppColors.errorText),
                ),
              ],
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: _api == null || _askingAi ? null : _askAi,
                icon: _askingAi
                    ? const SizedBox(
                        width: 17,
                        height: 17,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.background,
                        ),
                      )
                    : const Icon(Icons.auto_awesome_rounded),
                label: Text(
                  _api == null
                      ? t('ريال غير متصل', 'Riyal is not connected')
                      : t('اشرح اقتراحاتي', 'Explain my suggestions'),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.background,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          t(
            'هذه اقتراحات تقديرية. لم يتم إلغاء أو تعديل أي دفعة تلقائيًا.',
            'These are estimates. No payment was cancelled or changed automatically.',
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }

  IconData _domainIcon(ReviewDomain domain) => switch (domain) {
    ReviewDomain.subscription => Icons.subscriptions_outlined,
    ReviewDomain.utility => Icons.bolt_outlined,
    ReviewDomain.people => Icons.groups_outlined,
  };

  String _activityQuestion(ReviewDomain domain) => switch (domain) {
    ReviewDomain.subscription => t(
      'كم تستخدم هذا الاشتراك أسبوعيًا؟',
      'How often do you use this each week?',
    ),
    ReviewDomain.utility => t(
      'كيف تغيرت تكلفة هذه الخدمة هذا الشهر؟',
      'How did this service cost change this month?',
    ),
    ReviewDomain.people => t(
      'كم كان هذا الالتزام فعالًا هذا الشهر؟',
      'How active was this commitment this month?',
    ),
  };

  String _activityLabel(ReviewDomain domain, ReviewActivity value) {
    if (domain == ReviewDomain.utility) {
      return switch (value) {
        ReviewActivity.none => t('أقل', 'Lower'),
        ReviewActivity.low => t('مثل السابق', 'About the same'),
        ReviewActivity.medium => t('أعلى قليلًا', 'Slightly higher'),
        ReviewActivity.high => t('أعلى بكثير', 'Much higher'),
      };
    }
    if (domain == ReviewDomain.people) {
      return switch (value) {
        ReviewActivity.none => t('غير فعال', 'Not active'),
        ReviewActivity.low => t('أحيانًا', 'Occasionally'),
        ReviewActivity.medium => t('معظم الأيام', 'Most days'),
        ReviewActivity.high => t('يوميًا', 'Daily'),
      };
    }
    return switch (value) {
      ReviewActivity.none => t('ولا مرة', 'Never'),
      ReviewActivity.low => t('1–2 يوم', '1–2 days'),
      ReviewActivity.medium => t('3–4 أيام', '3–4 days'),
      ReviewActivity.high => t('5+ أيام', '5+ days'),
    };
  }

  String _needQuestion(ReviewDomain domain) => switch (domain) {
    ReviewDomain.subscription => t(
      'هل ما زلت تحتاج هذا الاشتراك؟',
      'Do you still need this subscription?',
    ),
    ReviewDomain.utility => t(
      'ما وضع هذه الخدمة الآن؟',
      'What is the status of this service?',
    ),
    ReviewDomain.people => t(
      'ما قرارك المبدئي لهذا الالتزام؟',
      'What is your current intention for this commitment?',
    ),
  };

  String _needLabel(ReviewDomain domain, ReviewNeed value) {
    if (domain == ReviewDomain.utility) {
      return switch (value) {
        ReviewNeed.keep => t('أساسية', 'Essential'),
        ReviewNeed.unsure => t('مراجعة الباقة', 'Review plan'),
        ReviewNeed.stop => t('لم تعد فعالة', 'No longer active'),
      };
    }
    if (domain == ReviewDomain.people) {
      return switch (value) {
        ReviewNeed.keep => t('استمرار', 'Continue'),
        ReviewNeed.unsure => t('إيقاف مؤقت', 'Pause'),
        ReviewNeed.stop => t('إنهاء', 'End'),
      };
    }
    return switch (value) {
      ReviewNeed.keep => t('نعم', 'Yes'),
      ReviewNeed.unsure => t('غير متأكد', 'Not sure'),
      ReviewNeed.stop => t('لا', 'No'),
    };
  }

  String _continueQuestion(ReviewDomain domain) => switch (domain) {
    ReviewDomain.subscription => t(
      'هل تتوقع الاستمرار عليه 12 شهرًا؟',
      'Do you expect to keep it for 12 months?',
    ),
    ReviewDomain.utility => t(
      'هل تتوقع استمرار الخدمة للسنة القادمة؟',
      'Do you expect to keep the service next year?',
    ),
    ReviewDomain.people => t(
      'هل تتوقع استمرار الالتزام 12 شهرًا؟',
      'Do you expect this commitment to continue for 12 months?',
    ),
  };
}

class _Question extends StatelessWidget {
  const _Question({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 12),
      child,
    ],
  );
}

class _ChoiceWrap<T> extends StatelessWidget {
  const _ChoiceWrap({
    required this.value,
    required this.values,
    required this.label,
    required this.onChanged,
  });

  final T? value;
  final List<T> values;
  final String Function(T) label;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final option in values)
        ChoiceChip(
          label: Text(label(option)),
          selected: value == option,
          selectedColor: AppColors.gold,
          backgroundColor: AppColors.trackBackground,
          side: const BorderSide(color: AppColors.cardBorder),
          labelStyle: TextStyle(
            color: value == option
                ? AppColors.background
                : AppColors.textSecondary,
          ),
          onSelected: (_) => onChanged(option),
        ),
    ],
  );
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({
    required this.recommendation,
    required this.arabic,
  });

  final SavingRecommendation recommendation;
  final bool arabic;
  String t(String ar, String en) => arabic ? ar : en;

  @override
  Widget build(BuildContext context) {
    final type = recommendation.type;
    final title = switch (type) {
      RecommendationType.cancel => t('راجع الإلغاء', 'Review cancellation'),
      RecommendationType.pause => t(
        'فكر في الإيقاف المؤقت',
        'Consider pausing',
      ),
      RecommendationType.annualPlan => t(
        'افحص الخطة السنوية',
        'Check the annual plan',
      ),
      RecommendationType.reviewPlan => t(
        'راجع السعر أو الباقة',
        'Review the price or plan',
      ),
      RecommendationType.keep => t('قيمة مناسبة', 'Good value'),
    };
    final body = switch (type) {
      RecommendationType.cancel => t(
        'إجاباتك تشير إلى أن ${recommendation.item.name} لم يعد مستخدمًا أو مطلوبًا. إلغاؤه قد يوفر ⃁${recommendation.monthlySaving.toStringAsFixed(0)} شهريًا.',
        'Your answers suggest ${recommendation.item.name} is no longer used or needed. Cancelling could save ⃁${recommendation.monthlySaving.toStringAsFixed(0)} monthly.',
      ),
      RecommendationType.pause => t(
        'قد يكون إيقاف ${recommendation.item.name} مؤقتًا مناسبًا. التوفير المحتمل أثناء الإيقاف ⃁${recommendation.monthlySaving.toStringAsFixed(0)} شهريًا.',
        'Pausing ${recommendation.item.name} may fit your current needs and could save ⃁${recommendation.monthlySaving.toStringAsFixed(0)} per paused month.',
      ),
      RecommendationType.annualPlan => t(
        'استخدامك مستمر وتتوقع البقاء سنة. قارن السعر السنوي مع ⃁${(recommendation.item.monthlyAmount * 12).toStringAsFixed(0)}، وهي تكلفة 12 دفعة شهرية.',
        'Your use is consistent and you expect to stay for a year. Compare the annual price with ⃁${(recommendation.item.monthlyAmount * 12).toStringAsFixed(0)}, the cost of 12 monthly payments.',
      ),
      RecommendationType.reviewPlan => t(
        'إجاباتك تستحق مراجعة الباقة أو البدائل قبل موعد الدفع القادم.',
        'Your answers suggest reviewing the plan or alternatives before the next payment.',
      ),
      RecommendationType.keep => '',
    };
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            type == RecommendationType.annualPlan
                ? Icons.calendar_month_outlined
                : type == RecommendationType.reviewPlan
                ? Icons.manage_search_rounded
                : Icons.savings_outlined,
            color: AppColors.gold,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  body,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.body,
  });
  final IconData icon;
  final String title;
  final String body;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: AppColors.cardBorder),
    ),
    child: Row(
      children: [
        Icon(icon, color: AppColors.gold),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                body,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _EmptyReview extends StatelessWidget {
  const _EmptyReview({required this.arabic});
  final bool arabic;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        arabic
            ? 'أضف اشتراكًا أو التزامًا ماليًا أولًا لبدء المراجعة.'
            : 'Add a subscription or payment commitment to start a review.',
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.textSecondary),
      ),
    ),
  );
}
