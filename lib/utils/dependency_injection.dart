import 'package:capstone_app/mobile/admin/controllers/admin_messaging_controller.dart';
import 'package:capstone_app/mobile/user/components/dashboard_components/dashboard_controller.dart';
import 'package:capstone_app/mobile/user/controllers/user_messaging_controller.dart';
import 'package:capstone_app/notification/services/in_app_notification_service.dart';
import 'package:capstone_app/notification/services/notification_preferences_service.dart';
import 'package:capstone_app/notification/services/notification_service.dart';
import 'package:capstone_app/web/pages/web_user_home/web_user_home_controller.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:capstone_app/utils/user_session_service.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/data/provider/appwrite_provider.dart';
import 'package:capstone_app/web/super_admin/WebVersion/services/user_archive_service.dart';
import 'package:capstone_app/web/super_admin/WebVersion/services/clinic_archive_service.dart';

Future<void> initializeDependencies() async {
  await GetStorage.init();

  // 1. GetStorage
  if (!Get.isRegistered<GetStorage>()) {
    Get.put(GetStorage(), permanent: true);
  }

  // 2. AppWriteProvider
  Get.put(AppWriteProvider(), permanent: true);

  // 3. AuthRepository
  Get.put(AuthRepository(Get.find<AppWriteProvider>()), permanent: true);

  // 4. UserSessionService
  Get.put(UserSessionService(), permanent: true);

  // 5. Archive Services
  Get.put(
    ArchiveService(Get.find<AuthRepository>()),
    permanent: true,
  );
  Get.put(
    ClinicArchiveService(Get.find<AuthRepository>()),
    permanent: true,
  );

  // 6. Notification Services
  final notificationService = NotificationService();
  await notificationService.initializeNotifications();
  Get.put(notificationService, permanent: true);
  Get.put(
    InAppNotificationService(
      authRepository: Get.find<AuthRepository>(),
      session: Get.find<UserSessionService>(),
    ),
    permanent: true,
  );
  Get.put(
    NotificationPreferencesService(
      authRepository: Get.find<AuthRepository>(),
    ),
    permanent: true,
  );

  // 7. Controllers
  Get.put(DashboardController());
  Get.put(MessagingController());
  Get.put(AdminMessagingController());
  Get.put(WebUserHomeController(), permanent: true);

  // 8. Migrations
  await Get.find<AuthRepository>()
      .appWriteProvider
      .migrateReviewsArchiveField();
  await Get.find<AuthRepository>().migrateFeedbackArchiveField();
}