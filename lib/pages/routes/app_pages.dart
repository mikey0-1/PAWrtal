import 'package:capstone_app/mobile/admin/pages/staff_account_creation/staff_account_binding.dart';
import 'package:capstone_app/mobile/admin/pages/staff_account_creation/staff_account_creation_page.dart';
import 'package:capstone_app/pages/admin_home/admin_home_binding.dart';
import 'package:capstone_app/pages/admin_home/admin_home_page.dart';
import 'package:capstone_app/pages/auth/oauth_callback_page.dart';
import 'package:capstone_app/pages/auth/oauth_failure_page.dart';
import 'package:capstone_app/pages/auth/oauth_success_page.dart';
import 'package:capstone_app/pages/landing/landing_binding.dart';
import 'package:capstone_app/pages/landing/landing_page.dart';
import 'package:capstone_app/pages/landing/web_landing_page.dart';
import 'package:capstone_app/pages/reset_password/reset_password_binding.dart';
import 'package:capstone_app/pages/reset_password/reset_password_page.dart';
import 'package:capstone_app/pages/super_admin_home/super_admin_home_binding.dart';
import 'package:capstone_app/pages/super_admin_home/super_admin_home_page.dart';
import 'package:capstone_app/pages/user_home/user_home_binding.dart';
import 'package:capstone_app/pages/user_home/user_home_page.dart';
import 'package:capstone_app/pages/login/login_binding.dart';
import 'package:capstone_app/pages/login/login_page.dart';
import 'package:capstone_app/pages/signup/signup_binding.dart';
import 'package:capstone_app/pages/signup/signup_page.dart';
import 'package:capstone_app/pages/splash/splash_binding.dart';
import 'package:capstone_app/pages/splash/splash_page.dart';
import 'package:capstone_app/pages/vet_clinic_registration/vet_clinic_registration_binding.dart';
import 'package:capstone_app/pages/vet_clinic_registration/vet_clinic_registration_page.dart';

// Web imports
import 'package:capstone_app/web/pages/web_login/web_login_binding.dart';
import 'package:capstone_app/web/pages/web_login/web_login_page.dart';
import 'package:capstone_app/web/pages/web_signup/web_sign_up_page.dart';
import 'package:capstone_app/web/pages/web_signup/web_signup_binding.dart';
import 'package:capstone_app/web/pages/web_user_home/web_user_home_binding.dart';
import 'package:capstone_app/web/pages/web_user_home/web_user_home_page.dart';
import 'package:capstone_app/web/pages/web_admin_home/web_admin_home_binding.dart';
import 'package:capstone_app/web/pages/web_admin_home/web_admin_home_page.dart';
import 'package:capstone_app/web/pages/web_super_admin_home/web_super_admin_home_binding.dart';
import 'package:capstone_app/web/pages/web_super_admin_home/web_super_admin_home_page.dart';

// Staff imports - ADD THESE
import 'package:capstone_app/web/admin_web/components/staffs/staff_main_wrapper.dart';
import 'package:capstone_app/data/provider/appwrite_provider.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/utils/user_session_service.dart';
import 'package:capstone_app/web/super_admin/WebVersion/pet_owners_pages/user_page.dart';
import 'package:capstone_app/web/super_admin/WebVersion/vet_clinic_pages/veterinary_clinics/super_ad_vet_clinic_dashboard.dart';
import 'package:capstone_app/web/super_admin/WebVersion/vet_clinic_requests/vet_clinic_requests_dashboard.dart';
import 'package:capstone_app/web/super_admin/WebVersion/view_report/user_app_feedback/app_feedback.dart';

// SECURITY: Import middleware
import 'package:capstone_app/middleware/route_guard.dart';
import 'package:capstone_app/middleware/auth_middleware.dart';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const initial = Routes.splash;

  static final routes = [
    // Splash - No security needed
    GetPage(
      name: _Paths.splash,
      page: () => const SplashPage(),
      binding: SplashBinding(),
    ),

    GetPage(
      name: _Paths.landing,
      page: () => kIsWeb ? const WebLandingPage() : const LandingPage(),
      binding: LandingBinding(),
      // No middleware - public access
    ),

    // Login - Public route
    GetPage(
      name: _Paths.login,
      page: () => kIsWeb ? const WebLoginPage() : const LoginPage(),
      binding: kIsWeb ? WebLoginBinding() : LoginBinding(),
      // No middleware - public access
    ),

    // Signup - Public route
    GetPage(
      name: _Paths.signup,
      page: () => kIsWeb ? const WebSignUpPage() : const SignUpPage(),
      binding: kIsWeb ? WebSignUpBinding() : SignUpBinding(),
      // No middleware - public access
    ),

    // PROTECTED ROUTES - User Home
    GetPage(
      name: _Paths.userHome,
      page: () => kIsWeb ? const WebUserHomePage() : const UserHomePage(),
      binding: kIsWeb ? WebUserHomeBinding() : UserHomeBinding(),
      middlewares: [
        RouteGuard(), // Checks authentication and role
        AuthMiddleware(), // Validates session
      ],
    ),

    // PROTECTED ROUTES - Admin Home
    GetPage(
      name: _Paths.adminHome,
      page: () => kIsWeb ? const WebAdminHomePage() : const WebAdminHomePage(),
      binding: kIsWeb ? WebAdminHomeBinding() : WebAdminHomeBinding(),
      middlewares: [
        RouteGuard(), // Checks if user is admin or staff
        AuthMiddleware(), // Validates session
      ],
    ),

    // PROTECTED ROUTES - Super Admin Home
    GetPage(
      name: _Paths.superAdminHome,
      page: () =>
          kIsWeb ? const WebSuperAdminHomePage() : const SuperAdminHomePage(),
      binding: kIsWeb ? WebSuperAdminHomeBinding() : SuperAdminHomeBinding(),
      middlewares: [
        RouteGuard(), // Checks if user is developer
        AuthMiddleware(), // Validates session
      ],
    ),

    // PROTECTED ROUTES - Create Staff (Admin only)
    GetPage(
      name: _Paths.createStaff,
      page: () => const StaffAccountCreationPage(),
      binding: CreateStaffBinding(),
      middlewares: [
        RouteGuard(), // Admin only
        AuthMiddleware(),
      ],
    ),

    // PROTECTED ROUTES - Staff Home
    GetPage(
      name: _Paths.staffHome,
      page: () => const StaffMainWrapper(),
      binding: BindingsBuilder(() {
        Get.lazyPut<AppWriteProvider>(() => AppWriteProvider());
        Get.lazyPut<AuthRepository>(
            () => AuthRepository(Get.find<AppWriteProvider>()));
        Get.lazyPut<UserSessionService>(() => UserSessionService());
      }),
      middlewares: [
        RouteGuard(), // Staff only
        AuthMiddleware(),
      ],
    ),

    // Super Admin - Clinics
    GetPage(
      name: '/super-admin/clinics',
      page: () => const SuperAdminVetClinicDashboard(),
      binding: SuperAdminHomeBinding(),
      middlewares: [
        RouteGuard(),
        AuthMiddleware(),
      ],
    ),

    // Super Admin - Users
    GetPage(
      name: '/super-admin/users',
      page: () => const SuperAdminUserManagementScreen(),
      middlewares: [
        RouteGuard(),
        AuthMiddleware(),
      ],
    ),

    // Super Admin - Feedback
    GetPage(
      name: '/super-admin/feedback',
      page: () => const AdminFeedbackManagement(),
      middlewares: [
        RouteGuard(),
        AuthMiddleware(),
      ],
    ),

    // OAuth Callback - Public route (handles Google OAuth redirect)
    GetPage(
      name: Routes.oauthCallback,
      page: () => const OAuthCallbackPage(),
      // No middleware - public access for OAuth callback
    ),

    GetPage(
      name: Routes.oauthFailure,
      page: () => const OAuthFailurePage(),
      // No middleware - public access
    ),

    GetPage(
        name: Routes.resetPassword,
        page: () => const ResetPasswordPage(),
        binding: ResetPasswordBinding(),
        transition: Transition.fadeIn
        // No middleware - public access for password reset
        ),

    GetPage(
        name: Routes.vetClinicRegistration,
        page: () => const VetClinicRegistrationPage(),
        binding: VetClinicRegistrationBinding(),
        transition: Transition.fadeIn),

    GetPage(
      name: '/vet-clinic-requests',
      page: () => const VetClinicRequestsDashboard(),
    ),
  ];
}
