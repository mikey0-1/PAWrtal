import 'package:capstone_app/web/pages/web_user_home/web_user_home_controller.dart';
import 'package:get/get.dart';

class WebUserHomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<WebUserHomeController>(
      () => WebUserHomeController(),
    );
  }
}