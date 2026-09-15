import 'package:flutter/material.dart';
import '../widgets/coin_back_button.dart';

import '../data/subscription_catalog.dart';
import '../data/subscription_category.dart';
import '../data/tracked_category.dart';
import '../l10n/strings.dart';
import '../theme/app_theme.dart';
import '../widgets/category_filter_bar.dart';
import '../widgets/logo_image.dart';
import 'subscription_details_screen.dart';

class SelectAppScreen extends StatefulWidget {
  const SelectAppScreen({super.key, this.freeTrial = false});

  final bool freeTrial;

  @override
  State<SelectAppScreen> createState() => _SelectAppScreenState();
}

class _SelectAppScreenState extends State<SelectAppScreen> {
  String _query = '';
  TrackedCategory? _category;

  @override
  Widget build(BuildContext context) {
    final results = subscriptionCatalog
        .where((a) => a.name.toLowerCase().contains(_query.toLowerCase()))
        .where((a) => _category == null || a.category == _category)
        .toList();

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
                      Strings.t('choose_an_app'),
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
              const SizedBox(height: 12),
              TextField(
                onChanged: (v) => setState(() => _query = v),
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: Strings.t('search_apps'),
                  hintStyle: const TextStyle(color: AppColors.textSecondary),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.textSecondary,
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              CategoryFilterBar(
                categories: SubscriptionCategories.values,
                selected: _category,
                onChanged: (c) => setState(() => _category = c),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: results.isEmpty
                    ? Center(
                        child: Text(
                          Strings.t('no_apps_found'),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.only(bottom: 24),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 12,
                              childAspectRatio: 0.78,
                            ),
                        itemCount: results.length,
                        itemBuilder: (context, i) {
                          final app = results[i];
                          return GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => SubscriptionDetailsScreen(
                                    name: app.name,
                                    logoAsset: app.logoAsset,
                                    initialCategory: app.category,
                                    initialFreeTrial: widget.freeTrial,
                                  ),
                                ),
                              );
                            },
                            child: Column(
                              children: [
                                LogoImage(assetPath: app.logoAsset, size: 56),
                                const SizedBox(height: 8),
                                Text(
                                  app.name,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
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
