import 'package:flutter_riverpod/flutter_riverpod.dart';

const String vgMapsHomeUrl = 'https://vgmaps.de/';

class VgMapsPanelState {
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

  final bool isOpen;
  final String currentUrl;
  final bool canGoBack;
  final bool canGoForward;
  final bool isLoading;

  /// Image URL captured via the page's JS injection.
  final String? capturedImageUrl;
  final int? capturedImageWidth;
  final int? capturedImageHeight;

  final String? error;

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

final NotifierProviderFamily<VgMapsPanelNotifier, VgMapsPanelState, int?>
    vgMapsPanelProvider =
    NotifierProvider.family<VgMapsPanelNotifier, VgMapsPanelState, int?>(
  VgMapsPanelNotifier.new,
);

class VgMapsPanelNotifier extends FamilyNotifier<VgMapsPanelState, int?> {
  @override
  VgMapsPanelState build(int? arg) {
    return const VgMapsPanelState();
  }

  void togglePanel() {
    state = state.copyWith(isOpen: !state.isOpen);
  }

  void openPanel() {
    state = state.copyWith(isOpen: true);
  }

  /// The provider is keyed by `collectionId`, so without a full reset the
  /// previous URL / captured image would leak into the next canvas.
  void closePanel() {
    state = const VgMapsPanelState();
  }

  void setCurrentUrl(String url) {
    state = state.copyWith(currentUrl: url);
  }

  void setNavigationState({
    required bool canGoBack,
    required bool canGoForward,
  }) {
    state = state.copyWith(
      canGoBack: canGoBack,
      canGoForward: canGoForward,
    );
  }

  void setLoading({required bool isLoading}) {
    state = state.copyWith(isLoading: isLoading);
  }

  /// Capture an image URL reported by the page's JS injection.
  void captureImage(String url, {int? width, int? height}) {
    state = state.copyWith(
      capturedImageUrl: url,
      capturedImageWidth: width,
      capturedImageHeight: height,
    );
  }

  void clearCapturedImage() {
    state = state.copyWith(clearCapturedImage: true);
  }

  void setError(String error) {
    state = state.copyWith(error: error);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}
