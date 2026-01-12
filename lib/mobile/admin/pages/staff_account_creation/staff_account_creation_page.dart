import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:capstone_app/mobile/admin/pages/staff_account_creation/staff_account_controller.dart';
import 'package:capstone_app/data/models/staff_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/utils/appwrite_constant.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class StaffAccountCreationPage extends StatefulWidget {
  const StaffAccountCreationPage({super.key});

  @override
  State<StaffAccountCreationPage> createState() =>
      _StaffAccountCreationPageState();
}

class _StaffAccountCreationPageState extends State<StaffAccountCreationPage> {
  final CreateStaffController controller =
      CreateStaffController(Get.find<AuthRepository>());

  Staff? staff;

  @override
  void initState() {
    super.initState();

    final args = Get.arguments;

    if (args != null && args is Map<String, dynamic>) {
      staff = args['staff'] as Staff?;

      // load current image reference if available
      String currentImage = args['currentImage'] ?? '';

      controller.isEdit.value = true;
      controller.nameEditingController.text = staff?.name ?? '';
      controller.departmentEditingController.text = staff?.department ?? '';

      // use current image reference or placeholder
      controller.imageUrl.value = currentImage.isNotEmpty
          ? '${AppwriteConstants.endPoint}/storage/buckets/${AppwriteConstants.imageBucketID}/files/$currentImage/view?project=${AppwriteConstants.projectID}'
          : 'https://via.placeholder.com/150';
    }
  }

  bool pageAuth = false;
  bool appointmentsAuth = false;
  bool messagesAuth = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 81, 115, 153),
      body: ListView(
        physics: const NeverScrollableScrollPhysics(),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 10, top: 20),
            child: Row(
              children: [
                IconButton.filledTonal(
                  icon: const Icon(Icons.arrow_downward_outlined),
                  color: Colors.white,
                  style: IconButton.styleFrom(
                    iconSize: 25,
                    minimumSize: const Size(5, 5),
                    backgroundColor: Colors.transparent,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 50),
            child: Text(
              "Staff Account Creation",
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 17),
            ),
          ),
          Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            decoration: const BoxDecoration(
              color: Color.fromARGB(255, 230, 230, 230),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(25),
                topRight: Radius.circular(25),
              ),
            ),
            child: SingleChildScrollView(
              child: Form(
                key: controller.formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  children: [
                    const SizedBox(
                      height: 40,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 40, right: 50, bottom: 500),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Obx(() => !controller.isEdit.value
                                  ? (controller.imagePath.value == ''
                                      ? const Text(
                                          'Select Image from Gallery',
                                          style: TextStyle(fontSize: 20),
                                        )
                                      : CircleAvatar(
                                          radius: 80,
                                          backgroundImage: FileImage(
                                            File(controller.imagePath.value),
                                          ),
                                        ))
                                  : (controller.imagePath.value != ''
                                      ? CircleAvatar(
                                          radius: 80,
                                          backgroundImage: FileImage(
                                            File(controller.imagePath.value),
                                          ),
                                        )
                                      : CachedNetworkImage(
                                          imageUrl: controller
                                                  .imageUrl.value.isNotEmpty
                                              ? controller.imageUrl.value
                                              : 'https://via.placeholder.com/150',
                                          width: 100,
                                          height: 100,
                                          errorWidget: (context, url, error) =>
                                              const Icon(Icons.error),
                                        ))),
                              IconButton(
                                icon: const Icon(Icons.image),
                                onPressed: () {
                                  controller.selectImage();
                                },
                              )
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 20),
                            child: Container(
                              alignment: Alignment.centerLeft,
                              child: Column(
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.all(5.0),
                                    child: Align(
                                      alignment: Alignment.topLeft,
                                      child: Text(
                                        'Name *',
                                        style: TextStyle(
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                  ),
                                  TextFormField(
                                      decoration: InputDecoration(
                                        hintText: 'ex. David Pogi',
                                        labelStyle: const TextStyle(
                                          color: Colors.black,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: const BorderSide(
                                            color: Color.fromARGB(
                                                255, 81, 115, 153),
                                          ),
                                        ),
                                      ),
                                      keyboardType: TextInputType.text,
                                      controller:
                                          controller.nameEditingController,
                                      validator: (value) {
                                        return controller.validateName(value!);
                                      }),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 20),
                            child: Container(
                              alignment: Alignment.centerLeft,
                              child: Column(
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.all(5.0),
                                    child: Align(
                                      alignment: Alignment.topLeft,
                                      child: Text(
                                        'Department *',
                                        style: TextStyle(
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                  ),
                                  TextFormField(
                                      decoration: InputDecoration(
                                        hintText: 'ex. Veterinary',
                                        labelStyle: const TextStyle(
                                          color: Colors.black,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: const BorderSide(
                                            color: Color.fromARGB(
                                                255, 81, 115, 153),
                                          ),
                                        ),
                                      ),
                                      keyboardType: TextInputType.text,
                                      controller: controller
                                          .departmentEditingController,
                                      validator: (value) {
                                        return controller
                                            .validateDepartment(value!);
                                      }),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          const Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              'Authorities *',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          Column(
                            children: [
                              Row(
                                children: [
                                  Checkbox(
                                    value: pageAuth,
                                    onChanged: (value) {
                                      setState(
                                        () {
                                          pageAuth = value!;
                                        },
                                      );
                                    },
                                  ),
                                  const Text('Veterinary Clinic Page'),
                                ],
                              ),
                              Row(
                                children: [
                                  Checkbox(
                                    value: appointmentsAuth,
                                    onChanged: (value) {
                                      setState(
                                        () {
                                          appointmentsAuth = value!;
                                        },
                                      );
                                    },
                                  ),
                                  const Text('Appointment List'),
                                ],
                              ),
                              Row(
                                children: [
                                  Checkbox(
                                    value: messagesAuth,
                                    onChanged: (value) {
                                      setState(
                                        () {
                                          messagesAuth = value!;
                                        },
                                      );
                                    },
                                  ),
                                  const Text('Messages'),
                                ],
                              ),
                            ],
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromARGB(255, 81, 115, 153),
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              controller.validateAndSave(
                                name: controller.nameEditingController.text,
                                department:
                                    controller.departmentEditingController.text,
                                isEdit: controller.isEdit.value,
                                documentId: staff?.documentId ?? '',
                                currentImage: Get.arguments != null ? Get.arguments['currentImage'] : null,
                                // staffId: widget.staff?.id, // pass ID if editing
                              );
                            },
                            child: Text(
                                controller.isEdit.value ? 'Update' : 'Create'),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
