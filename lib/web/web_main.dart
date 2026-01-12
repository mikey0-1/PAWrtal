import 'package:capstone_app/pages/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics();
  }
}

class WebMain extends StatelessWidget {
  const WebMain({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      scrollBehavior: MyCustomScrollBehavior(),
      initialRoute: AppPages.initial,
      getPages: AppPages.routes,
      
      // SECURITY: Enhanced 404 handler with proper redirection
      unknownRoute: GetPage(
        name: '/not-found',
        page: () => const NotFoundPage(),
      ),
      
      // Default transition
      defaultTransition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}

/// Enhanced 404 Page with security-aware redirection
class NotFoundPage extends StatelessWidget {
  const NotFoundPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(40),
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 100,
                color: Colors.red,
              ),
              const SizedBox(height: 30),
              const Text(
                '404 - Page Not Found',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                'The page you are looking for does not exist or you do not have permission to access it.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: () {
                  final storage = GetStorage();
                  final role = storage.read('role');
                  final userId = storage.read('userId');
                  
                  
                  if (role != null && userId != null) {
                    // User is logged in - redirect to their home
                    switch (role) {
                      case 'admin':
                      case 'staff':
                        Get.offAllNamed('/adminHome');
                        break;
                      case 'developer':
                        Get.offAllNamed('/superAdminHome');
                        break;
                      case 'user':
                      case 'customer':
                      default:
                        Get.offAllNamed('/userHome');
                    }
                  } else {
                    // No valid session - go to login
                    storage.erase(); // Clear any invalid data
                    Get.offAllNamed('/login');
                  }
                },
                icon: const Icon(Icons.home),
                label: const Text('Go to Home'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}