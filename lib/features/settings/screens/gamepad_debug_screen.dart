// Debug-экран для отображения raw событий геймпада.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamepads/gamepads.dart';

import '../../../core/services/gamepad_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/gamepad/gamepad_provider.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/auto_breadcrumb_app_bar.dart';
import '../../../shared/widgets/breadcrumb_scope.dart';

/// Максимальное количество событий в логе.
const int _maxEvents = 100;

/// Debug-экран для тестирования подключённого геймпада.
///
/// Показывает:
/// - Сырые события от [Gamepads.events] в реальном времени
/// - Обработанные события от [GamepadService]
/// - Ключи кнопок и значения для маппинга
class GamepadDebugScreen extends ConsumerStatefulWidget {
  /// Создаёт [GamepadDebugScreen].
  const GamepadDebugScreen({super.key});

  @override
  ConsumerState<GamepadDebugScreen> createState() =>
      _GamepadDebugScreenState();
}

class _GamepadDebugScreenState extends ConsumerState<GamepadDebugScreen> {
  final List<_EventEntry> _rawEvents = <_EventEntry>[];
  final List<_EventEntry> _serviceEvents = <_EventEntry>[];
  final ScrollController _rawScrollController = ScrollController();
  final ScrollController _serviceScrollController = ScrollController();
  StreamSubscription<GamepadEvent>? _rawSub;
  StreamSubscription<GamepadServiceEvent>? _serviceSub;

  @override
  void initState() {
    super.initState();
    final GamepadService service = ref.read(gamepadServiceProvider);

    _rawSub = service.rawEvents.listen((GamepadEvent event) {
      // ignore: avoid_print
      print('[GAMEPAD] key=${event.key}  type=${event.type}  '
          'value=${event.value.toStringAsFixed(3)}');
      setState(() {
        _rawEvents.insert(
          0,
          _EventEntry(
            time: DateTime.now(),
            text: 'key=${event.key}  type=${event.type}  '
                'value=${event.value.toStringAsFixed(3)}  '
                'gamepad=${event.gamepadId}',
          ),
        );
        if (_rawEvents.length > _maxEvents) {
          _rawEvents.removeLast();
        }
      });
    });

    _serviceSub = service.events.listen((GamepadServiceEvent event) {
      setState(() {
        _serviceEvents.insert(
          0,
          _EventEntry(
            time: DateTime.now(),
            text: 'key=${event.key}  value=${event.value.toStringAsFixed(3)}'
                '  type=${event.type.name}',
          ),
        );
        if (_serviceEvents.length > _maxEvents) {
          _serviceEvents.removeLast();
        }
      });
    });
  }

  @override
  void dispose() {
    _rawSub?.cancel();
    _serviceSub?.cancel();
    _rawScrollController.dispose();
    _serviceScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    return BreadcrumbScope(
      label: l.debugGamepad,
      child: Scaffold(
      appBar: AutoBreadcrumbAppBar(
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: l.debugClearLogs,
            onPressed: () {
              setState(() {
                _rawEvents.clear();
                _serviceEvents.clear();
              });
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Raw events
            Expanded(
              child: _buildEventColumn(
                title: l.debugRawEvents,
                events: _rawEvents,
                scrollController: _rawScrollController,
                color: AppColors.brand,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Service events
            Expanded(
              child: _buildEventColumn(
                title: l.debugServiceEvents,
                events: _serviceEvents,
                scrollController: _serviceScrollController,
                color: AppColors.tvShowAccent,
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildEventColumn({
    required String title,
    required List<_EventEntry> events,
    required ScrollController scrollController,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              title,
              style: AppTypography.bodySmall.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              S.of(context).debugEventsCount(events.length),
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: events.isEmpty
                ? Center(
                    child: Text(
                      S.of(context).debugPressButton,
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: scrollController,
                    itemCount: events.length,
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    itemBuilder: (BuildContext context, int index) {
                      final _EventEntry entry = events[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          '${_formatTime(entry.time)}  ${entry.text}',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime time) {
    final String h = time.hour.toString().padLeft(2, '0');
    final String m = time.minute.toString().padLeft(2, '0');
    final String s = time.second.toString().padLeft(2, '0');
    final String ms = time.millisecond.toString().padLeft(3, '0');
    return '$h:$m:$s.$ms';
  }
}

class _EventEntry {
  const _EventEntry({required this.time, required this.text});
  final DateTime time;
  final String text;
}
