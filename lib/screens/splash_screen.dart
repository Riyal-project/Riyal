import 'package:flutter/material.dart';

import '../data/account_session.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../l10n/strings.dart';
import '../widgets/hero_tags.dart';
import 'main_shell.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  /// Reopening a saved login runs while the splash animation plays.
  late final Future<bool> _signedIn;

  @override
  void initState() {
    super.initState();
    _signedIn = _restoreSession();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..forward();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) _continueFromSplash();
    });
  }

  Future<bool> _restoreSession() async {
    try {
      return await AccountSession.instance.restore();
    } catch (error) {
      debugPrint('Restoring the saved session failed: $error');
      return false;
    }
  }

  Future<void> _continueFromSplash() async {
    await Future.delayed(const Duration(milliseconds: 350));
    final signedIn = await _signedIn;
    if (!mounted) return;
    // Someone already logged in goes straight to the app. Everyone else
    // always sees onboarding (including the language-choice screen) on every
    // launch, regardless of AppSettings.onboardingCompleted.
    final Widget next = signedIn ? const MainShell() : const OnboardingScreen();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 550),
        pageBuilder: (_, _, _) => next,
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final t = _controller.value;

              final coinFade = Interval(
                0,
                0.18,
                curve: Curves.easeOut,
              ).transform(t.clamp(0, 1));
              final coinScale = Interval(
                0,
                0.32,
                curve: Curves.easeOutBack,
              ).transform(t.clamp(0, 1));
              final coinSettle = Interval(
                0,
                0.42,
                curve: Curves.easeOutCubic,
              ).transform(t.clamp(0, 1));
              final tiltAngle = (1 - coinSettle) * -0.5;

              final titleT = Interval(
                0.5,
                0.72,
                curve: Curves.easeOut,
              ).transform(t.clamp(0, 1));
              final taglineT = Interval(
                0.68,
                0.9,
                curve: Curves.easeOut,
              ).transform(t.clamp(0, 1));

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Opacity(
                    opacity: coinFade,
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.0025)
                        ..rotateY(tiltAngle),
                      child: Transform.scale(
                        scale: coinScale,
                        child: Hero(
                          tag: heroAppCoinTag,
                          child: ColorFiltered(
                            // Fold a little of the app's deep-green base
                            // into the metallic artwork so the gold is less
                            // bright while its coin detail remains intact.
                            colorFilter: const ColorFilter.mode(
                              Color(0x33031108),
                              BlendMode.srcATop,
                            ),
                            child: Image.asset(
                              'assets/icon/coin_3d.webp',
                              width: 188,
                              height: 188,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Semantics(
                    label: 'RIYAL',
                    child: ExcludeSemantics(
                      // The wordmark is Latin: pin it to LTR so an RTL (Arabic)
                      // locale doesn't lay the letters out in reverse.
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        textDirection: TextDirection.ltr,
                        children: List.generate(5, (index) {
                          final letterT = Interval(
                            index * 0.12,
                            0.5 + index * 0.12,
                            curve: Curves.easeOutCubic,
                          ).transform(titleT);
                          return Opacity(
                            opacity: letterT,
                            child: Transform.translate(
                              offset: Offset(0, (1 - letterT) * 10),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 1.5,
                                ),
                                child: Text(
                                  'RIYAL'[index],
                                  style: AppTypography.wordmark(
                                    color: AppColors.goldLight,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Opacity(
                    opacity: taglineT,
                    child: Transform.translate(
                      offset: Offset(0, (1 - taglineT) * 10),
                      child: Text(
                        Strings.t('splash_tagline'),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
