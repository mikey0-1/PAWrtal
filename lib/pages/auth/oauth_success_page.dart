import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:capstone_app/pages/routes/app_pages.dart';

class OAuthSuccessPage extends StatelessWidget {
  const OAuthSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Immediately redirect to callback handler
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.offNamed(Routes.oauthCallback);
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