import 'package:web/web.dart' as html;
import 'platform_html_helper.dart';

class PlatformHtmlWeb implements PlatformHtmlInterface {
  @override
  String getBaseUrl() {
    return html.window.location.origin;
  }

  @override
  void redirectToUrl(String url) {
    html.window.location.href = url;
  }
}

PlatformHtmlInterface getPlatformHtml() => PlatformHtmlWeb();