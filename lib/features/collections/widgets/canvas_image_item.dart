import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/image_cache_service.dart';
import '../../../shared/models/canvas_item.dart';
import '../../../shared/widgets/cached_image.dart';

// Виджет изображения на канвасе.
//
// Поддерживает два формата данных:
// - {url: String} — сетевое изображение через CachedImage (с диск-кэшем)
// - {base64: String, mimeType: String} — локальное изображение

/// Вычисляет стабильный хэш строки для использования как imageId.
///
/// Используется FNV-1a 32-bit алгоритм — детерминированный,
/// не зависит от версии Dart или платформы.
String urlToImageId(String url) {
  int hash = 0x811c9dc5;
  for (int i = 0; i < url.length; i++) {
    hash ^= url.codeUnitAt(i);
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  return hash.toRadixString(16).padLeft(8, '0');
}

/// Изображение на канвасе.
///
/// Использует StatefulWidget для кэширования декодированных base64-байтов.
/// Без кэширования каждый rebuild канваса (при перемещении, зуме)
/// вызывает base64Decode заново, что приводит к морганию изображения.
class CanvasImageItem extends ConsumerStatefulWidget {
  /// Создаёт [CanvasImageItem].
  const CanvasImageItem({required this.item, super.key});

  /// Элемент канваса с данными изображения.
  final CanvasItem item;

  @override
  ConsumerState<CanvasImageItem> createState() => _CanvasImageItemState();
}

class _CanvasImageItemState extends ConsumerState<CanvasImageItem> {
  Uint8List? _cachedBytes;
  String? _cachedBase64Source;

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic>? data = widget.item.data;
    final String? url = data?['url'] as String?;
    final String? base64Data = data?['base64'] as String?;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    Widget imageWidget;

    if (url != null && url.isNotEmpty) {
      imageWidget = CachedImage(
        imageType: ImageType.canvasImage,
        imageId: urlToImageId(url),
        remoteUrl: url,
        fit: BoxFit.cover,
        placeholder: Center(
          child: Icon(
            Icons.image_outlined,
            size: 32,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        errorWidget: Center(
          child: Icon(
            Icons.broken_image_outlined,
            size: 32,
            color: colorScheme.error,
          ),
        ),
      );
    } else if (base64Data != null && base64Data.isNotEmpty) {
      // Кэшируем декодированные байты — пересоздаём только при смене данных
      if (_cachedBytes == null || _cachedBase64Source != base64Data) {
        _cachedBytes = base64Decode(base64Data);
        _cachedBase64Source = base64Data;
      }
      imageWidget = Image.memory(
        _cachedBytes!,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder:
            (BuildContext context, Object error, StackTrace? stackTrace) =>
                Center(
          child: Icon(
            Icons.broken_image_outlined,
            size: 32,
            color: colorScheme.error,
          ),
        ),
      );
    } else {
      imageWidget = Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 32,
          color: colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: SizedBox.expand(
        child: imageWidget,
      ),
    );
  }
}
