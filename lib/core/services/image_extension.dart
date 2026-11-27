const Set<String> _kImageExtensions = <String>{
  'png',
  'jpg',
  'jpeg',
  'webp',
  'gif',
  'bmp',
};

/// The extension a copied user image is saved under; anything unknown becomes
/// `png` so a crafted name cannot leave the target folder.
String sanitizeImageExtension(String ext) {
  final String clean = ext.toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '');
  return _kImageExtensions.contains(clean) ? clean : 'png';
}
