class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'SIBA_API_BASE_URL',
    defaultValue: 'https://siba.escsoftware.com.mx/api/mobile/v1',
  );
  static const bool enablePush = bool.fromEnvironment('SIBA_ENABLE_PUSH', defaultValue: false);

  static Uri uri(String path, [Map<String, dynamic>? query]) {
    final cleanBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final cleanPath = path.startsWith('/') ? path : '/$path';
    final uri = Uri.parse('$cleanBase$cleanPath');
    if (uri.scheme != 'https' || uri.host.isEmpty) {
      throw StateError('Configura SIBA_API_BASE_URL con la URL HTTPS de SIBA.');
    }
    if (query == null || query.isEmpty) return uri;
    return uri.replace(
      queryParameters: query.map(
        (key, value) => MapEntry(key, value?.toString() ?? ''),
      ),
    );
  }
  static String get logoUrl => uri('/').resolve('/img/siba-web-logo.png').toString();
}
