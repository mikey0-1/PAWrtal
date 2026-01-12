import 'package:capstone_app/mobile/admin/pages/staff_details_page.dart';
import 'package:flutter/material.dart';
import 'package:capstone_app/utils/appwrite_constant.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';

class StaffAccountTile extends StatelessWidget {
  final dynamic staff;

  const StaffAccountTile({super.key, required this.staff});

  void _staffDetailsPopUp(dynamic staffData) {
    showModalBottomSheet(
      context: Get.context!,
      builder: (ctx) => StaffDetailsPage(staffData: staffData),
      isScrollControlled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    String imageUrl = (staff.image != null && staff.image.isNotEmpty)
        ? '${AppwriteConstants.endPoint}/storage/buckets/${AppwriteConstants.imageBucketID}/files/${staff.image}/view?project=${AppwriteConstants.projectID}'
        : ''; // placeholder image

    return GestureDetector(
      onTap: () => _staffDetailsPopUp(staff),
      child: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              // staff Image
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: SizedBox(
                  width: 75,
                  height: 75,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(60),
                    child: imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            fit: BoxFit.cover,
                            imageUrl: imageUrl,
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.red),
                          )
                        : Image.asset(
                            'assets/images/placeholder.png', // local placeholder
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
              ),

              // staff name and department
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 10, top: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        staff.name ?? 'Unknown',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          staff.department ?? 'Unknown',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          "Authorities: ",
                          style: TextStyle(
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
