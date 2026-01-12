// import 'package:flutter/material.dart';

// class PreVerificationDialog extends StatefulWidget {
//   final String accountName;
//   final VoidCallback onConfirmAndProceed;
//   final VoidCallback onUpdateName;
//   final VoidCallback onCancel;

//   const PreVerificationDialog({
//     Key? key,
//     required this.accountName,
//     required this.onConfirmAndProceed,
//     required this.onUpdateName,
//     required this.onCancel,
//   }) : super(key: key);

//   @override
//   State<PreVerificationDialog> createState() => _PreVerificationDialogState();
// }

// class _PreVerificationDialogState extends State<PreVerificationDialog> {
//   bool _hasConfirmed = false;

//   @override
//   Widget build(BuildContext context) {
//     return AlertDialog(
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(20),
//       ),
//       title: Column(
//         children: [
//           Container(
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: const Color(0xFF1976D2).withOpacity(0.1),
//               shape: BoxShape.circle,
//             ),
//             child: const Icon(
//               Icons.verified_user_rounded,
//               size: 48,
//               color: Color(0xFF1976D2),
//             ),
//           ),
//           const SizedBox(height: 16),
//           const Text(
//             'ID Verification',
//             style: TextStyle(
//               fontSize: 24,
//               fontWeight: FontWeight.bold,
//             ),
//             textAlign: TextAlign.center,
//           ),
//         ],
//       ),
//       content: SingleChildScrollView(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Important notice
//             Container(
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: const Color(0xFFFFF3E0),
//                 borderRadius: BorderRadius.circular(12),
//                 border: Border.all(
//                   color: const Color(0xFFFF9800),
//                   width: 2,
//                 ),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     children: [
//                       const Icon(
//                         Icons.warning_rounded,
//                         color: Color(0xFFFF9800),
//                         size: 24,
//                       ),
//                       const SizedBox(width: 8),
//                       const Expanded(
//                         child: Text(
//                           'Important',
//                           style: TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                             color: Color(0xFFFF9800),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 12),
//                   const Text(
//                     'Your account name MUST match the name on your government-issued ID exactly.',
//                     style: TextStyle(
//                       fontSize: 15,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 20),
            
//             // Current account name
//             Container(
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: Colors.blue.shade50,
//                 borderRadius: BorderRadius.circular(12),
//                 border: Border.all(
//                   color: const Color(0xFF1976D2),
//                   width: 1,
//                 ),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     children: [
//                       const Icon(
//                         Icons.person_outline,
//                         color: Color(0xFF1976D2),
//                         size: 20,
//                       ),
//                       const SizedBox(width: 8),
//                       const Text(
//                         'Your Account Name:',
//                         style: TextStyle(
//                           fontSize: 14,
//                           fontWeight: FontWeight.bold,
//                           color: Color(0xFF1976D2),
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 8),
//                   Padding(
//                     padding: const EdgeInsets.only(left: 28),
//                     child: Text(
//                       widget.accountName,
//                       style: const TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 20),
            
//             // Requirements checklist
//             const Text(
//               'Before proceeding, ensure:',
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 12),
//             _buildCheckItem('Your account name matches your ID name exactly'),
//             _buildCheckItem('You have a valid government-issued ID (National ID, Passport, or Driver\'s License)'),
//             _buildCheckItem('Your ID is not expired'),
//             _buildCheckItem('Your ID photo is clear and readable'),
//             const SizedBox(height: 20),
            
//             // Warning about one-time verification
//             Container(
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: Colors.red.shade50,
//                 borderRadius: BorderRadius.circular(8),
//                 border: Border.all(
//                   color: Colors.red.shade300,
//                   width: 1,
//                 ),
//               ),
//               child: Row(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Icon(
//                     Icons.info_outline,
//                     color: Colors.red.shade700,
//                     size: 20,
//                   ),
//                   const SizedBox(width: 8),
//                   Expanded(
//                     child: Text(
//                       'You can only verify once. If verification fails due to name mismatch, you must update your account name before trying again.',
//                       style: TextStyle(
//                         fontSize: 13,
//                         color: Colors.red.shade700,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 20),
            
//             // Confirmation checkbox
//             Container(
//               decoration: BoxDecoration(
//                 color: Colors.grey.shade100,
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: CheckboxListTile(
//                 value: _hasConfirmed,
//                 onChanged: (value) {
//                   setState(() {
//                     _hasConfirmed = value ?? false;
//                   });
//                 },
//                 title: const Text(
//                   'I confirm that my account name matches my government ID',
//                   style: TextStyle(
//                     fontSize: 14,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//                 activeColor: const Color(0xFF1976D2),
//                 controlAffinity: ListTileControlAffinity.leading,
//               ),
//             ),
//           ],
//         ),
//       ),
//       actions: [
//         TextButton(
//           onPressed: widget.onCancel,
//           child: const Text(
//             'Cancel',
//             style: TextStyle(color: Colors.grey),
//           ),
//         ),
//         TextButton.icon(
//           onPressed: widget.onUpdateName,
//           icon: const Icon(Icons.edit_outlined, size: 18),
//           label: const Text('Update Name'),
//           style: TextButton.styleFrom(
//             foregroundColor: const Color(0xFF1976D2),
//           ),
//         ),
//         ElevatedButton.icon(
//           onPressed: _hasConfirmed ? widget.onConfirmAndProceed : null,
//           icon: const Icon(Icons.arrow_forward, size: 18),
//           label: const Text('Proceed to Verification'),
//           style: ElevatedButton.styleFrom(
//             backgroundColor: const Color(0xFF1976D2),
//             foregroundColor: Colors.white,
//             disabledBackgroundColor: Colors.grey.shade300,
//             disabledForegroundColor: Colors.grey.shade600,
//             padding: const EdgeInsets.symmetric(
//               horizontal: 20,
//               vertical: 12,
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildCheckItem(String text) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 8),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Icon(
//             Icons.check_circle_outline,
//             color: Color(0xFF4CAF50),
//             size: 20,
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Text(
//               text,
//               style: const TextStyle(fontSize: 14),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// /// Show pre-verification dialog before starting ARGOS verification
// Future<bool?> showPreVerificationDialog({
//   required BuildContext context,
//   required String accountName,
//   required VoidCallback onUpdateName,
// }) async {
//   return showDialog<bool>(
//     context: context,
//     barrierDismissible: false,
//     builder: (BuildContext context) {
//       return PreVerificationDialog(
//         accountName: accountName,
//         onConfirmAndProceed: () {
//           Navigator.of(context).pop(true);
//         },
//         onUpdateName: () {
//           Navigator.of(context).pop(false);
//           onUpdateName();
//         },
//         onCancel: () {
//           Navigator.of(context).pop(null);
//         },
//       );
//     },
//   );
// }