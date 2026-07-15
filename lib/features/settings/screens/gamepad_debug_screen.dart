import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamepads/gamepads.dart';
import 'package:logging/logging.dart';

import '../../../core/services/gamepad_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/extensions/snackbar_extension.dart';
import '../../../shared/gamepad/gamepad_provider.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/draggable_fab.dart';
import '../../../shared/widgets/sub_screen_title_bar.dart';

const int _maxEvents = 100;

class GamepadDebugScreen extends ConsumerStatefulWidget {
  const GamepadDebugScreen({super.key});

  @override
  ConsumerState<GamepadDebugScreen> createState() =>
      _GamepadDebugScreenState();
}

class _GamepadDebugScreenState extends ConsumerState<GamepadDebugScreen> {
  static final Logger _log = Logger('GamepadDebugScreen');

  final List<_EventEntry> _rawEvents = <_EventEntry>[];
  final List<_EventEntry> _serviceEvents = <_EventEntry>[];
  final List<_EventEntry> _keyEvents = <_EventEntry>[];
  final ScrollController _rawScrollController = ScrollController();
  final ScrollController _serviceScrollController = ScrollController();
  final ScrollController _keyScrollController = ScrollController();
  StreamSubscription<GamepadEvent>? _rawSub;
  StreamSubscription<GamepadServiceEvent>? _serviceSub;

  @override
  void initState() {
    super.initState();
    final GamepadService service = ref.read(gamepadServiceProvider);

    _rawSub = service.rawEvents.listen((GamepadEvent event) {
      _log.fine('key=${event.key}  type=${event.type}  '
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
    _keyScrollController.dispose();
    super.dispose();
  }

  /// Captures Flutter hardware key events. On Android, gamepad buttons arrive
  /// here (as `gameButton*` keys) even when the `gamepads` plugin stays silent.
  /// Never consumed, so global shortcuts keep working.
  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (!Platform.isAndroid) return KeyEventResult.ignored;
    final String kind = switch (event) {
      KeyDownEvent() => 'down',
      KeyUpEvent() => 'up',
      KeyRepeatEvent() => 'repeat',
      _ => 'other',
    };
    if (kind == 'up') return KeyEventResult.ignored;
    final LogicalKeyboardKey lk = event.logicalKey;
    final PhysicalKeyboardKey pk = event.physicalKey;
    setState(() {
      _keyEvents.insert(
        0,
        _EventEntry(
          time: DateTime.now(),
          text: 'logical=${lk.debugName ?? lk.keyLabel} '
              '(0x${lk.keyId.toRadixString(16)})  '
              'physical=${pk.debugName ?? "?"} '
              '(0x${pk.usbHidUsage.toRadixString(16)})  $kind',
        ),
      );
      if (_keyEvents.length > _maxEvents) {
        _keyEvents.removeLast();
      }
    });
    return KeyEventResult.ignored;
  }

  Future<void> _exportLog() async {
    final S l = S.of(context);

    if (_rawEvents.isEmpty && _serviceEvents.isEmpty && _keyEvents.isEmpty) {
      if (mounted) {
        context.showSnack(l.debugLogEmpty);
      }
      return;
    }

    final StringBuffer buffer = StringBuffer();
    buffer.writeln('=== Gamepad Debug Log ===');
    buffer.writeln('Exported: ${DateTime.now().toIso8601String()}');
    buffer.writeln();

    buffer.writeln('--- Raw Events (${_rawEvents.length}) ---');
    for (final _EventEntry entry in _rawEvents.reversed) {
      buffer.writeln('${_formatTime(entry.time)}  ${entry.text}');
    }
    buffer.writeln();

    buffer.writeln('--- Service Events (${_serviceEvents.length}) ---');
    for (final _EventEntry entry in _serviceEvents.reversed) {
      buffer.writeln('${_formatTime(entry.time)}  ${entry.text}');
    }
    buffer.writeln();

    buffer.writeln('--- Key Events (${_keyEvents.length}) ---');
    for (final _EventEntry entry in _keyEvents.reversed) {
      buffer.writeln('${_formatTime(entry.time)}  ${entry.text}');
    }

    final String content = buffer.toString();

    try {
      // On Android FileType.custom doesn't support custom extensions.
      final bool useAny = Platform.isAndroid || Platform.isIOS;
      final String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: l.debugExportLog,
        fileName: 'gamepad_log.txt',
        type: useAny ? FileType.any : FileType.custom,
        allowedExtensions: useAny ? null : <String>['txt'],
        bytes: utf8.encode(content),
      );
      if (outputPath == null) return;
      // On Android/iOS file_picker writes the bytes via SAF;
      // on desktop the file must be written manually.
      if (!Platform.isAndroid && !Platform.isIOS) {
        await File(outputPath).writeAsString(content);
      }
      if (mounted) {
        context.showSnack(
          l.debugLogExported(outputPath),
          type: SnackType.success,
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        context.showErrorSnack(e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    return Focus(
      autofocus: true,
      onKeyEvent: _handleKey,
      child: Stack(
        children: <Widget>[
        Column(
          children: <Widget>[
            SubScreenTitleBar(title: l.settingsGamepadDebug),
            Expanded(
              child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool isNarrow = constraints.maxWidth < 600;

            final Widget rawColumn = _buildEventColumn(
              title: l.debugRawEvents,
              events: _rawEvents,
              scrollController: _rawScrollController,
              color: AppColors.brand,
            );
            final Widget serviceColumn = _buildEventColumn(
              title: l.debugServiceEvents,
              events: _serviceEvents,
              scrollController: _serviceScrollController,
              color: AppColors.tvShowAccent,
            );
            // Flutter key-event capture is Android-only (gamepad buttons arrive
            // as key events there); elsewhere it stays hidden.
            final Widget? keyColumn = Platform.isAndroid
                ? _buildEventColumn(
                    title: l.debugKeyEvents,
                    events: _keyEvents,
                    scrollController: _keyScrollController,
                    color: AppColors.gameAccent,
                  )
                : null;

            if (isNarrow) {
              return Column(
                children: <Widget>[
                  if (keyColumn != null) ...<Widget>[
                    Expanded(child: keyColumn),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  Expanded(child: rawColumn),
                  const SizedBox(height: AppSpacing.md),
                  Expanded(child: serviceColumn),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (keyColumn != null) ...<Widget>[
                  Expanded(child: keyColumn),
                  const SizedBox(width: AppSpacing.md),
                ],
                Expanded(child: rawColumn),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: serviceColumn),
              ],
            );
          },
        ),
            ),
          ),
          ],
        ),
        DraggableFab(
          mainAction: DraggableFabItem(
            icon: Icons.save_alt,
            label: l.debugExportLog,
            onTap: _exportLog,
          ),
          items: <DraggableFabItem>[
            DraggableFabItem(
              icon: Icons.delete_outline,
              label: l.debugClearLogs,
              iconColor: AppColors.error,
              onTap: () {
                setState(() {
                  _rawEvents.clear();
                  _serviceEvents.clear();
                  _keyEvents.clear();
                });
              },
            ),
          ],
        ),
        ],
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
            Flexible(
              child: Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
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
