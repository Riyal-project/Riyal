import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../data/user_bank_accounts_store.dart';
import '../l10n/strings.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import 'main_shell.dart';
import 'signup_screen.dart';
import '../data/budget_store.dart';
import '../widgets/riyal_coin_painter.dart';
import '../widgets/auth_coin_flip.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'danah@gmail.com');
  final _passwordController = TextEditingController(text: '123123123');
  bool _obscurePassword = true;
  bool _signingIn = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Real Supabase Auth (email/password) is wired up in AuthStore but not
  // called here for now — email confirmation was blocking testing. See
  // lib/data/auth_store.dart to re-enable it later.
  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _signingIn = true);
    try {
      await BudgetStore.instance.activate(_emailController.text);
      await UserBankAccountsStore.instance.load();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const MainShell()),
        (_) => false,
      );
    } catch (error) {
      _showMessage(Strings.t('sign_in_generic_error'));
    } finally {
      if (mounted) setState(() => _signingIn = false);
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
                                  painter: const RiyalCoinPainter(),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // Big, translucent riyal watermark
                                      // sitting behind the form, on the
                                      // coin's face.
                                      ExcludeSemantics(
                                        child: FractionallySizedBox(
                                          widthFactor: 0.6,
                                          heightFactor: 0.6,
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
                                                    Strings.t('login_heading'),
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
                                                      'signin_subtitle',
                                                    ),
                                                    style: const TextStyle(
                                                      color: AppColors
                                                          .textSecondary,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 18),
                                                  _field(
                                                    controller:
                                                        _emailController,
                                                    hint: Strings.t('email'),
                                                    icon: Icons.email_outlined,
                                                    autofillHints: const [
                                                      AutofillHints.email,
                                                    ],
                                                  ),
                                                  const SizedBox(height: 16),
                                                  _field(
                                                    controller:
                                                        _passwordController,
                                                    hint: Strings.t('password'),
                                                    icon: Icons
                                                        .lock_outline_rounded,
                                                    password: true,
                                                    autofillHints: const [
                                                      AutofillHints.password,
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
                                                      onPressed: _signingIn
                                                          ? null
                                                          : _signIn,
                                                      style: FilledButton.styleFrom(
                                                        backgroundColor:
                                                            AppColors.gold,
                                                        foregroundColor: AppColors
                                                            .goldForeground,
                                                        minimumSize:
                                                            const Size.fromHeight(
                                                              50,
                                                            ),
                                                        shape:
                                                            const StadiumBorder(),
                                                      ),
                                                      child: _signingIn
                                                          ? const SizedBox(
                                                              width: 18,
                                                              height: 18,
                                                              child:
                                                                  CircularProgressIndicator(
                                                                    strokeWidth:
                                                                        2,
                                                                    color: AppColors
                                                                        .goldForeground,
                                                                  ),
                                                            )
                                                          : Text(
                                                              Strings.t(
                                                                'sign_in_button',
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
                        onPressed: () {
                          FocusManager.instance.primaryFocus?.unfocus();
                          Navigator.of(
                            context,
                          ).push(authCoinRoute(const SignupScreen()));
                        },
                        child: Text(
                          Strings.t('no_account_signup'),
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
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required List<String> autofillHints,
    bool password = false,
  }) {
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
              controller: controller,
              keyboardType: password
                  ? TextInputType.text
                  : TextInputType.emailAddress,
              obscureText: password && _obscurePassword,
              autofillHints: autofillHints,
              autocorrect: false,
              enableSuggestions: !password,
              textInputAction: password
                  ? TextInputAction.done
                  : TextInputAction.next,
              onFieldSubmitted: password ? (_) => _signIn() : null,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return Strings.f('enter_your_field', hint.toLowerCase());
                }
                if (!password &&
                    !RegExp(
                      r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                    ).hasMatch(value.trim())) {
                  return Strings.t('valid_email_error');
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
                prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 30),
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
                  borderSide: const BorderSide(
                    color: AppColors.gold,
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
