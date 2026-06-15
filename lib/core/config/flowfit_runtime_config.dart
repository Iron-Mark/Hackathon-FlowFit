import 'package:flutter/foundation.dart';

/// Build-time runtime values that must line up with native app configuration.
class FlowFitRuntimeConfig {
  static const String authScheme = String.fromEnvironment(
    'FLOWFIT_AUTH_SCHEME',
    defaultValue: 'com.oldstlabs.flowfit',
  );

  static const String devAuthScheme = String.fromEnvironment(
    'FLOWFIT_DEV_AUTH_SCHEME',
    defaultValue: 'com.oldstlabs.flowfit.dev',
  );

  static const String supportEmail = String.fromEnvironment(
    'FLOWFIT_SUPPORT_EMAIL',
    defaultValue: 'support@flowfit.com',
  );

  static const String publicWebBaseUrl = String.fromEnvironment(
    'FLOWFIT_PUBLIC_WEB_BASE_URL',
    defaultValue: 'https://iron-mark.github.io/Hackathon-FlowFit',
  );

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
