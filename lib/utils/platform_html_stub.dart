import 'platform_html_helper.dart';

class PlatformHtmlStub implements PlatformHtmlInterface {
  @override
  String getBaseUrl() {
    throw UnimplementedError('Platform not supported');
  }

  @override
  void redirectToUrl(String url) {
    throw UnimplementedError('Platform not supported');
  }
}

PlatformHtmlInterface getPlatformHtml() => PlatformHtmlStub();