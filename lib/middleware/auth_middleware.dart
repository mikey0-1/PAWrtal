import 'package:capstone_app/utils/logout_helper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:capstone_app/pages/routes/app_pages.dart';

class AuthMiddleware extends GetMiddleware {
  final GetStorage _storage = GetStorage();

  @override
  int? get priority => 2; // Runs after RouteGuard

  @override
  RouteSettings? redirect(String? route) {
    return null; // No redirect, just validation
  }

  @override
  GetPage? onPageCalled(GetPage? page) {
    // Skip validation for public pages
    if (page?.name == Routes.landing ||
        page?.name == Routes.login || 
        page?.name == Routes.signup || 
        page?.name == Routes.splash) {
      return page;
    }

    // CRITICAL FIX: Check if logout is in progress
    // If so, DON'T validate session - let logout complete
    if (LogoutHelper.isLoggingOut.value) {
      return page;
    }

    // REMOVED: Session validation that causes race conditions
    // The automatic session validation and timeout has been removed
    // to prevent conflicts with manual logout and FCM token cleanup
    
    return page;
  }

  // REMOVED: _validateSession() method
  // REMOVED: _handleInvalidSession() method
  // These caused race conditions during logout and prevented proper FCM cleanup
}