// // rejected_page.dart (or declined_page.dart)
// import 'package:capstone_app/mobile/admin/controllers/enhanced_clinic_appointment_controller.dart';
// import 'package:capstone_app/mobile/admin/components/appointment_tiles/enhanced_clinic_appointment_tile.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:intl/intl.dart';

// class RejectedPage extends StatelessWidget {
//   const RejectedPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final controller = Get.find<EnhancedClinicAppointmentController>();

//     return Scaffold(
//       backgroundColor: const Color.fromARGB(255, 230, 230, 230),
//       body: Obx(() {
//         if (controller.isLoading.value) {
//           return const Center(child: CircularProgressIndicator());
//         }

//         final declinedAppointments = controller.declined; // Now this getter exists

//         if (declinedAppointments.isEmpty) {
//           return _buildEmptyState();
//         }

//         return RefreshIndicator(
//           onRefresh: () => controller.refreshAppointments(),
//           child: Column(
//             children: [
//               // Declined appointments info banner
//               Container(
//                 width: double.infinity,
//                 margin: const EdgeInsets.all(16),
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     colors: [Colors.red, Colors.red.shade300],
//                     begin: Alignment.topLeft,
//                     end: Alignment.bottomRight,
//                   ),
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Row(
//                   children: [
//                     const Icon(
//                       Icons.cancel,
//                       color: Colors.white,
//                       size: 24,
//                     ),
//                     const SizedBox(width: 12),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           const Text(
//                             'Declined Appointments',
//                             style: TextStyle(
//                               color: Colors.white,
//                               fontWeight: FontWeight.bold,
//                               fontSize: 16,
//                             ),
//                           ),
//                           Text(
//                             '${declinedAppointments.length} appointment${declinedAppointments.length > 1 ? 's' : ''} declined',
//                             style: TextStyle(
//                               color: Colors.white.withOpacity(0.9),
//                               fontSize: 12,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     Container(
//                       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                       decoration: BoxDecoration(
//                         color: Colors.white.withOpacity(0.2),
//                         borderRadius: BorderRadius.circular(16),
//                       ),
//                       child: const Text(
//                         'DECLINED',
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontWeight: FontWeight.bold,
//                           fontSize: 10,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
              
//               // Appointments List
//               Expanded(
//                 child: ListView.builder(
//                   padding: const EdgeInsets.symmetric(vertical: 8),
//                   itemCount: declinedAppointments.length,
//                   itemBuilder: (context, index) {
//                     final appointment = declinedAppointments[index];
//                     return Column(
//                       children: [
//                         PatientWorkflowTile(
//                           appointment: appointment,
//                           workflowStage: 'declined',
//                         ),
//                         // Show decline date
//                         Container(
//                           margin: const EdgeInsets.symmetric(horizontal: 16),
//                           padding: const EdgeInsets.all(8),
//                           decoration: BoxDecoration(
//                             color: Colors.red.shade50,
//                             borderRadius: BorderRadius.circular(8),
//                             border: Border.all(color: Colors.red.shade200),
//                           ),
//                           child: Row(
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               Icon(
//                                 Icons.schedule,
//                                 size: 16,
//                                 color: Colors.red[700],
//                               ),
//                               const SizedBox(width: 4),
//                               Text(
//                                 'Declined: ${DateFormat('MMM dd, hh:mm a').format(appointment.updatedAt)}',
//                                 style: TextStyle(
//                                   fontSize: 12,
//                                   color: Colors.red[700],
//                                   fontWeight: FontWeight.w500,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     );
//                   },
//                 ),
//               ),
//             ],
//           ),
//         );
//       }),
//     );
//   }

//   Widget _buildEmptyState() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             Icons.cancel_outlined,
//             size: 80,
//             color: Colors.grey[400],
//           ),
//           const SizedBox(height: 16),
//           Text(
//             'No Declined Appointments',
//             style: TextStyle(
//               fontSize: 20,
//               fontWeight: FontWeight.bold,
//               color: Colors.grey[600],
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'Declined appointments will appear here.\nThis helps track appointment history.',
//             style: TextStyle(
//               fontSize: 14,
//               color: Colors.grey[500],
//             ),
//             textAlign: TextAlign.center,
//           ),
//         ],
//       ),
//     );
//   }
// }