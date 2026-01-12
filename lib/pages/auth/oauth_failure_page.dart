import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:capstone_app/pages/routes/app_pages.dart';

class OAuthFailurePage extends StatelessWidget {
  const OAuthFailurePage({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      
      Get.offAllNamed(Routes.login);
      
      Get.snackbar(
        'Sign In Cancelled',
        'Google Sign-In was cancelled or failed. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.shade100,
        colorText: Colors.orange.shade900,
        duration: const Duration(seconds: 4),
      );
    });

    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            Color.fromARGB(255, 81, 115, 153),
          ),
        ),
      ),
    );
  }
}