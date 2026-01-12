import 'package:capstone_app/utils/snackbar_helper.dart';
import 'package:capstone_app/utils/user_session_service.dart';
import 'package:get/get.dart';
import 'package:capstone_app/data/models/pet_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/utils/custom_snack_bar.dart';

class PetsController extends GetxController {
  final AuthRepository authRepository;
  final UserSessionService session;

  PetsController({required this.authRepository, required this.session});

  RxList<Pet> pets = <Pet>[].obs;
  RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchUserPets();
  }

  Future<void> fetchUserPets() async {
    isLoading.value = true;
    try {
      final userId = session.userId;
      final petDocs = await authRepository.getUserPets(userId);
      pets.value = petDocs.map((doc) => Pet.fromMap(doc.data)).toList();
    } catch (e) {
      SnackbarHelper.showError(
        context: Get.overlayContext,
        title: "Error",
        message: "Failed to fetch pets: $e",
      );
    } finally {
      isLoading.value = false;
    }
  }

  void fetchPets() {
    fetchUserPets();
  }
}
