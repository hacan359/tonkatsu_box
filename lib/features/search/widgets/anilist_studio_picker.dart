import 'dart:async';

import 'package:core/models/anilist_studio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/anilist_api.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../models/search_source.dart';
import '../utils/filter_ui.dart';

/// Returns the picked studio name, [kFilterResetSentinel] to clear, or null
/// when dismissed - the single-select custom picker contract.
Future<Object?> showAniListStudioPicker(
  BuildContext context,
  WidgetRef _,
  S l,
  Object? currentValue,
) {
  return showModalBottomSheet<Object?>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (BuildContext ctx) => _AniListStudioPicker(
      current: currentValue is String ? currentValue : null,
      l: l,
    ),
  );
}

class _AniListStudioPicker extends ConsumerStatefulWidget {
  const _AniListStudioPicker({required this.current, required this.l});

  final String? current;
  final S l;

  @override
  ConsumerState<_AniListStudioPicker> createState() =>
      _AniListStudioPickerState();
}

class _AniListStudioPickerState extends ConsumerState<_AniListStudioPicker> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  int _generation = 0;
  List<AniListStudio> _results = const <AniListStudio>[];
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(SearchSource.defaultSearchDebounce, () => _search(value));
  }

  Future<void> _search(String query) async {
    _debounce?.cancel();
    final int gen = ++_generation;
    if (query.trim().isEmpty) {
      setState(() {
        _results = const <AniListStudio>[];
        _loading = false;
        _error = null;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final List<AniListStudio> found = await ref
          .read(aniListApiProvider)
          .searchStudios(query);
      if (gen != _generation || !mounted) return;
      setState(() {
        _results = found
            .where((AniListStudio s) => s.isAnimationStudio)
            .toList();
        _loading = false;
      });
    } on Object catch (e) {
      if (gen != _generation || !mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final S l = widget.l;
    final String? current = widget.current;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(l.studioPickerTitle, style: AppTypography.h3),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: l.studioPickerSearchHint,
              ),
              onChanged: _onChanged,
              onSubmitted: _search,
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: <Widget>[
                Icon(Icons.info_outline,
                    size: 14, color: AppColors.textTertiary),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    l.studioFilterExclusiveHint,
                    style: AppTypography.caption
                        .copyWith(color: AppColors.textTertiary),
                  ),
                ),
              ],
            ),
            if (current != null) ...<Widget>[
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerLeft,
                child: InputChip(
                  label: Text(current),
                  selected: true,
                  onDeleted: () =>
                      Navigator.of(context).pop(kFilterResetSentinel),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            const Divider(height: 1),
            Flexible(child: _buildBody(l)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(S l) {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: CircularProgressIndicator(),
        ),
      );
    }
    final String? error = _error;
    if (error != null) {
      return _Hint(text: error, color: AppColors.error);
    }
    if (_controller.text.trim().isEmpty) {
      return _Hint(text: l.studioPickerTypeToSearch);
    }
    if (_results.isEmpty) {
      return _Hint(text: l.studioPickerEmpty);
    }
    return ListView.builder(
      itemCount: _results.length,
      itemBuilder: (BuildContext ctx, int index) {
        final AniListStudio studio = _results[index];
        return ListTile(
          key: ValueKey<int>(studio.id),
          leading: const Icon(Icons.business),
          title: Text(studio.name),
          selected: studio.name == widget.current,
          onTap: () => Navigator.of(context).pop(studio.name),
        );
      },
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.text, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: AppTypography.bodySmall.copyWith(
            color: color ?? AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
