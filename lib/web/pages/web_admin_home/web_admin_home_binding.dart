import 'package:capstone_app/web/pages/web_admin_home/web_admin_home_controller.dart';
import 'package:get/get.dart';

class WebAdminHomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<WebAdminHomeController>(
      () => WebAdminHomeController(),
    );
  }
}
