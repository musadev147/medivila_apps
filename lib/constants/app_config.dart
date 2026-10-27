class AppConfig {
  AppConfig._();

  static const String appName = 'মেডিভিলা (Medivila)';
  static const String appSlogan = 'আপনার নির্ভরযোগ্য অনলাইন ফার্মেসি ও স্বাস্থ্যসেবা';
  static const String helplinePhone = '+8801625491153';
  static const String supportEmail = 'medivila.com@gmail.com';
  static const String logoAsset = 'assets/images/playstore.png';

  /// Primary API base URL as specified in MOBILE_APP_API_DOCUMENTATION.md
  static const String apiBaseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://api.medivila.com/api',
  );

  static final String apiUrl =
      apiBaseUrl.endsWith('/') ? apiBaseUrl.substring(0, apiBaseUrl.length - 1) : apiBaseUrl;

  /// Server root (API base minus `/api`), used to complete `/storage/...` image paths.
  static final String baseUrl = apiUrl.endsWith('/api') ? apiUrl.substring(0, apiUrl.length - 4) : apiUrl;

  static const String storageUrl = 'https://api.medivila.com/storage';
  static const String defaultImageFallback = 'https://api.medivila.com/medivila-default.jpg';

  /// Poll interval for the unread-notification badge while the app is open.
  static const Duration unreadPoll = Duration(seconds: 60);

  /// Standardized Medivila image resolver algorithm as specified in API documentation
  static String resolveImageUrl(String? rawPath) {
    if (rawPath == null || rawPath.trim().isEmpty) {
      return defaultImageFallback;
    }
    final clean = rawPath.trim();
    if (clean.startsWith('http://') || clean.startsWith('https://')) {
      return clean;
    }
    final normalized = clean.replaceAll(RegExp(r'^/+'), '');
    if (normalized.startsWith('images/') || normalized.startsWith('storage/')) {
      return 'https://api.medivila.com/$normalized';
    }
    return '$storageUrl/$normalized';
  }

  /// Bangladeshi Phone Number Validation: ^01[3-9]\d{8}$
  static bool isValidBdPhone(String? phone) {
    if (phone == null) return false;
    final clean = phone.replaceAll(RegExp(r'[\s\-+88]'), '');
    return RegExp(r'^01[3-9]\d{8}$').hasMatch(clean);
  }

  /// Clean Bangladeshi Phone Number (e.g. removes +88, spaces)
  static String cleanBdPhone(String phone) {
    var p = phone.replaceAll(RegExp(r'[\s\-]'), '');
    if (p.startsWith('+88')) p = p.substring(3);
    if (p.startsWith('88')) p = p.substring(2);
    return p;
  }
}
