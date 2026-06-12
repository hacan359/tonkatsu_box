// Welcome Wizard — first-run onboarding.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../features/settings/providers/settings_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/constants/platform_features.dart';
import '../../../shared/navigation/app_shell.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_durations.dart';
import '../../../shared/theme/app_spacing.dart';
import '../providers/menu_tour_provider.dart';
import '../widgets/step_indicator.dart';
import '../widgets/welcome_step_intro.dart';
import '../widgets/welcome_step_language.dart';
import '../widgets/welcome_step_menu_tour.dart';
import '../widgets/welcome_step_name.dart';
import '../widgets/welcome_step_sources.dart';

/// SharedPreferences flag marking the wizard as completed.
const String kWelcomeCompletedKey = 'welcome_completed';

/// Welcome Wizard — a 5-step onboarding flow.
///
/// Shown automatically on first launch instead of [AppShell]. Can be reopened
/// from Settings (with [fromSettings] = true). Steps: Welcome → Language →
/// Name → Sources (with inline API keys) → interactive menu Tour.
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({this.fromSettings = false, super.key});

  /// When true, the wizard was pushed from Settings (not a first run).
  final bool fromSettings;

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const int _totalSteps = 5;

  /// Index of the final, interactive menu-tour step.
  static const int _tourStep = _totalSteps - 1;

  List<String> _stepLabels(S l) => <String>[
        l.welcomeStepWelcome,
        l.welcomeStepLanguage,
        l.welcomeStepName,
        l.welcomeStepSources,
        l.welcomeStepTour,
      ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool compact = isCompactScreen(context);
    final bool onTour = _currentPage == _tourStep;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _buildStepBar(compact),
            _buildProgressBar(),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (int page) {
                  setState(() => _currentPage = page);
                },
                children: <Widget>[
                  const WelcomeStepIntro(),
                  const WelcomeStepLanguage(),
                  const WelcomeStepName(),
                  const WelcomeStepSources(),
                  WelcomeStepMenuTour(
                    onStart: () => _finish(startTour: true),
                    onSkip: _finish,
                  ),
                ],
              ),
            ),
            // The tour owns its own controls (Next / Skip / Start).
            if (!onTour) _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepBar(bool compact) {
    final S l = S.of(context);
    final List<String> labels = _stepLabels(l);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.surfaceBorder.withAlpha(50),
          ),
        ),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: List<Widget>.generate(_totalSteps, (int index) {
                return StepIndicator(
                  number: index + 1,
                  label: labels[index],
                  isActive: index == _currentPage,
                  isDone: index < _currentPage,
                  showLabel: !compact || index == _currentPage,
                  onTap: () => _goToPage(index),
                );
              }),
            ),
          ),
          if (_currentPage < _totalSteps - 1)
            GestureDetector(
              onTap: () => _goToPage(_totalSteps - 1),
              child: Text(
                l.skip,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textTertiary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return SizedBox(
      height: 2,
      child: LinearProgressIndicator(
        value: (_currentPage + 1) / _totalSteps,
        backgroundColor: AppColors.surfaceBorder,
        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.brand),
      ),
    );
  }

  Widget _buildBottomNav() {
    final S l = S.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppColors.surfaceBorder.withAlpha(50),
          ),
        ),
      ),
      child: Row(
        children: <Widget>[
          TextButton(
            onPressed: _currentPage > 0
                ? () => _goToPage(_currentPage - 1)
                : null,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              disabledForegroundColor: AppColors.textTertiary.withAlpha(60),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(Icons.arrow_back, size: 14),
                const SizedBox(width: 4),
                Text(l.back, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
          const Spacer(),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List<Widget>.generate(_totalSteps, (int index) {
              final bool isActive = index == _currentPage;
              final bool isDone = index < _currentPage;
              return GestureDetector(
                onTap: () => _goToPage(index),
                child: AnimatedContainer(
                  duration: AppDurations.normal,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: isActive ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.brand
                        : isDone
                            ? AppColors.success
                            : AppColors.surfaceBorder,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                  ),
                ),
              );
            }),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => _goToPage(_currentPage + 1),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: AppColors.brand,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    l.next,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward, size: 14, color: Colors.black),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: AppDurations.slow,
      curve: Curves.easeInOut,
    );
  }

  Future<void> _finish({bool startTour = false}) async {
    final SharedPreferences prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(kWelcomeCompletedKey, true);

    // The tour overlay plays over the real shell that this finish reveals
    // (a fresh AppShell on first run, or the one under the Settings push).
    if (startTour) {
      ref.read(menuTourControllerProvider.notifier).start();
    }

    if (!mounted) return;

    if (widget.fromSettings) {
      Navigator.of(context).pop();
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const AppShell(),
      ),
    );
  }
}
