import 'package:capstone_app/web/super_admin/WebVersion/vet_clinic_pages/veterinary_clinics/super_ad_vet_clinic_page.dart';
import 'package:flutter/material.dart';

class StaffMember {
//  final String id;
  final String name;
  // final String role;
  final String email;
  final String phone;
//  final String password;
  final DateTime joinDate;
//  final String department;
  final bool isActive;

  StaffMember({
    //  required this.id,
    required this.name,
    //  required this.role,
    required this.email,
    required this.phone,
    // required this.password,
    required this.joinDate,
    //required this.department,
    required this.isActive,
  });
}

class CrudeStaffAccount extends StatefulWidget {
  const CrudeStaffAccount({super.key});
  @override
  State<CrudeStaffAccount> createState() => _CrudeStaffAccountState();
}

class _CrudeStaffAccountState extends State<CrudeStaffAccount> {
  final buttonColor = const Color.fromRGBO(81, 115, 153, 0.8);

  List<StaffMember> staffMembers = [
    StaffMember(
      //  id: 'VET001',
      name: 'Dr. Sarah Johnson',
      // role: 'Senior Veterinarian',
      email: 'sarah.johnson@vetclinic.com',
      phone: '+1-555-0123',
      //  password: '••••••••',
      joinDate: DateTime(2020, 3, 15),
      //   department: 'Surgery',
      isActive: true,
    ),
    StaffMember(
      // id: 'VET002',
      name: 'Mike Rodriguez',
      // role: 'Veterinary Technician',
      email: 'mike.rodriguez@vetclinic.com',
      phone: '+1-555-0124',
      //   password: '••••••••',
      joinDate: DateTime(2021, 7, 22),
      //   department: 'General Care',
      isActive: true,
    ),
    StaffMember(
      //  id: 'VET003',
      name: 'Emily Chen',
      //  role: 'Receptionist',
      email: 'emily.chen@vetclinic.com',
      phone: '+1-555-0125',
      //  password: '••••••••',
      joinDate: DateTime(2022, 1, 10),
      //   department: 'Administration',
      isActive: true,
    ),
    StaffMember(
      // id: 'VET004',
      name: 'Dr. James Wilson',
      //  role: 'Veterinarian',
      email: 'james.wilson@vetclinic.com',
      phone: '+1-555-0126',
      // password: '••••••••',
      joinDate: DateTime(2019, 11, 5),
      // department: 'Emergency',
      isActive: false,
    ),
    StaffMember(
      //id: 'VET005',
      name: 'Lisa Thompson',
      // role: 'Veterinary Assistant',
      email: 'lisa.thompson@vetclinic.com',
      phone: '+1-555-0127',
      //  password: '••••••••',
      joinDate: DateTime(2023, 4, 18),
      //   department: 'General Care',
      isActive: true,
    ),
  ];

  String searchQuery = '';
  String selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(253, 253, 255, 1),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back,
              color: Color.fromARGB(255, 81, 115, 153)),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const SuperAdminVetClinicPage()),
            );
          },
          tooltip: 'Back',
        ),
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Staff Account Management',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color.fromRGBO(81, 115, 153, 1),
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromRGBO(249, 253, 255, 1),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              setState(() {
                // Refresh the staff list
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Staff list refreshed')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Header Section with Search and Filter
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color.fromRGBO(249, 253, 255, 1),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                    decoration: const InputDecoration(
                      hintText: 'Search staff members...',
                      prefixIcon: Icon(Icons.search, color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                // Filter Dropdown
                Row(
                  children: [
                    const Text(
                      'Filter by: ',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            dropdownColor:
                                const Color.fromRGBO(249, 253, 255, 1),
                            value: selectedFilter,
                            onChanged: (String? newValue) {
                              setState(() {
                                selectedFilter = newValue!;
                              });
                            },
                            items: <String>[
                              'All',
                              'Active',
                              'Inactive',
                              'Veterinarian',
                              'Technician',
                              'Assistant',
                              'Receptionist'
                            ].map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Stats Section
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Staff',
                    staffMembers.length.toString(),
                    Icons.people,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildStatCard(
                    'Active Staff',
                    staffMembers.where((s) => s.isActive).length.toString(),
                    Icons.person,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildStatCard(
                    'Inactive Staff',
                    staffMembers.where((s) => !s.isActive).length.toString(),
                    Icons.person_off,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ),

          // Staff List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: getFilteredStaff().length,
              itemBuilder: (context, index) {
                final staff = getFilteredStaff()[index];
                return _buildStaffCard(staff);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffCard(StaffMember staff) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            staff.isActive
                ? Colors.green.withOpacity(0.05)
                : Colors.red.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: staff.isActive
              ? Colors.green.withOpacity(0.2)
              : Colors.red.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                // CircleAvatar(
                //   radius: 25,
                //   backgroundColor: _getRoleColor(staff.role),
                //   child: Text(
                //     staff.name.split(' ').map((e) => e[0]).join(''),
                //     style: const TextStyle(
                //       color: Colors.white,     ROLE AVATAR
                //       fontWeight: FontWeight.bold,
                //     ),
                //   ),
                // ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        staff.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color.fromRGBO(81, 115, 153, 1),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Container(
                      //   padding: const EdgeInsets.symmetric(
                      //       horizontal: 12, vertical: 4),
                      //   decoration: BoxDecoration(
                      //     color: _getRoleColor(staff.role),
                      //     borderRadius: BorderRadius.circular(12),
                      //   ),
                      //   child: Text(     //ROLE
                      //     staff.role,
                      //     style: const TextStyle(
                      //       color: Colors.white,
                      //       fontSize: 12,
                      //       fontWeight: FontWeight.w600,
                      //     ),
                      //   ),
                      // ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: staff.isActive ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    staff.isActive ? 'Active' : 'Inactive',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Staff Information Grid
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  //    _buildInfoRow('ID', staff.id, Icons.badge),
                  // const Divider(height: 20),
                  _buildInfoRow('Email', staff.email, Icons.email),
                  const Divider(height: 20),
                  _buildInfoRow('Phone', staff.phone, Icons.phone),
                  // const Divider(height: 20),
                  // _buildInfoRow('Password', staff.password, Icons.lock),
                  // const Divider(height: 20),
                  //   _buildInfoRow('Department', staff.department, Icons.business),
                  const Divider(height: 20),
                  _buildInfoRow(
                      'Join Date',
                      '${staff.joinDate.day}/${staff.joinDate.month}/${staff.joinDate.year}',
                      Icons.calendar_today),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const SizedBox(width: 10),
                SizedBox(
                  width: 110,
                  child: ElevatedButton.icon(
                    onPressed: () => _deleteStaff(staff),
                    icon: const Icon(Icons.delete, color: Colors.white),
                    label: const Text('Delete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color.fromRGBO(81, 115, 153, 1)),
        const SizedBox(width: 10),
        Text(
          '$label:',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Color.fromRGBO(81, 115, 153, 1),
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Color.fromRGBO(81, 115, 153, 1),
            ),
          ),
        ),
      ],
    );
  }

  // Color _getRoleColor(String role) {
  //   switch (role.toLowerCase()) {
  //     case 'senior veterinarian':
  //       return Colors.purple;
  //     case 'veterinarian':
  //       return Colors.blue;
  //     case 'veterinary technician':
  //       return Colors.green;
  //     case 'veterinary assistant':
  //       return Colors.orange;
  //     case 'receptionist':
  //       return Colors.teal;
  //     default:
  //       return Colors.grey;
  //   }
  // }

  List<StaffMember> getFilteredStaff() {
    return staffMembers.where((staff) {
      // Search filter
      bool matchesSearch = searchQuery.isEmpty ||
          staff.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          //   staff.role.toLowerCase().contains(searchQuery.toLowerCase()) ||
          staff.email.toLowerCase().contains(searchQuery.toLowerCase());
      //   staff.id.toLowerCase().contains(searchQuery.toLowerCase())

      // Role filter
      bool matchesFilter = selectedFilter == 'All' ||
          (selectedFilter == 'Active' && staff.isActive) ||
          (selectedFilter == 'Inactive' && !staff.isActive);
      //staff.role.toLowerCase().contains(selectedFilter.toLowerCase());

      return matchesSearch && matchesFilter;
    }).toList();
  }

  void _viewStaffDetails(StaffMember staff) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color.fromRGBO(249, 253, 255, 1),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              // CircleAvatar(
              //   backgroundColor: _getRoleColor(staff.role),
              //   child: Text(     ROLE
              //     staff.name.split(' ').map((e) => e[0]).join(''),
              //     style: const TextStyle(
              //         color: Colors.white, fontWeight: FontWeight.bold),
              //   ),
              // ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  staff.name,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color.fromRGBO(81, 115, 153, 1)),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                //_buildDetailItem('Staff ID', staff.id),
                // _buildDetailItem('Role', staff.role),
                _buildDetailItem('Email', staff.email),
                _buildDetailItem('Phone', staff.phone),
                //_buildDetailItem('Department', staff.department),
                _buildDetailItem('Join Date',
                    '${staff.joinDate.day}/${staff.joinDate.month}/${staff.joinDate.year}'),
                _buildDetailItem(
                    'Status', staff.isActive ? 'Active' : 'Inactive'),
                //  _buildDetailItem('Password', staff.password),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close', style: TextStyle(color: buttonColor)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color.fromRGBO(81, 115, 153, 1)),
            ),
          ),
          Expanded(
              child: Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: Color.fromRGBO(81, 115, 153, 1),
            ),
          )),
        ],
      ),
    );
  }

  void _deleteStaff(StaffMember staff) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color.fromRGBO(249, 253, 255, 1),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Delete Staff Member'),
          content: Text(
              'Are you sure you want to delete ${staff.name}? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: TextStyle(color: buttonColor)),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  staffMembers.remove(staff);
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text('${staff.name} has been deleted successfully'),
                    backgroundColor: Colors.red,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child:
                  const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
