import 'package:capstone_app/data/models/staff_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/pages/admin_home/admin_home_controller.dart';
import 'package:capstone_app/pages/routes/app_pages.dart';
import 'package:capstone_app/utils/appwrite_constant.dart';
import 'package:capstone_app/utils/custom_snack_bar.dart';
import 'package:capstone_app/utils/full_screen_dialog_loader.dart';
import 'package:capstone_app/utils/snackbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';

class CreateStaffController extends GetxController {
  AuthRepository authRepository;
  CreateStaffController(this.authRepository);

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  TextEditingController nameEditingController = TextEditingController();
  TextEditingController departmentEditingController = TextEditingController();

  final GetStorage _getStorage = GetStorage();
  
  final ImagePicker _picker = ImagePicker();
  
  var imagePath = ''.obs;
  var imageUrl = ''.obs;
  var isEdit = false.obs;
  
  Staff? staff;

  bool isFormValid = false;


  @override
  void onReady() async {
    super.onReady();
    
    final args = Get.arguments;
    
    if (args != null && args is Map<String, dynamic>) {
      staff = args['staff'] as Staff?;
      
      if (staff != null) {
        isEdit.value = true;

        nameEditingController.text = staff?.name ?? '';
        departmentEditingController.text = staff?.department ?? '';
        
        String currentImage = args['currentImage'] ?? '';
        
        imageUrl.value = currentImage.isNotEmpty
            ? '${AppwriteConstants.endPoint}/storage/buckets/${AppwriteConstants.imageBucketID}/files/$currentImage/view?project=${AppwriteConstants.projectID}'
            : 'https://via.placeholder.com/150';
      }
    } else {
      debugPrint("Error: Staff argument is null");
    }
  }

  @override
  void onClose() {
    super.onClose();
    nameEditingController.dispose();
    departmentEditingController.dispose();
  }

  void clearTextEditingControllers() {
    nameEditingController.clear();
    departmentEditingController.clear();
  }

  String? validateName(String value) {
    if (value.isEmpty) {
      return "Provide a valid name";
    }
    return null;
  }

  String? validateDepartment(String value) {
    if (value.isEmpty) {
      return "Provide a valid department";
    }
    return null;
  }

  void selectImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      imagePath.value = image.path;
    } else {
      SnackbarHelper.showError(
        context: Get.overlayContext,
        title: "Error",
        message: "Image selection cancelled",
      );
    }
  }

  void validateAndSave({
    required String name,
    required String department,
    required bool isEdit,
    String? documentId,
    String? currentImage,
  }) async {
    isFormValid = formKey.currentState!.validate();

    if (!isFormValid) return;

    formKey.currentState!.save();

    try {
      FullScreenDialogLoader.showDialog();

      String? newImageId;

      // upload new image only if selected
      if (imagePath.isNotEmpty) {
        final imageResponse = await authRepository.uploadImage(imagePath.value);
        newImageId = imageResponse.$id;
      }

      // delete the old image only if editing and new image is uploaded
      if (isEdit && newImageId != null && staff != null && staff!.image.isNotEmpty) {
        await authRepository.deleteImage(staff!.image);
      }

      // use current image reference if no new image is uploaded
      String imageToUse = newImageId ?? currentImage ?? '';

      // handle staff creation
      if (!isEdit) {
        await authRepository.createStaff({
          "name": name,
          "department": department,
          "createdBy": _getStorage.read("userId"),
          "image": imageToUse,  
          "createdAt": DateTime.now().toIso8601String(),
        });

        FullScreenDialogLoader.cancelDialog();
        SnackbarHelper.showSuccess(
          context: Get.overlayContext,
          title: "Success",
          message: "Staff created successfully",
        );

        Get.find<AdminHomeController>().getStaff();
        Get.offNamedUntil(Routes.adminHome, (route) => route.isFirst);
        return;
      }

      // ensure document ID is provided for updating
      if (documentId == null || documentId.isEmpty) {
        FullScreenDialogLoader.cancelDialog();
        SnackbarHelper.showError(
          context: Get.overlayContext,
          title: "Error",
          message: "Document ID is missing",
        );
        return;
      }

      // update existing staff
      await authRepository.updateStaff({
        "documentId": documentId,
        "name": name,
        "department": department,
        "createdBy": _getStorage.read("userId"),
        "image": imageToUse,
      });

      FullScreenDialogLoader.cancelDialog();
      SnackbarHelper.showSuccess(
        context: Get.overlayContext,
        title: "Success",
        message: "Staff updated successfully",
      );

      Get.find<AdminHomeController>().getStaff();
      Get.offNamedUntil(Routes.adminHome, (route) => route.isFirst);
    } catch (e) {
      FullScreenDialogLoader.cancelDialog();
      SnackbarHelper.showError(
        context: Get.overlayContext,
        title: "Error",
        message: "Failed to update staff: $e",
      );
    }
  }
}
