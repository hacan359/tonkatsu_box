import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/collection_hero_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/collection.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../providers/collections_provider.dart';
import 'collection_hero_background.dart';

/// Persists changes directly through `collectionsProvider.notifier`.
/// Pops `true` if the user pressed Save and the changes were applied.
class EditCollectionDialog extends ConsumerStatefulWidget {
  const EditCollectionDialog({required this.collection, super.key});

  final Collection collection;

  static Future<bool> show(
    BuildContext context,
    Collection collection,
  ) async {
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) =>
          EditCollectionDialog(collection: collection),
    );
    return result ?? false;
  }

  @override
  ConsumerState<EditCollectionDialog> createState() =>
      _EditCollectionDialogState();
}

class _EditCollectionDialogState extends ConsumerState<EditCollectionDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;

  /// File name of the newly picked hero image, not yet saved to the DB.
  String? _pendingHeroFile;

  bool _clearHero = false;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.collection.name);
    _descriptionController = TextEditingController(
      text: widget.collection.description ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Current hero file name, taking the pending pick into account.
  String? get _currentHeroFile {
    if (_clearHero) return null;
    return _pendingHeroFile ?? widget.collection.heroImagePath;
  }

  Future<void> _pickImage() async {
    final CollectionHeroService service =
        ref.read(collectionHeroServiceProvider);
    final String? picked = await service.pickAndSave(
      collectionId: widget.collection.id,
      // The old file is deleted only on Save — the user may still cancel.
    );
    if (picked == null) return;

    // Delete the previous pending pick: it was never saved to the DB.
    if (_pendingHeroFile != null) {
      await service.delete(_pendingHeroFile);
    }

    setState(() {
      _pendingHeroFile = picked;
      _clearHero = false;
    });
  }

  void _removeImage() {
    setState(() {
      _pendingHeroFile = null;
      _clearHero = true;
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);

    final String newName = _nameController.text.trim();
    final String newDescription = _descriptionController.text.trim();

    final bool nameChanged = newName != widget.collection.name;
    final bool descChanged =
        newDescription != (widget.collection.description ?? '');
    final bool descEmpty = newDescription.isEmpty;
    final bool heroChanged = _pendingHeroFile != null || _clearHero;

    // Delete the old hero file when the user picked a new one or removed it.
    final CollectionHeroService service =
        ref.read(collectionHeroServiceProvider);
    final String? oldHero = widget.collection.heroImagePath;
    if (heroChanged && oldHero != null && oldHero != _pendingHeroFile) {
      await service.delete(oldHero);
    }

    await ref.read(collectionsProvider.notifier).updatePersonalization(
          widget.collection.id,
          name: nameChanged ? newName : null,
          heroImagePath: _pendingHeroFile,
          description: descChanged && !descEmpty ? newDescription : null,
          clearHeroImage: _clearHero,
          clearDescription: descChanged && descEmpty,
        );

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  Future<void> _cancel() async {
    // The newly picked image was already written to disk — clean it up.
    if (_pendingHeroFile != null) {
      await ref.read(collectionHeroServiceProvider).delete(_pendingHeroFile);
    }
    if (!mounted) return;
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    final CollectionHeroService service =
        ref.watch(collectionHeroServiceProvider);
    final String? heroFile = _currentHeroFile;
    final String? heroAbsPath = service.resolve(heroFile);

    return AlertDialog(
      scrollable: true,
      titlePadding:
          const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.sm, 0),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      title: Row(
        children: <Widget>[
          Expanded(child: Text(l.collectionEditDialogTitle)),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: _saving ? null : _cancel,
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _HeroPreview(
                absolutePath: heroAbsPath,
                name: _nameController.text.trim().isEmpty
                    ? widget.collection.name
                    : _nameController.text.trim(),
                description: _descriptionController.text.trim().isEmpty
                    ? null
                    : _descriptionController.text.trim(),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l.collectionEditHeroImageHint,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _saving ? null : _pickImage,
                      icon: const Icon(Icons.image_outlined, size: 18),
                      label: Text(
                        heroAbsPath != null
                            ? l.collectionEditHeroReplace
                            : l.collectionEditHeroPick,
                      ),
                    ),
                  ),
                  if (heroAbsPath != null) ...<Widget>[
                    const SizedBox(width: AppSpacing.sm),
                    IconButton.outlined(
                      onPressed: _saving ? null : _removeImage,
                      icon: const Icon(Icons.delete_outline, size: 18),
                      tooltip: l.collectionEditHeroRemove,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: l.createCollectionNameLabel,
                  border: const OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
                onChanged: (_) => setState(() {}),
                validator: (String? value) {
                  if (value == null || value.trim().isEmpty) {
                    return l.createCollectionEnterName;
                  }
                  if (value.trim().length < 2) {
                    return l.createCollectionNameTooShort;
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),

              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: l.collectionEditDescription,
                  hintText: l.collectionEditDescriptionHint,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
                minLines: 2,
                maxLength: 240,
                textInputAction: TextInputAction.done,
                onChanged: (_) => setState(() {}),
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _saving ? null : _cancel,
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(l.save),
        ),
      ],
    );
  }
}

class _HeroPreview extends StatelessWidget {
  const _HeroPreview({
    required this.absolutePath,
    required this.name,
    this.description,
  });

  final String? absolutePath;
  final String name;
  final String? description;

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: absolutePath == null
            ? _EmptyPreview(label: l.collectionEditHeroImage)
            : Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  CollectionHeroBackground(
                    imagePath: absolutePath!,
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              name,
                              style: AppTypography.h2.copyWith(
                                color: AppColors.textPrimary,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                shadows: const <Shadow>[
                                  Shadow(color: Colors.black87, blurRadius: 10),
                                ],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (description != null) ...<Widget>[
                              const SizedBox(height: 2),
                              Text(
                                description!,
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textSecondary,
                                  shadows: const <Shadow>[
                                    Shadow(
                                      color: Colors.black87,
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _EmptyPreview extends StatelessWidget {
  const _EmptyPreview({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[AppColors.surface, AppColors.surfaceLight],
        ),
        border: Border.all(color: AppColors.surfaceBorder),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.image_outlined,
              color: AppColors.textTertiary,
              size: 40,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

