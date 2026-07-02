import 'package:flutter/foundation.dart';

/// Build-time runtime values that must line up with native app configuration.
class FlowFitRuntimeConfig {
  static const String authScheme = String.fromEnvironment(
    'FLOWFIT_AUTH_SCHEME',
    defaultValue: 'com.msiazondev.flowfit',
  );

  static const String devAuthScheme = String.fromEnvironment(
    'FLOWFIT_DEV_AUTH_SCHEME',
    defaultValue: 'com.msiazondev.flowfit.dev',
  );

  static const String supportEmail = String.fromEnvironment(
    'FLOWFIT_SUPPORT_EMAIL',
    defaultValue: 'marksiazon.dev@gmail.com',
  );

  static const String publicWebBaseUrl = String.fromEnvironment(
    'FLOWFIT_PUBLIC_WEB_BASE_URL',
    defaultValue: 'https://iron-mark.github.io/Hackathon-FlowFit',
  );

  static const String apkDownloadUrl = String.fromEnvironment(
    'FLOWFIT_APK_DOWNLOAD_URL',
    defaultValue:
        'https://github.com/Iron-Mark/Hackathon-FlowFit/releases/latest',
  );

  static const String mapTileUrlTemplate = String.fromEnvironment(
    'FLOWFIT_MAP_TILE_URL_TEMPLATE',
    defaultValue:
        'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
  );

  static const String _mapTileSubdomains = String.fromEnvironment(
    'FLOWFIT_MAP_TILE_SUBDOMAINS',
    defaultValue: 'a,b,c',
  );

  static List<String> get mapTileSubdomains => _mapTileSubdomains
      .split(',')
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toList(growable: false);

  static String mapTileUrl({
    required int x,
    required int y,
    required int zoom,
  }) {
    final subdomains = mapTileSubdomains;
    final subdomain = subdomains.isEmpty
        ? ''
        : subdomains[(x + y) % subdomains.length];

    return mapTileUrlTemplate
        .replaceAll('{s}', subdomain)
        .replaceAll('{z}', zoom.toString())
        .replaceAll('{x}', x.toString())
        .replaceAll('{y}', y.toString());
  }

  static String authRedirectUrl({bool isDevelopment = false}) {
    if (kIsWeb) {
      final webOrigin = _currentWebOrigin();
      if (webOrigin != null) {
        return webOrigin;
      }
    }

    final scheme = isDevelopment ? devAuthScheme : authScheme;
    return '$scheme://auth-callback';
  }

  static String? _currentWebOrigin() {
    final base = Uri.base;
    if (base.scheme != 'http' && base.scheme != 'https') {
      return null;
    }
    return '${base.scheme}://${base.authority}';
  }
}
