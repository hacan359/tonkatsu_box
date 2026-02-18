import 'package:flutter_riverpod/flutter_riverpod.dart';

// Домашний URL VGMaps (Better VGMaps).
const String vgMapsHomeUrl = 'https://vgmaps.de/';

/// Состояние боковой панели VGMaps Browser.
class VgMapsPanelState {
  /// Создаёт экземпляр [VgMapsPanelState].
  const VgMapsPanelState({
    this.isOpen = false,
    this.currentUrl = vgMapsHomeUrl,
    this.canGoBack = false,
    this.canGoForward = false,
    this.isLoading = false,
    this.capturedImageUrl,
    this.capturedImageWidth,
    this.capturedImageHeight,
    this.error,
  });

  /// Открыта ли панель.
  final bool isOpen;

  /// Текущий URL в WebView.
  final String currentUrl;

  /// Можно ли перейти назад.
  final bool canGoBack;

  /// Можно ли перейти вперёд.
  final bool canGoForward;

  /// Идёт ли загрузка страницы.
  final bool isLoading;

  /// URL захваченного изображения (из JS injection).
  final String? capturedImageUrl;

  /// Ширина захваченного изображения.
  final int? capturedImageWidth;

  /// Высота захваченного изображения.
  final int? capturedImageHeight;

  /// Ошибка.
  final String? error;

  /// Создаёт копию с изменёнными полями.
  VgMapsPanelState copyWith({
    bool? isOpen,
    String? currentUrl,
    bool? canGoBack,
    bool? canGoForward,
    bool? isLoading,
    String? capturedImageUrl,
    bool clearCapturedImage = false,
    int? capturedImageWidth,
    int? capturedImageHeight,
    String? error,
    bool clearError = false,
  }) {
    return VgMapsPanelState(
      isOpen: isOpen ?? this.isOpen,
      currentUrl: currentUrl ?? this.currentUrl,
      canGoBack: canGoBack ?? this.canGoBack,
      canGoForward: canGoForward ?? this.canGoForward,
      isLoading: isLoading ?? this.isLoading,
      capturedImageUrl: clearCapturedImage
          ? null
          : (capturedImageUrl ?? this.capturedImageUrl),
      capturedImageWidth: clearCapturedImage
          ? null
          : (capturedImageWidth ?? this.capturedImageWidth),
      capturedImageHeight: clearCapturedImage
          ? null
          : (capturedImageHeight ?? this.capturedImageHeight),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Провайдер для управления боковой панелью VGMaps Browser.
final NotifierProviderFamily<VgMapsPanelNotifier, VgMapsPanelState, int?>
    vgMapsPanelProvider =
    NotifierProvider.family<VgMapsPanelNotifier, VgMapsPanelState, int?>(
  VgMapsPanelNotifier.new,
);

/// Notifier для управления состоянием боковой панели VGMaps Browser.
class VgMapsPanelNotifier extends FamilyNotifier<VgMapsPanelState, int?> {
  @override
  VgMapsPanelState build(int? arg) {
    return const VgMapsPanelState();
  }

  /// Переключает видимость панели.
  void togglePanel() {
    state = state.copyWith(isOpen: !state.isOpen);
  }

  /// Открывает панель.
  void openPanel() {
    state = state.copyWith(isOpen: true);
  }

  /// Закрывает панель.
  void closePanel() {
    state = state.copyWith(isOpen: false);
  }

  /// Обновляет текущий URL при навигации.
  void setCurrentUrl(String url) {
    state = state.copyWith(currentUrl: url);
  }

  /// Обновляет состояние навигации (назад/вперёд).
  void setNavigationState({
    required bool canGoBack,
    required bool canGoForward,
  }) {
    state = state.copyWith(
      canGoBack: canGoBack,
      canGoForward: canGoForward,
    );
  }

  /// Устанавливает состояние загрузки страницы.
  void setLoading({required bool isLoading}) {
    state = state.copyWith(isLoading: isLoading);
  }

  /// Захватывает URL изображения из JS injection.
  void captureImage(String url, {int? width, int? height}) {
    state = state.copyWith(
      capturedImageUrl: url,
      capturedImageWidth: width,
      capturedImageHeight: height,
    );
  }

  /// Очищает захваченное изображение.
  void clearCapturedImage() {
    state = state.copyWith(clearCapturedImage: true);
  }

  /// Устанавливает ошибку.
  void setError(String error) {
    state = state.copyWith(error: error);
  }

  /// Очищает ошибку.
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}
