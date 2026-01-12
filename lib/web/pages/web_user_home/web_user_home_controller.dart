import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class WebUserHomeController extends GetxController {
  final GetStorage _getStorage = GetStorage();
  
  final selectedIndex = 0.obs;
  final showMapView = false.obs; // ✨ NEW: Shared map view state

  void onItemSelected(int index) {
    selectedIndex.value = index;
  }

  // ✨ NEW: Toggle map view
  void toggleMapView() {
    showMapView.value = !showMapView.value;
  }

  // ✨ NEW: Set map view directly
  void setMapView(bool show) {
    showMapView.value = show;
  }

  String get userName {
    return _getStorage.read("userName") ?? "User";
  }

  String get userEmail {
    return _getStorage.read("email") ?? "";
  }

  String get userId {
    return _getStorage.read("userId") ?? "";
  }
}