import 'platform_html_stub.dart'
    if (dart.library.html) 'platform_html_web.dart'
    if (dart.library.io) 'platform_html_mobile.dart';

/// Platform-agnostic HTML helper
/// Automatically uses the correct implementation based on platform
class PlatformHtmlHelper {
  static PlatformHtmlInterface get instance => getPlatformHtml();
}

/// Interface that both implementations must follow
abstract class PlatformHtmlInterface {
  String getBaseUrl();
  void redirectToUrl(String url);
}