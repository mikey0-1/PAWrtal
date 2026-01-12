import 'package:capstone_app/mobile/admin/components/staff_account_tile.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:capstone_app/pages/admin_home/admin_home_controller.dart';

class StaffAccountsPage extends StatefulWidget {
  const StaffAccountsPage({super.key});

  @override
  State<StaffAccountsPage> createState() => _StaffAccountsPageState();
}

class _StaffAccountsPageState extends State<StaffAccountsPage> {
  final AdminHomeController controller = Get.find();


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 81, 115, 153),
      floatingActionButton: FloatingActionButton(
        onPressed: () => controller.moveToCreateStaff(),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 75, bottom: 20),
            child: Text(
              "Staff Account List",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 17,
              ),
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 230, 230, 230),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(25),
                  topRight: Radius.circular(25),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            cursorColor: Colors.grey,
                            decoration: InputDecoration(
                              fillColor: Colors.white,
                              filled: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(40),
                                borderSide: BorderSide.none,
                              ),
                              hintText: 'Search',
                              hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                              prefixIcon: Container(
                                width: 70,
                                height: 70,
                                padding: const EdgeInsets.all(15),
                                child: const Icon(Icons.search, color: Colors.grey),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          height: 50,
                          width: 50,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: IconButton(
                            iconSize: 25,
                            color: Colors.black,
                            icon: const Icon(Icons.sort),
                            onPressed: () {},
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: controller.obx(
                      (state) => ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        itemCount: state!.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () {
                              controller.moveToEditStaff(state[index]);
                            },
                            child: StaffAccountTile(staff: state[index]),
                          );
                        },
                      ),
                      onLoading: const Center(child: CircularProgressIndicator()),
                      onError: (error) => Center(child: Text(error ?? "An error occurred")),
                      onEmpty: const Center(child: Text('No staff found')),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
