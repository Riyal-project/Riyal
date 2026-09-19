import 'package:flutter/material.dart';

import '../data/mock_bank.dart';
import '../data/mock_bank_connection_service.dart';
import '../data/mock_banks_store.dart';
import '../data/user_bank_accounts_store.dart';
import '../l10n/strings.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../widgets/coin_back_button.dart';
import '../widgets/logo_image.dart';
import '../widgets/riyal_loader.dart';
import 'main_shell.dart';

enum _ConnectStep { chooseBank, bankLogin, connecting, success }

/// The mock "connect a bank" flow — a grid → bank login → loading →
/// success sequence backed entirely by local mock data (see
/// lib/data/mock_bank_connection_service.dart).
///
/// When [forced] is true (the new-user gate right after sign-up),
/// the user can connect now or skip and add a bank
/// manually later. Either path replaces the stack with [MainShell].
class ConnectBankScreen extends StatefulWidget {
  const ConnectBankScreen({super.key, this.forced = false});

  final bool forced;

  @override
  State<ConnectBankScreen> createState() => _ConnectBankScreenState();
}

class _ConnectBankScreenState extends State<ConnectBankScreen> {
  _ConnectStep _step = _ConnectStep.chooseBank;
  MockBank? _selectedBank;
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _connectFailed = false;

  bool get _hasCredentials =>
      _idController.text.trim().isNotEmpty &&
      _passwordController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _idController.addListener(_credentialsChanged);
    _passwordController.addListener(_credentialsChanged);
  }

  void _credentialsChanged() => setState(() {});

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _selectBank(MockBank bank) {
    _idController.clear();
    _passwordController.clear();
    setState(() {
      _selectedBank = bank;
      _step = _ConnectStep.bankLogin;
      _connectFailed = false;
    });
  }

  void _backToChooseBank() {
    setState(() {
      _step = _ConnectStep.chooseBank;
      _selectedBank = null;
    });
  }

  Future<void> _submitLogin() async {
    final bank = _selectedBank;
    if (bank == null || !_hasCredentials || _step != _ConnectStep.bankLogin) {
      return;
    }
    setState(() => _step = _ConnectStep.connecting);
    try {
      // A fake delay so the loading state reads as a real connection
      // attempt rather than an instant no-op.
      await Future.delayed(const Duration(milliseconds: 1400));
      await MockBankConnectionService.instance.connect(bank);
      await UserBankAccountsStore.instance.load();
      if (!mounted) return;
      setState(() => _step = _ConnectStep.success);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _step = _ConnectStep.bankLogin;
        _connectFailed = true;
      });
    }
  }

  void _finish() {
    if (widget.forced) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const MainShell()),
        (_) => false,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  void _skipForNow() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const MainShell()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final canPopFreely = !widget.forced && _step == _ConnectStep.chooseBank;
    return PopScope(
      canPop: canPopFreely,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_step != _ConnectStep.chooseBank &&
            _step != _ConnectStep.connecting) {
          _backToChooseBank();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            child: switch (_step) {
              _ConnectStep.chooseBank => _ChooseBankStep(
                key: const ValueKey('chooseBank'),
                forced: widget.forced,
                onBack: canPopFreely ? () => Navigator.of(context).pop() : null,
                onSelectBank: _selectBank,
                onSkip: widget.forced ? _skipForNow : null,
              ),
              _ConnectStep.bankLogin => _BankLoginStep(
                key: const ValueKey('bankLogin'),
                bank: _selectedBank!,
                idController: _idController,
                passwordController: _passwordController,
                obscurePassword: _obscurePassword,
                showError: _connectFailed,
                onToggleObscure: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                onBack: _backToChooseBank,
                onSubmit: _hasCredentials ? _submitLogin : null,
              ),
              _ConnectStep.connecting => _ConnectingStep(
                key: const ValueKey('connecting'),
                bank: _selectedBank!,
              ),
              _ConnectStep.success => _SuccessStep(
                key: const ValueKey('success'),
                bank: _selectedBank!,
                forced: widget.forced,
                onFinish: _finish,
              ),
            },
          ),
        ),
      ),
    );
  }
}

/// The bank's real logo when it has one (see mock_banks.logo_asset_path),
/// falling back to a colored initials circle otherwise.
class _BankBadge extends StatelessWidget {
  const _BankBadge({required this.bank, this.size = 56});

  final MockBank bank;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (bank.logoAssetPath != null) {
      return LogoImage(
        assetPath: bank.logoAssetPath,
        size: size,
        radius: size / 2,
      );
    }
    final initials = bank.name
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bank.primaryColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: bank.primaryColor.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.34,
        ),
      ),
    );
  }
}

class _ChooseBankStep extends StatelessWidget {
  const _ChooseBankStep({
    super.key,
    required this.forced,
    required this.onBack,
    required this.onSelectBank,
    required this.onSkip,
  });

  final bool forced;
  final VoidCallback? onBack;
  final ValueChanged<MockBank> onSelectBank;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (onBack != null)
                CoinBackButton(onPressed: onBack)
              else
                const SizedBox(width: 4),
              Expanded(
                child: Text(
                  Strings.t(
                    forced ? 'connect_bank_forced_title' : 'connect_bank_title',
                  ),
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
          if (forced) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Text(
                Strings.t('connect_bank_optional_subtitle'),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Text(
            Strings.t('choose_your_bank'),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: FutureBuilder<List<MockBank>>(
              future: MockBanksStore.instance.load(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: RiyalLoader());
                }
                final banks = snapshot.data!;
                return GridView.builder(
                  padding: const EdgeInsets.only(top: 4, bottom: 24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 1.15,
                  ),
                  itemCount: banks.length,
                  itemBuilder: (context, i) {
                    final bank = banks[i];
                    return GestureDetector(
                      onTap: () => onSelectBank(bank),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _BankBadge(bank: bank),
                            const SizedBox(height: 12),
                            Text(
                              bank.name,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 13,
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
          if (onSkip != null) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: onSkip,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.gold,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      Strings.t('skip_bank_now'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      Strings.t('skip_bank_manual_hint'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BankLoginStep extends StatelessWidget {
  const _BankLoginStep({
    super.key,
    required this.bank,
    required this.idController,
    required this.passwordController,
    required this.obscurePassword,
    required this.showError,
    required this.onToggleObscure,
    required this.onBack,
    required this.onSubmit,
  });

  final MockBank bank;
  final TextEditingController idController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool showError;
  final VoidCallback onToggleObscure;
  final VoidCallback onBack;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -0.3),
          radius: 1,
          colors: [
            bank.primaryColor.withValues(alpha: 0.35),
            AppColors.background,
          ],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [CoinBackButton(onPressed: onBack)]),
            const SizedBox(height: 24),
            Center(
              child: Column(
                children: [
                  _BankBadge(bank: bank, size: 72),
                  const SizedBox(height: 14),
                  Text(
                    bank.name,
                    style: AppTypography.wordmark(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            if (showError) ...[
              Text(
                Strings.t('bank_connect_failed'),
                style: const TextStyle(
                  color: AppColors.statusCancelled,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
            ],
            _field(
              hint: Strings.t('bank_login_username_hint'),
              icon: Icons.badge_outlined,
              controller: idController,
            ),
            const SizedBox(height: 12),
            _field(
              hint: Strings.t('password'),
              icon: Icons.lock_outline_rounded,
              controller: passwordController,
              obscure: obscurePassword,
              suffix: IconButton(
                onPressed: onToggleObscure,
                icon: Icon(
                  obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onSubmit,
                style: FilledButton.styleFrom(
                  backgroundColor: bank.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  Strings.t('bank_login_button'),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    bool obscure = false,
    Widget? suffix,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        isDense: true,
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.gold, width: 2),
        ),
      ),
    );
  }
}

class _ConnectingStep extends StatelessWidget {
  const _ConnectingStep({super.key, required this.bank});

  final MockBank bank;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RiyalLoader(color: bank.primaryColor),
          const SizedBox(height: 20),
          Text(
            Strings.f('connecting_to_bank', bank.name),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessStep extends StatelessWidget {
  const _SuccessStep({
    super.key,
    required this.bank,
    required this.forced,
    required this.onFinish,
  });

  final MockBank bank;
  final bool forced;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.statusActive.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.check_rounded,
                color: AppColors.statusActive,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              Strings.t('bank_connected_title'),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              Strings.f('bank_connected_body', bank.name),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onFinish,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.background,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  Strings.t(forced ? 'continue_button' : 'done_button'),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
