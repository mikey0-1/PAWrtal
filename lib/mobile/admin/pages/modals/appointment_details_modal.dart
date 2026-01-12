// import 'package:capstone_app/data/models/appointment_model.dart';
// import 'package:capstone_app/mobile/admin/controllers/enhanced_clinic_appointment_controller.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:intl/intl.dart';

// class AppointmentDetailsModal extends StatelessWidget {
//   final Appointment appointment;

//   const AppointmentDetailsModal({
//     super.key,
//     required this.appointment,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final controller = Get.find<EnhancedClinicAppointmentController>();
    
//     return Container(
//       height: MediaQuery.of(context).size.height * 0.8,
//       decoration: const BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.only(
//           topLeft: Radius.circular(25),
//           topRight: Radius.circular(25),
//         ),
//       ),
//       child: Column(
//         children: [
//           // Handle bar
//           Container(
//             width: 40,
//             height: 4,
//             margin: const EdgeInsets.symmetric(vertical: 12),
//             decoration: BoxDecoration(
//               color: Colors.grey[300],
//               borderRadius: BorderRadius.circular(2),
//             ),
//           ),
//           // Header
//           Padding(
//             padding: const EdgeInsets.all(20),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 const Text(
//                   'Appointment Details',
//                   style: TextStyle(
//                     fontSize: 22,
//                     fontWeight: FontWeight.bold,
//                     color: Color.fromARGB(255, 81, 115, 153),
//                   ),
//                 ),
//                 Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                   decoration: BoxDecoration(
//                     color: _getStatusColor(appointment.status),
//                     borderRadius: BorderRadius.circular(20),
//                   ),
//                   child: Text(
//                     appointment.status.toUpperCase(),
//                     style: const TextStyle(
//                       color: Colors.white,
//                       fontSize: 12,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           Expanded(
//             child: SingleChildScrollView(
//               padding: const EdgeInsets.symmetric(horizontal: 20),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Owner Information Card
//                   _buildInfoCard(
//                     'Pet Owner Information',
//                     Icons.person,
//                     [
//                       _buildDetailRow(
//                         Icons.person_outline,
//                         'Owner Name',
//                         controller.getOwnerName(appointment.userId),
//                       ),
//                       // Add more owner details if available
//                     ],
//                   ),
//                   const SizedBox(height: 16),
//                   // Pet Information Card
//                   _buildInfoCard(
//                     'Pet Information',
//                     Icons.pets,
//                     [
//                       _buildDetailRow(
//                         Icons.pets,
//                         'Pet Name',
//                         controller.getPetName(appointment.petId),
//                       ),
//                       _buildDetailRow(
//                         Icons.category,
//                         'Type',
//                         controller.getPetType(appointment.petId),
//                       ),
//                       _buildDetailRow(
//                         Icons.pets_outlined,
//                         'Breed',
//                         controller.getPetBreed(appointment.petId),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 16),
//                   // Appointment Information Card
//                   _buildInfoCard(
//                     'Appointment Information',
//                     Icons.schedule,
//                     [
//                       _buildDetailRow(
//                         Icons.calendar_today,
//                         'Date',
//                         DateFormat('EEEE, MMMM dd, yyyy').format(appointment.dateTime),
//                       ),
//                       _buildDetailRow(
//                         Icons.access_time,
//                         'Time',
//                         DateFormat('hh:mm a').format(appointment.dateTime),
//                       ),
//                       _buildDetailRow(
//                         Icons.medical_services,
//                         'Service',
//                         appointment.service,
//                       ),
//                       if (appointment.notes != null && appointment.notes!.isNotEmpty)
//                         _buildDetailRow(
//                           Icons.note,
//                           'Notes',
//                           appointment.notes!,
//                         ),
//                       _buildDetailRow(
//                         Icons.history,
//                         'Created',
//                         DateFormat('MMM dd, yyyy • hh:mm a').format(appointment.createdAt),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 24),
//                 ],
//               ),
//             ),
//           ),
//           // Action Buttons (only for pending appointments)
//           if (appointment.status == 'pending')
//             Container(
//               padding: const EdgeInsets.all(20),
//               decoration: BoxDecoration(
//                 color: Colors.grey[50],
//                 borderRadius: const BorderRadius.only(
//                   topLeft: Radius.circular(20),
//                   topRight: Radius.circular(20),
//                 ),
//               ),
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: ElevatedButton(
//                       onPressed: () {
//                         Navigator.pop(context);
//                         _showConfirmDialog(
//                           context,
//                           'Decline Appointment',
//                           'Are you sure you want to decline this appointment?',
//                           () => controller.declineAppointment(appointment),
//                         );
//                       },
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.red,
//                         foregroundColor: Colors.white,
//                         padding: const EdgeInsets.symmetric(vertical: 16),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                       ),
//                       child: const Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Icon(Icons.close, size: 20),
//                           SizedBox(width: 8),
//                           Text('Decline', style: TextStyle(fontWeight: FontWeight.bold)),
//                         ],
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: ElevatedButton(
//                       onPressed: () {
//                         Navigator.pop(context);
//                         _showConfirmDialog(
//                           context,
//                           'Accept Appointment',
//                           'Are you sure you want to accept this appointment?',
//                           () => controller.acceptAppointment(appointment),
//                         );
//                       },
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.green,
//                         foregroundColor: Colors.white,
//                         padding: const EdgeInsets.symmetric(vertical: 16),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                       ),
//                       child: const Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Icon(Icons.check, size: 20),
//                           SizedBox(width: 8),
//                           Text('Accept', style: TextStyle(fontWeight: FontWeight.bold)),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             )
//           else
//             // Contact Owner Button for accepted appointments
//             if (appointment.status == 'accepted')
//               Container(
//                 padding: const EdgeInsets.all(20),
//                 child: SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton(
//                     onPressed: () {
//                       // TODO: Implement contact functionality
//                       Get.snackbar("Info", "Contact functionality coming soon!");
//                     },
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: const Color.fromARGB(255, 81, 115, 153),
//                       foregroundColor: Colors.white,
//                       padding: const EdgeInsets.symmetric(vertical: 16),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                     ),
//                     child: const Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Icon(Icons.phone, size: 20),
//                         SizedBox(width: 8),
//                         Text('Contact Owner', style: TextStyle(fontWeight: FontWeight.bold)),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//         ],
//       ),
//     );
//   }

//   Widget _buildInfoCard(String title, IconData icon, List<Widget> children) {
//     return Container(
//       width: double.infinity,
//       decoration: BoxDecoration(
//         color: Colors.grey[50],
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: Colors.grey[200]!),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Icon(
//                   icon,
//                   color: const Color.fromARGB(255, 81, 115, 153),
//                   size: 20,
//                 ),
//                 const SizedBox(width: 8),
//                 Text(
//                   title,
//                   style: const TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                     color: Color.fromARGB(255, 81, 115, 153),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 12),
//             ...children,
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildDetailRow(IconData icon, String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 8),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Icon(
//             icon,
//             size: 16,
//             color: Colors.grey[600],
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   label,
//                   style: TextStyle(
//                     fontSize: 12,
//                     color: Colors.grey[600],
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//                 const SizedBox(height: 2),
//                 Text(
//                   value,
//                   style: const TextStyle(
//                     fontSize: 14,
//                     color: Colors.black87,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Color _getStatusColor(String status) {
//     switch (status.toLowerCase()) {
//       case 'accepted':
//         return Colors.green;
//       case 'declined':
//         return Colors.red;
//       case 'pending':
//         return Colors.orange;
//       default:
//         return Colors.grey;
//     }
//   }

//   void _showConfirmDialog(
//     BuildContext context,
//     String title,
//     String content,
//     VoidCallback onConfirm,
//   ) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(16),
//           ),
//           title: Text(
//             title,
//             style: const TextStyle(
//               fontWeight: FontWeight.bold,
//               color: Color.fromARGB(255, 81, 115, 153),
//             ),
//           ),
//           content: Text(content),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.of(context).pop(),
//               child: const Text(
//                 'Cancel',
//                 style: TextStyle(color: Colors.grey),
//               ),
//             ),
//             ElevatedButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//                 onConfirm();
//               },
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: const Color.fromARGB(255, 81, 115, 153),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//               ),
//               child: const Text(
//                 'Confirm',
//                 style: TextStyle(color: Colors.white),
//               ),
//             ),
//           ],
//         );
//       },
//     );
//   }
// }