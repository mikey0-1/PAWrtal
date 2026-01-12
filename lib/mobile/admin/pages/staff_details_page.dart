import 'package:capstone_app/pages/admin_home/admin_home_controller.dart';
import 'package:capstone_app/utils/appwrite_constant.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';

class StaffDetailsPage extends StatefulWidget {
  final dynamic staffData;

  const StaffDetailsPage({super.key, required this.staffData});

  @override
  State<StaffDetailsPage> createState() => _StaffDetailsPageState();
}

class _StaffDetailsPageState extends State<StaffDetailsPage> {
  final AdminHomeController controller = Get.find();

  bool pageAuth = false;
  bool appointmentsAuth = false;
  bool messagesAuth = false;

  @override
  Widget build(BuildContext context) {
    String imageUrl = (widget.staffData.image != null &&
            widget.staffData.image.isNotEmpty)
        ? '${AppwriteConstants.endPoint}/storage/buckets/${AppwriteConstants.imageBucketID}/files/${widget.staffData.image}/view?project=${AppwriteConstants.projectID}'
        : ''; // trigger local placeholder

    return Material(
      color: const Color.fromARGB(255, 81, 115, 153),
      child: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 10, top: 30),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_downward_outlined,
                      color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                Padding(
                  padding: const EdgeInsets.only(),
                  child: Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          controller.deleteStaff(widget.staffData);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // profile picture
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(70),
                child: imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        imageUrl: imageUrl,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(),
                        ),
                        errorWidget: (context, url, error) => Image.asset(
                          'assets/images/placeholder.png', // local placeholder
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Image.asset(
                        'assets/images/placeholder.png', // fallback for empty URL
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
              ),
            ),
          ),

          // Staff details
          Container(
            width: MediaQuery.of(context).size.width,
            decoration: const BoxDecoration(
              color: Color.fromARGB(255, 230, 230, 230),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(25),
                topRight: Radius.circular(25),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // edit button
                  Center(
                    child: IconButton(
                        onPressed: () {
                          controller.moveToEditStaff(widget.staffData);
                        },
                        icon: const Icon(Icons.edit, color: Colors.lightBlue)),
                  ),

                  // name
                  Center(
                    child: Text(
                      widget.staffData.name ?? 'Unknown',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // phone number
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 5, bottom: 10),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.phone, color: Colors.lightBlue, size: 20),
                          SizedBox(width: 5),
                          Text(
                            "0995 123 4567",
                            style: TextStyle(fontSize: 13, color: Colors.black),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Divider(),
                  const SizedBox(height: 20),

                  // email and password
                  buildInfoRow(
                      "Email Address", "email" /*widget.staffData.email*/),
                  buildInfoRow(
                      "Password", "*******" /*widget.staffData.address*/),
                  const SizedBox(height: 20),

                  // authorities section
                  const Text(
                    'Authorities',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  buildCheckbox("Veterinary Clinic Page", pageAuth),
                  buildCheckbox("Appointment List", appointmentsAuth),
                  buildCheckbox("Messages", messagesAuth),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // method for staff info display
  Widget buildInfoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 5),
          Text(value,
              style: const TextStyle(color: Colors.black, fontSize: 14)),
        ],
      ),
    );
  }

  // authority checkbox
  Widget buildCheckbox(String title, bool value) {
    return Row(
      children: [
        Checkbox(
          value: value,
          onChanged: (newValue) {
            setState(() {
              value = newValue!;
            });
          },
        ),
        Text(title, style: const TextStyle(color: Colors.black, fontSize: 14)),
      ],
    );
  }
}
