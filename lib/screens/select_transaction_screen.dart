import 'package:flutter/material.dart';
import '../widgets/coin_back_button.dart';

import '../data/bank_transaction_matcher.dart';
import '../data/mock_transactions.dart';
import '../l10n/strings.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../widgets/logo_image.dart';
import '../widgets/riyal_loader.dart';
import 'subscription_details_screen.dart';

class SelectTransactionScreen extends StatelessWidget {
  const SelectTransactionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CoinBackButton(),
                  Expanded(
                    child: Text(
                      Strings.t('recent_transactions'),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 12, bottom: 12),
                child: Text(
                  Strings.t('tap_charge_to_track_subscription'),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
              Expanded(
                child: FutureBuilder<List<MockTransaction>>(
                  future: loadRecentSubscriptionTransactions(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: RiyalLoader());
                    }
                    final transactions = snapshot.data!;
                    return ListView.separated(
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: transactions.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final tx = transactions[i];
                        return GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => SubscriptionDetailsScreen(
                                  name: tx.matchedName ?? tx.merchant,
                                  logoAsset: tx.matchedLogo,
                                  initialAmount: tx.amount,
                                  initialCategory: tx.matchedCategory,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                LogoImage(assetPath: tx.matchedLogo, size: 44),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tx.matchedName ?? tx.merchant,
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${tx.merchant} · ${Strings.daysAgo(tx.daysAgo)}',
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '⃁${tx.amount.toStringAsFixed(0)}',
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
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
