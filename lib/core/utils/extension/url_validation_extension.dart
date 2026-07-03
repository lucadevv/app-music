extension UrlValidationExtension on String? {
  bool get isValidImageUrl {
    if (this == null) return false;
    final trimmed = this!.trim();
    if (trimmed.isEmpty) return false;
    return trimmed.startsWith('http://') || trimmed.startsWith('https://');
  }
}
