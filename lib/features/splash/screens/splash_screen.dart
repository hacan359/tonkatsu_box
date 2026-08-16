import 'package:core/models/profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/database/database_service.dart';
import '../../../core/logging/startup_error.dart';
import '../../../features/settings/providers/profile_provider.dart';
import '../../../features/settings/providers/settings_provider.dart';
import '../../../features/welcome/screens/welcome_screen.dart';
import 'profile_picker_screen.dart';
import '../../../shared/constants/platform_features.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/navigation/app_shell.dart';
import '../../../shared/theme/app_assets.dart';
import '../../../shared/theme/app_durations.dart';

/// Navigation waits for both the animation and the pre-warmed DB open, so the
/// heavy init never overlaps the route transition and ANRs a weak device.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final CurvedAnimation _fadeCurve;
  late final CurvedAnimation _scaleCurve;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  bool _animationDone = false;

  bool _dbDone = false;

  bool _navigated = false;

  /// 1.5s animation + 0.5s hold.
  static const Duration _totalDuration = Duration(milliseconds: 2000);

  /// Animation fraction of total duration (1.5 / 2.0).
  static const double _animationEnd = 0.75;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: _totalDuration,
    );

    // Fade and scale run in the first 75% of the controller's time.
    _fadeCurve = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, _animationEnd, curve: Curves.easeIn),
    );
    _fadeAnimation = _fadeCurve;

    _scaleCurve = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, _animationEnd, curve: Curves.easeOutCubic),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(_scaleCurve);

    _controller.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed) {
        _animationDone = true;
        _tryNavigate();
      }
    });
    _controller.forward();

    final DatabaseService db = ref.read(databaseServiceProvider);
    db.warmUp().then((_) {
      _dbDone = true;
      _tryNavigate();
    }).catchError((Object error, StackTrace stack) {
      // A failed migration, or on web a server that did not answer. Without
      // this the future just rejects and the splash hangs forever.
      recordStartupError('database', error, stack);
    });
  }

  void _tryNavigate() {
    if (_animationDone && _dbDone && !_navigated && mounted) {
      _navigated = true;
      final SharedPreferences prefs = ref.read(sharedPreferencesProvider);
      final bool welcomeCompleted =
          prefs.getBool(kWelcomeCompletedKey) ?? false;
      if (!welcomeCompleted) {
        _navigateToWelcome();
        return;
      }

      final ProfilesData data = ref.read(profilesDataProvider);
      final bool skipPicker =
          prefs.getBool(kSkipProfilePickerKey) ?? false;
      final bool skipOnce =
          prefs.getBool(SettingsKeys.skipPickerOnce) ?? false;
      if (skipOnce) {
        prefs.remove(SettingsKeys.skipPickerOnce);
      }

      // Profiles are a native concept: the server hands out one database.
      if (!kIsWebBuild && data.profiles.length > 1 && !skipPicker && !skipOnce) {
        _navigateToProfilePicker();
      } else {
        _navigateToHome();
      }
    }
  }

  void _navigateToProfilePicker() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (
          BuildContext context,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
        ) {
          return const ProfilePickerScreen();
        },
        transitionsBuilder: (
          BuildContext context,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
          Widget child,
        ) {
          return FadeTransition(
            opacity: animation,
            child: _withBackdrop(child),
          );
        },
        transitionDuration: Duration(
          milliseconds: kIsMobile ? 200 : 500,
        ),
      ),
    );
  }

  void _navigateToHome() {
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (
          BuildContext context,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
        ) {
          return const AppShell();
        },
        transitionsBuilder: (
          BuildContext context,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
          Widget child,
        ) {
          return FadeTransition(
            opacity: animation,
            child: _withBackdrop(child),
          );
        },
        transitionDuration: Duration(milliseconds: kIsMobile ? 200 : 500),
      ),
    );
  }


  /// PageRouteBuilder skips PageTransitionsTheme, so on web the route paints
  /// the tiled backdrop itself — the browser's page root is white; native isn't.
  Widget _withBackdrop(Widget child) {
    if (!kIsWebBuild) return child;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.background,
        image: AppColors.tileImage,
      ),
      child: child,
    );
  }

  void _navigateToWelcome() {
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (
          BuildContext context,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
        ) {
          return const WelcomeScreen();
        },
        transitionsBuilder: (
          BuildContext context,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
          Widget child,
        ) {
          return FadeTransition(
            opacity: animation,
            child: _withBackdrop(child),
          );
        },
        transitionDuration: AppDurations.slower,
      ),
    );
  }

  @override
  void dispose() {
    _fadeCurve.dispose();
    _scaleCurve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Image.asset(
              AppAssets.logo,
              width: 200,
              height: 200,
            ),
          ),
        ),
      ),
    );
  }
}
