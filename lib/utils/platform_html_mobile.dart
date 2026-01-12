import 'platform_html_helper.dart';

class PlatformHtmlMobile implements PlatformHtmlInterface {
  @override
  String getBaseUrl() {
    // Not used on mobile, return app scheme
    return 'pawrtal://';
  }

  @override
  void redirectToUrl(String url) {
    // Not used on mobile
  }
}

PlatformHtmlInterface getPlatformHtml() => PlatformHtmlMobile();