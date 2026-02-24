import 'dart:async';
import 'dart:io' show Platform;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_windows/webview_windows.dart';

import '../../../l10n/app_localizations.dart';
import '../providers/vgmaps_panel_provider.dart';

/// JS-скрипт для захвата изображения карты со страницы vgmaps.de.
///
/// Ищет `<img id="MapViewerImage">` на странице view.php.
/// Если не найден — ищет первый крупный `<img>` (> 200px).
/// Возвращает JSON с src, width, height через postMessage.
const String _captureMapScript = '''
(function() {
  var img = document.getElementById('MapViewerImage');
  if (!img) {
    var imgs = document.querySelectorAll('img');
    for (var i = 0; i < imgs.length; i++) {
      if (imgs[i].naturalWidth > 200 && imgs[i].naturalHeight > 200) {
        img = imgs[i];
        break;
      }
    }
  }
  if (img) {
    window.chrome.webview.postMessage(JSON.stringify({
      type: 'image_context_menu',
      src: img.src,
      width: img.naturalWidth,
      height: img.naturalHeight
    }));
  }
})();
''';

/// Тип колбэка для добавления изображения на канвас.
typedef VgMapsAddImageCallback = void Function(
  String url,
  int? width,
  int? height,
);

/// Боковая панель VGMaps Browser для поиска и добавления карт на канвас.
class VgMapsPanel extends ConsumerStatefulWidget {
  /// Создаёт [VgMapsPanel].
  const VgMapsPanel({
    required this.collectionId,
    required this.onAddImage,
    this.webViewBuilder,
    super.key,
  });

  /// ID коллекции (null для uncategorized).
  final int? collectionId;

  /// Колбэк при добавлении изображения на канвас.
  final VgMapsAddImageCallback onAddImage;

  /// Опциональный builder для WebView (для тестов).
  /// Если null — используется реальный Webview из webview_windows.
  final Widget Function(WebviewController controller)? webViewBuilder;

  @override
  ConsumerState<VgMapsPanel> createState() => _VgMapsPanelState();
}

class _VgMapsPanelState extends ConsumerState<VgMapsPanel> {
  final WebviewController _controller = WebviewController();
  bool _isWebViewReady = false;
  final TextEditingController _searchController = TextEditingController();
  final List<StreamSubscription<Object?>> _subscriptions =
      <StreamSubscription<Object?>>[];

  @override
  void initState() {
    super.initState();
    // webview_windows работает только на Windows.
    // На других платформах не инициализируем WebView.
    if (Platform.isWindows) {
      _initWebView();
    }
  }

  @override
  void dispose() {
    for (final StreamSubscription<Object?> sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    _searchController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initWebView() async {
    try {
      await _controller.initialize();

      if (!mounted) return;

      // Слушаем сообщения из JS (webMessage уже декодирован из JSON)
      _subscriptions.add(_controller.webMessage.listen(_handleWebMessage));

      // Слушаем навигацию
      _subscriptions.add(_controller.url.listen((String url) {
        if (!mounted) return;
        ref
            .read(vgMapsPanelProvider(widget.collectionId).notifier)
            .setCurrentUrl(url);
      }));

      _subscriptions
          .add(_controller.loadingState.listen((LoadingState loadingState) {
        if (!mounted) return;
        final VgMapsPanelNotifier notifier =
            ref.read(vgMapsPanelProvider(widget.collectionId).notifier);
        notifier.setLoading(isLoading: loadingState == LoadingState.loading);
      }));

      _subscriptions
          .add(_controller.historyChanged.listen((HistoryChanged event) {
        if (!mounted) return;
        ref
            .read(vgMapsPanelProvider(widget.collectionId).notifier)
            .setNavigationState(
              canGoBack: event.canGoBack,
              canGoForward: event.canGoForward,
            );
      }));

      await _controller.loadUrl(vgMapsHomeUrl);

      if (mounted) {
        setState(() {
          _isWebViewReady = true;
        });
      }
    } on Object catch (e) {
      if (mounted) {
        ref
            .read(vgMapsPanelProvider(widget.collectionId).notifier)
            .setError(S.of(context).vgmapsFailedInit(e.toString()));
      }
    }
  }

  void _handleWebMessage(Object? message) {
    if (!mounted) return;
    try {
      // webview_windows автоматически декодирует JSON из postMessage,
      // поэтому message уже является Map, а не строкой.
      final Map<String, Object?> data = message is Map<String, Object?>
          ? message
          : (message as Map<Object?, Object?>).cast<String, Object?>();
      final String? type = data['type'] as String?;
      if (type == 'image_context_menu') {
        final String? src = data['src'] as String?;
        final int? width = data['width'] as int?;
        final int? height = data['height'] as int?;
        if (src != null && src.isNotEmpty) {
          ref
              .read(vgMapsPanelProvider(widget.collectionId).notifier)
              .captureImage(src, width: width, height: height);
        }
      }
    } on Object {
      // Игнорируем невалидные сообщения
    }
  }

  void _navigateHome() {
    _controller.loadUrl(vgMapsHomeUrl);
  }

  void _navigateBack() {
    _controller.goBack();
  }

  void _navigateForward() {
    _controller.goForward();
  }

  void _reload() {
    _controller.reload();
  }

  void _performSearch() {
    final String term = _searchController.text.trim();
    if (term.isEmpty) return;
    final String encoded = Uri.encodeComponent(term);
    _controller.loadUrl('https://vgmaps.de/maps/?search=$encoded');
  }

  /// Захватывает изображение карты с текущей страницы.
  ///
  /// Три стратегии по приоритету:
  /// 1. JS `executeScript` с прямым return (без postMessage)
  /// 2. HTTP fetch текущей страницы + парсинг HTML из Dart
  /// 3. Fallback: postMessage через JS injection
  Future<void> _captureMapImage() async {
    if (!_isWebViewReady) return;

    final VgMapsPanelNotifier notifier =
        ref.read(vgMapsPanelProvider(widget.collectionId).notifier);

    // Стратегия 1: прямой return из executeScript
    try {
      final Object? rawResult = await _controller.executeScript(
        'document.getElementById("MapViewerImage")?.getAttribute("src") ?? ""',
      );
      final String? result = rawResult?.toString();
      if (result != null && result.isNotEmpty) {
        // WebView2 возвращает JSON-encoded строку: "/files/..."
        String src = result;
        if (src.startsWith('"') && src.endsWith('"')) {
          src = src.substring(1, src.length - 1);
        }
        if (src.isNotEmpty && src != 'null') {
          if (src.startsWith('/')) {
            src = 'https://vgmaps.de$src';
          }
          if (mounted) {
            notifier.captureImage(src);
          }
          return;
        }
      }
    } on Object {
      // executeScript не сработал — пробуем fallback
    }

    // Стратегия 2: HTTP fetch + парсинг HTML
    final String? httpResult = await _fetchMapImageFromHtml();
    if (httpResult != null && mounted) {
      notifier.captureImage(httpResult);
      return;
    }

    // Стратегия 3: postMessage через JS injection
    _controller.executeScript(_captureMapScript);
  }

  /// Загружает HTML текущей страницы через HTTP и ищет MapViewerImage.
  ///
  /// Полностью обходит JS-выполнение в WebView — работает даже если
  /// Cloudflare блокирует скрипты.
  Future<String?> _fetchMapImageFromHtml() async {
    try {
      final VgMapsPanelState panelState =
          ref.read(vgMapsPanelProvider(widget.collectionId));
      final String currentUrl = panelState.currentUrl;

      // Работает только на страницах vgmaps.de
      if (!currentUrl.contains('vgmaps.de')) return null;

      final Dio dio = Dio();
      final Response<String> response = await dio.get<String>(
        currentUrl,
        options: Options(
          responseType: ResponseType.plain,
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      final String? html = response.data;
      if (html == null || html.isEmpty) return null;

      // Ищем <img id="MapViewerImage" src="...">
      final RegExp imgRegex = RegExp(
        r'<img\s[^>]*id\s*=\s*"MapViewerImage"[^>]*src\s*=\s*"([^"]+)"',
        caseSensitive: false,
      );
      final RegExpMatch? match = imgRegex.firstMatch(html);

      // Если не нашли по id, пробуем обратный порядок атрибутов
      if (match == null) {
        final RegExp altRegex = RegExp(
          r'<img\s[^>]*src\s*=\s*"([^"]+)"[^>]*id\s*=\s*"MapViewerImage"',
          caseSensitive: false,
        );
        final RegExpMatch? altMatch = altRegex.firstMatch(html);
        if (altMatch != null) {
          return _resolveVgMapsUrl(altMatch.group(1)!);
        }
      }

      if (match != null) {
        return _resolveVgMapsUrl(match.group(1)!);
      }

      // Fallback: ищем любую картинку в /files/ директории
      final RegExp filesRegex = RegExp(
        r'src\s*=\s*"(/files/[^"]+)"',
        caseSensitive: false,
      );
      final RegExpMatch? filesMatch = filesRegex.firstMatch(html);
      if (filesMatch != null) {
        return _resolveVgMapsUrl(filesMatch.group(1)!);
      }

      return null;
    } on Object {
      return null;
    }
  }

  /// Преобразует относительный путь в полный URL vgmaps.de.
  String _resolveVgMapsUrl(String src) {
    if (src.startsWith('/')) {
      return 'https://vgmaps.de$src';
    }
    if (src.startsWith('http')) {
      return src;
    }
    return 'https://vgmaps.de/$src';
  }

  void _handleAddToCanvas() {
    final VgMapsPanelState panelState =
        ref.read(vgMapsPanelProvider(widget.collectionId));
    if (panelState.capturedImageUrl != null) {
      widget.onAddImage(
        panelState.capturedImageUrl!,
        panelState.capturedImageWidth,
        panelState.capturedImageHeight,
      );
      ref
          .read(vgMapsPanelProvider(widget.collectionId).notifier)
          .clearCapturedImage();
    }
  }

  void _dismissCapturedImage() {
    ref
        .read(vgMapsPanelProvider(widget.collectionId).notifier)
        .clearCapturedImage();
  }

  @override
  Widget build(BuildContext context) {
    // Safety guard: не рендерим на non-Windows платформах.
    if (!Platform.isWindows) {
      return const SizedBox.shrink();
    }

    final VgMapsPanelState panelState =
        ref.watch(vgMapsPanelProvider(widget.collectionId));
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Container(
      width: 500,
      color: colorScheme.surface,
      child: Column(
        children: <Widget>[
          // Заголовок
          _buildHeader(colorScheme, theme),
          const Divider(height: 1),

          // Тулбар навигации
          _buildNavigationToolbar(panelState, colorScheme),
          const Divider(height: 1),

          // Индикатор загрузки
          if (panelState.isLoading) const LinearProgressIndicator(),

          // Ошибка
          if (panelState.error != null)
            _buildErrorBanner(panelState.error!, colorScheme, theme),

          // WebView
          Expanded(child: _buildWebView()),

          // Нижняя панель с захваченным изображением
          if (panelState.capturedImageUrl != null)
            _buildCapturedImageBar(panelState, colorScheme, theme),
        ],
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: <Widget>[
          Icon(Icons.map, color: colorScheme.primary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'VGMaps',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            tooltip: S.of(context).vgmapsClosePanel,
            onPressed: () => ref
                .read(vgMapsPanelProvider(widget.collectionId).notifier)
                .closePanel(),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationToolbar(
    VgMapsPanelState panelState,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        children: <Widget>[
          IconButton(
            icon: const Icon(Icons.arrow_back, size: 20),
            tooltip: S.of(context).vgmapsBack,
            onPressed: panelState.canGoBack ? _navigateBack : null,
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward, size: 20),
            tooltip: S.of(context).vgmapsForward,
            onPressed: panelState.canGoForward ? _navigateForward : null,
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            icon: const Icon(Icons.home, size: 20),
            tooltip: S.of(context).vgmapsHome,
            onPressed: _navigateHome,
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: S.of(context).vgmapsReload,
            onPressed: _reload,
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            icon: const Icon(Icons.download, size: 20),
            tooltip: S.of(context).vgmapsCaptureImage,
            onPressed: _isWebViewReady ? _captureMapImage : null,
            visualDensity: VisualDensity.compact,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: SizedBox(
              height: 32,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: S.of(context).vgmapsSearchHint,
                  isDense: true,
                  border: const OutlineInputBorder(),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search, size: 16),
                    tooltip: S.of(context).search,
                    onPressed: _performSearch,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 28,
                      minHeight: 28,
                    ),
                  ),
                ),
                style: const TextStyle(fontSize: 12),
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _performSearch(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(
    String message,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      color: colorScheme.errorContainer,
      child: Row(
        children: <Widget>[
          Icon(Icons.error_outline, size: 16, color: colorScheme.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onErrorContainer,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            onPressed: () => ref
                .read(vgMapsPanelProvider(widget.collectionId).notifier)
                .clearError(),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildWebView() {
    if (!_isWebViewReady) {
      return const Center(child: CircularProgressIndicator());
    }

    if (widget.webViewBuilder != null) {
      return widget.webViewBuilder!(_controller);
    }

    return Webview(_controller);
  }

  Widget _buildCapturedImageBar(
    VgMapsPanelState panelState,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: <Widget>[
          // Превью
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              width: 48,
              height: 48,
              child: CachedNetworkImage(
                imageUrl: panelState.capturedImageUrl!,
                fit: BoxFit.cover,
                placeholder: (BuildContext context, String url) => Container(
                  color: colorScheme.surfaceContainerHighest,
                  child: const Center(
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
                errorWidget:
                    (BuildContext context, String url, Object error) =>
                        Container(
                  color: colorScheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.broken_image_outlined,
                    size: 20,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Информация
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'Image captured',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (panelState.capturedImageWidth != null &&
                    panelState.capturedImageHeight != null)
                  Text(
                    '${panelState.capturedImageWidth}x${panelState.capturedImageHeight}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),

          // Кнопка добавления
          FilledButton.icon(
            onPressed: _handleAddToCanvas,
            icon: const Icon(Icons.add, size: 16),
            label: Text(S.of(context).canvasAddToBoard),
            style: FilledButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              minimumSize: const Size(0, 36),
            ),
          ),
          const SizedBox(width: 4),

          // Закрыть
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            tooltip: S.of(context).vgmapsDismiss,
            onPressed: _dismissCapturedImage,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
          ),
        ],
      ),
    );
  }
}
