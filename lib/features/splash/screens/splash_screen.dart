// Анимированный splash screen с логотипом Tonkatsu Box.

import 'package:flutter/material.dart';

import '../../../shared/navigation/navigation_shell.dart';
import '../../../shared/theme/app_assets.dart';
import '../../../shared/theme/app_colors.dart';

/// Анимированный splash screen.
///
/// Показывает логотип с fade-in и scale анимацией (~1.5 сек),
/// удерживает на экране 0.5 сек, затем плавно переходит к [NavigationShell].
/// Общая длительность контроллера 2 сек: [0..0.75] — анимация, [0.75..1.0] — пауза.
class SplashScreen extends StatefulWidget {
  /// Создаёт [SplashScreen].
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final CurvedAnimation _fadeCurve;
  late final CurvedAnimation _scaleCurve;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  /// Общая длительность: 1.5с анимация + 0.5с пауза = 2с.
  static const Duration _totalDuration = Duration(milliseconds: 2000);

  /// Доля анимации от общей длительности (1.5 / 2.0 = 0.75).
  static const double _animationEnd = 0.75;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: _totalDuration,
    );

    // Fade и scale происходят в первые 75% времени контроллера.
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
        _navigateToHome();
      }
    });
    _controller.forward();
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
          return const NavigationShell();
        },
        transitionsBuilder: (
          BuildContext context,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
          Widget child,
        ) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
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
      backgroundColor: AppColors.background,
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
