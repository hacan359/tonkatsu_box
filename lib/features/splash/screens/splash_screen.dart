// Анимированный splash screen с логотипом Tonkatsu Box.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_service.dart';
import '../../../shared/constants/platform_features.dart';
import '../../../shared/navigation/navigation_shell.dart';
import '../../../shared/theme/app_assets.dart';
import '../../../shared/theme/app_colors.dart';

/// Анимированный splash screen.
///
/// Показывает логотип с fade-in и scale анимацией (~1.5 сек),
/// удерживает на экране 0.5 сек, затем плавно переходит к [NavigationShell].
/// Общая длительность контроллера 2 сек: [0..0.75] — анимация, [0.75..1.0] — пауза.
///
/// Параллельно с анимацией запускает инициализацию базы данных (pre-warming).
/// Навигация происходит только когда **оба** условия выполнены:
/// анимация завершена И база данных открыта. Это гарантирует, что тяжёлая
/// DB-инициализация не пересекается с route transition, предотвращая ANR.
class SplashScreen extends ConsumerStatefulWidget {
  /// Создаёт [SplashScreen].
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

  /// Анимация завершена.
  bool _animationDone = false;

  /// База данных инициализирована.
  bool _dbDone = false;

  /// Навигация уже выполнена.
  bool _navigated = false;

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
        _animationDone = true;
        _tryNavigate();
      }
    });
    _controller.forward();

    // Pre-warm: запускаем инициализацию DB в фоне.
    // Навигация произойдёт только когда И анимация завершена, И DB открыта.
    // Это разводит DB-инициализацию и route transition по времени,
    // предотвращая конкуренцию за main thread и ANR на слабых устройствах.
    ref.read(databaseServiceProvider).database.then((_) {
      _dbDone = true;
      _tryNavigate();
    });
  }

  /// Навигирует на главный экран когда оба условия выполнены:
  /// анимация завершена И база данных открыта.
  void _tryNavigate() {
    if (_animationDone && _dbDone && !_navigated && mounted) {
      _navigated = true;
      _navigateToHome();
    }
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
        transitionDuration: Duration(milliseconds: kIsMobile ? 200 : 500),
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
