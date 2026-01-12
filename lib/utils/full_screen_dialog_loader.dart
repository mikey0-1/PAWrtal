import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FullScreenDialogLoader {
  static void showDialog() {
    Get.dialog(
      // ignore: deprecated_member_use
      WillPopScope(
        child: const Center(
          child: CircularProgressIndicator(),
          ),
          onWillPop: () => Future.value(false),
          ),
          barrierDismissible: false,
          barrierColor: Colors.pink.withOpacity(0.2),
          useSafeArea: true,
    );
  }

  static void cancelDialog() {
    if (Get.isDialogOpen ?? false){
      Get.back();
    }
  }
}