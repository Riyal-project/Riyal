import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../l10n/strings.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import 'connect_bank_screen.dart';
import 'budget_setup_screen.dart';
import '../data/account_session.dart';
import '../data/budget_store.dart';
import '../data/profile_store.dart';
import '../widgets/riyal_coin_painter.dart';
import '../widgets/auth_coin_flip.dart';
import '../widgets/riyal_loader.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _signingUp = false;
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Real Supabase Auth (email/password) is wired up in AuthStore but not
  // called here for now — email confirmation was blocking testing. See
  // lib/data/auth_store.dart to re-enable it later.
  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _signingUp = true);
    try {
      await AccountSession.instance.signUp(
        _emailController.text,
        _passwordController.text,
      );
      await BudgetStore.instance.activate(_emailController.text);
      // The name/email typed here aren't tied to a real Supabase Auth user
      // (see the note above) — save them straight to ProfileStore so the
      // home screen greeting and Profile screen reflect what was entered.
      await ProfileStore.instance.save(
        'Full name',
        _fullNameController.text.trim(),
      );
      await ProfileStore.instance.save('Email', _emailController.text.trim());
      if (!mounted) return;
      // A brand-new account can't have a connected bank yet.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => const BudgetSetupScreen(
            afterSetup: ConnectBankScreen(forced: true),
          ),
        ),
        (_) => false,
      );
    } on AccountExistsException {
      _showMessage(Strings.t('account_exists_error'));
    } catch (error) {
      _showMessage(Strings.t('sign_up_generic_error'));
    } finally {
      if (mounted) setState(() => _signingUp = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.2),
            radius: 0.85,
            colors: [
              AppColors.cardBorder,
              AppColors.surface,
              AppColors.background,
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 28,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: math.max(0, constraints.maxHeight - 56),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'RIYAL',
                        style: AppTypography.wordmark(
                          color: AppColors.gold,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        Strings.t('brand_tagline'),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 300),
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: AuthCoinFlip(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.32,
                                      ),
                                      blurRadius: 20,
                                      offset: const Offset(0, 14),
                                    ),
                                  ],
                                ),
                                child: CustomPaint(
                                  painter: const RiyalCoinPainter(
                                    faceColor: AppColors.surface,
                                    dashCount: 40,
                                    dashWidthScale: 0.4,
                                    dashLengthScale: 0.55,
                                    dashOuterEndOffset: 0.3,
                                    outerRimWidthScale: 0.3,
                                    innerRingWidthScale: 0.32,
                                    innerRingInset: 3.2,
                                  ),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // Big, translucent riyal watermark
                                      // sitting behind the form, on the
                                      // coin's face.
                                      ExcludeSemantics(
                                        child: FractionallySizedBox(
                                          widthFactor: 0.57,
                                          heightFactor: 0.57,
                                          child: Opacity(
                                            opacity: 0.14,
                                            child: SvgPicture.asset(
                                              'assets/icons/saudi_riyal.svg',
                                              colorFilter:
                                                  const ColorFilter.mode(
                                                    AppColors.gold,
                                                    BlendMode.srcIn,
                                                  ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(34),
                                        child: FittedBox(
                                          fit: BoxFit.contain,
                                          child: SizedBox(
                                            width: 440,
                                            height: 600,
                                            child: Form(
                                              key: _formKey,
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    Strings.t('signup_heading'),
                                                    style:
                                                        AppTypography.wordmark(
                                                          fontSize: 36,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color: AppColors
                                                              .textPrimary,
                                                          height: 1.1,
                                                        ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    Strings.t(
                                                      'create_account_subtitle',
                                                    ),
                                                    style: const TextStyle(
                                                      color: AppColors
                                                          .textSecondary,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 18),
                                                  _field(
                                                    fieldKey: 'full_name',
                                                    icon: Icons
                                                        .person_outline_rounded,
                                                    autofillHints: const [
                                                      AutofillHints.name,
                                                    ],
                                                  ),
                                                  const SizedBox(height: 14),
                                                  _field(
                                                    fieldKey: 'email',
                                                    icon: Icons.email_outlined,
                                                    autofillHints: const [
                                                      AutofillHints.email,
                                                    ],
                                                  ),
                                                  const SizedBox(height: 14),
                                                  _field(
                                                    fieldKey: 'password',
                                                    icon: Icons
                                                        .lock_outline_rounded,
                                                    password: true,
                                                    autofillHints: const [
                                                      AutofillHints.newPassword,
                                                    ],
                                                  ),
                                                  const SizedBox(height: 14),
                                                  _field(
                                                    fieldKey:
                                                        'confirm_password',
                                                    icon: Icons
                                                        .lock_outline_rounded,
                                                    password: true,
                                                    autofillHints: const [
                                                      AutofillHints.newPassword,
                                                    ],
                                                  ),
                                                  const SizedBox(height: 16),
                                                  Container(
                                                    width: 290,
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            40,
                                                          ),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: AppColors
                                                              .goldDark
                                                              .withValues(
                                                                alpha: 0.28,
                                                              ),
                                                          blurRadius: 5,
                                                          offset: const Offset(
                                                            0,
                                                            3,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    child: FilledButton(
                                                      onPressed: _signingUp
                                                          ? null
                                                          : _signUp,
                                                      style: FilledButton.styleFrom(
                                                        backgroundColor:
                                                            AppColors.gold,
                                                        foregroundColor:
                                                            AppColors
                                                                .goldForeground,
                                                        minimumSize:
                                                            const Size.fromHeight(
                                                              50,
                                                            ),
                                                        shape:
                                                            const StadiumBorder(),
                                                      ),
                                                      child: _signingUp
                                                          ? const RiyalLoader(
                                                              size: 18,
                                                              color: AppColors
                                                                  .goldForeground,
                                                            )
                                                          : Text(
                                                              Strings.t(
                                                                'create_account_button',
                                                              ),
                                                              style: const TextStyle(
                                                                fontSize: 18,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                                letterSpacing:
                                                                    1.4,
                                                              ),
                                                            ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          Strings.t('have_account_signin'),
                          style: const TextStyle(color: AppColors.gold),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.shield_outlined,
                              size: 15,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 7),
                            Flexible(
                              child: Text(
                                Strings.t('finances_on_device'),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _field({
    required String fieldKey,
    required IconData icon,
    required List<String> autofillHints,
    bool password = false,
  }) {
    final hint = Strings.t(fieldKey);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              color: Colors.white.withValues(alpha: 0.14),
            ),
            child: TextFormField(
              controller: switch (fieldKey) {
                'full_name' => _fullNameController,
                'email' => _emailController,
                'password' => _passwordController,
                'confirm_password' => _confirmPasswordController,
                _ => null,
              },
              keyboardType: fieldKey == 'email'
                  ? TextInputType.emailAddress
                  : TextInputType.text,
              obscureText: password && _obscurePassword,
              autofillHints: autofillHints,
              autocorrect: false,
              enableSuggestions: !password,
              textInputAction: fieldKey == 'confirm_password'
                  ? TextInputAction.done
                  : TextInputAction.next,
              onFieldSubmitted: fieldKey == 'confirm_password'
                  ? (_) => _signUp()
                  : null,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return Strings.f('enter_your_field', hint.toLowerCase());
                }
                if (fieldKey == 'email' &&
                    !RegExp(
                      r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                    ).hasMatch(value.trim())) {
                  return Strings.t('valid_email_error');
                }
                if (fieldKey == 'password' && value.length < 8) {
                  return Strings.t('password_length_error');
                }
                if (fieldKey == 'confirm_password' &&
                    value != _passwordController.text) {
                  return Strings.t('passwords_no_match');
                }
                return null;
              },
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 28,
              ),
              cursorColor: AppColors.gold,
              decoration: InputDecoration(
                isDense: false,
                errorStyle: const TextStyle(fontSize: 13),
                hintText: hint,
                hintStyle: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 24,
                ),
                prefixIcon: Icon(
                  icon,
                  color: AppColors.textSecondary,
                  size: 30,
                ),
                suffixIcon: password
                    ? IconButton(
                        tooltip: _obscurePassword
                            ? Strings.t('show_password')
                            : Strings.t('hide_password'),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppColors.textSecondary,
                          size: 28,
                        ),
                      )
                    : null,
                filled: false,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 26,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.45),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: const BorderSide(color: AppColors.gold, width: 2),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
