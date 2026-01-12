// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:capstone_app/data/repository/auth.repository.dart';
// import 'package:capstone_app/data/models/clinic_settings_model.dart';

// class EmailTemplateEditor extends StatefulWidget {
//   final ClinicSettings clinicSettings;
//   final VoidCallback onTemplateUpdated;
//   final bool hasStaffAccounts; // NEW: Check if clinic has any staff

//   const EmailTemplateEditor({
//     super.key,
//     required this.clinicSettings,
//     required this.onTemplateUpdated,
//     required this.hasStaffAccounts,
//   });

//   @override
//   State<EmailTemplateEditor> createState() => _EmailTemplateEditorState();
// }

// class _EmailTemplateEditorState extends State<EmailTemplateEditor> {
//   late TextEditingController _templateController;
//   bool _isEditing = false;
//   bool _isSaving = false;
//   String? _errorMessage;

//   static const Color primaryBlue = Color(0xFF4A6FA5);
//   static const Color primaryTeal = Color(0xFF5B9BD5);
//   static const Color vetGreen = Color(0xFF34D399);
//   static const Color mediumGray = Color(0xFF9CA3AF);
//   static const Color lightVetGreen = Color(0xFFE5F7E5);
//   static const Color vetOrange = Color(0xFFF59E0B);

//   @override
//   void initState() {
//     super.initState();
//     _templateController = TextEditingController(
//       text: widget.clinicSettings.staffEmailTemplate,
//     );
//   }

//   @override
//   void dispose() {
//     _templateController.dispose();
//     super.dispose();
//   }

//   bool get _isLocked => widget.hasStaffAccounts;

//   Future<void> _saveTemplate() async {
//     if (_isLocked) {
//       Get.snackbar(
//         'Template Locked',
//         'Email template cannot be changed after creating your first staff account',
//         snackPosition: SnackPosition.BOTTOM,
//         backgroundColor: vetOrange,
//         colorText: Colors.white,
//         icon: const Icon(Icons.lock, color: Colors.white),
//       );
//       return;
//     }

//     final newTemplate = _templateController.text.trim();

//     // Validate template
//     if (!_validateEmailTemplate(newTemplate)) {
//       return;
//     }

//     setState(() {
//       _isSaving = true;
//       _errorMessage = null;
//     });

//     try {
//       final authRepo = Get.find<AuthRepository>();

//       print('>>> Updating email template to: $newTemplate');

//       await authRepo.updateClinicSettingsEmailTemplate(
//         widget.clinicSettings.documentId!,
//         newTemplate,
//       );

//       Get.snackbar(
//         'Success',
//         'Email template updated successfully',
//         snackPosition: SnackPosition.BOTTOM,
//         backgroundColor: vetGreen,
//         colorText: Colors.white,
//         icon: const Icon(Icons.check_circle, color: Colors.white),
//         duration: const Duration(seconds: 3),
//       );

//       setState(() {
//         _isEditing = false;
//       });

//       widget.onTemplateUpdated();
//     } catch (e) {
//       setState(() {
//         _errorMessage = 'Failed to update template: $e';
//       });

//       Get.snackbar(
//         'Error',
//         'Failed to update email template: $e',
//         snackPosition: SnackPosition.BOTTOM,
//         backgroundColor: Colors.red,
//         colorText: Colors.white,
//         duration: const Duration(seconds: 5),
//       );
//     } finally {
//       setState(() {
//         _isSaving = false;
//       });
//     }
//   }

//   bool _validateEmailTemplate(String template) {
//     if (template.isEmpty) {
//       setState(() {
//         _errorMessage = 'Email template cannot be empty';
//       });
//       return false;
//     }

//     if (!template.contains('@')) {
//       setState(() {
//         _errorMessage = 'Template must contain @ symbol';
//       });
//       return false;
//     }

//     final parts = template.split('@');
//     if (parts.length != 2) {
//       setState(() {
//         _errorMessage = 'Template must have exactly one @ symbol';
//       });
//       return false;
//     }

//     final domain = parts[1];
//     if (!domain.contains('.')) {
//       setState(() {
//         _errorMessage = 'Domain must contain a dot (e.g., @clinic.vet)';
//       });
//       return false;
//     }

//     final domainParts = domain.split('.');
//     final extension = domainParts.last;

//     if (extension.length < 2 || extension.length > 6) {
//       setState(() {
//         _errorMessage =
//             'Domain extension must be 2-6 characters (e.g., .vet, .com)';
//       });
//       return false;
//     }

//     if (!RegExp(r'^[a-zA-Z]+$').hasMatch(extension)) {
//       setState(() {
//         _errorMessage = 'Domain extension must contain only letters';
//       });
//       return false;
//     }

//     return true;
//   }

//   String _generatePreview() {
//     final template = _templateController.text.trim();
//     if (template.isEmpty) return 'example@domain.vet';

//     if (template.startsWith('@')) {
//       return 'johndoe$template';
//     }

//     return template.replaceAll('{name}', 'john.doe');
//   }

//   void _showLockedInfo() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         title: Row(
//           children: [
//             Container(
//               padding: const EdgeInsets.all(8),
//               decoration: BoxDecoration(
//                 color: vetOrange.withOpacity(0.2),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: const Icon(Icons.lock, color: vetOrange, size: 24),
//             ),
//             const SizedBox(width: 12),
//             const Expanded(
//               child: Text(
//                 'Template Locked',
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//               ),
//             ),
//           ],
//         ),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'The email template is now locked and cannot be changed.',
//               style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
//             ),
//             const SizedBox(height: 16),
//             Container(
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: Colors.orange[50],
//                 borderRadius: BorderRadius.circular(8),
//                 border: Border.all(color: vetOrange.withOpacity(0.3)),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     children: [
//                       Icon(Icons.info_outline,
//                           size: 18, color: Colors.orange[800]),
//                       const SizedBox(width: 8),
//                       Text(
//                         'Why is it locked?',
//                         style: TextStyle(
//                           fontSize: 14,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.orange[800],
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 8),
//                   const Text(
//                     'Once your first staff account is created, the email template is permanently locked to maintain consistency across all staff accounts.',
//                     style: TextStyle(fontSize: 13, height: 1.4),
//                   ),
//                   const SizedBox(height: 12),
//                   const Text(
//                     'This ensures that all staff emails follow the same format and prevents confusion.',
//                     style: TextStyle(fontSize: 13, height: 1.4),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//         actions: [
//           ElevatedButton(
//             onPressed: () => Navigator.pop(context),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: primaryTeal,
//               foregroundColor: Colors.white,
//               padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(10),
//               ),
//             ),
//             child: const Text('Got It'),
//           ),
//         ],
//       ),
//     );
//   }

//   void _showTemplateGuidelines() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         title: Row(
//           children: [
//             Container(
//               padding: const EdgeInsets.all(8),
//               decoration: BoxDecoration(
//                 color: primaryTeal.withOpacity(0.2),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: const Icon(Icons.lightbulb_outline,
//                   color: primaryTeal, size: 24),
//             ),
//             const SizedBox(width: 12),
//             const Expanded(
//               child: Text(
//                 'Email Template Guide',
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//               ),
//             ),
//           ],
//         ),
//         content: SingleChildScrollView(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               _buildGuidelineItem(
//                 '1',
//                 'Represent Your Clinic',
//                 'Use your clinic name in the template. Example: If your clinic is "Paw Vet" use @paw.vet or @vet.paw',
//                 Icons.local_hospital,
//                 primaryBlue,
//               ),
//               const SizedBox(height: 16),
//               _buildGuidelineItem(
//                 '2',
//                 'Valid Format Required',
//                 'Domain must have 2-6 letters after the dot. Valid: @clinic.vet, @paw.com',
//                 Icons.check_circle,
//                 vetGreen,
//               ),
//               const SizedBox(height: 16),
//               _buildGuidelineItem(
//                 '3',
//                 'Lock After First Staff',
//                 'Template locks when you create your first staff account. Choose carefully!',
//                 Icons.lock_clock,
//                 vetOrange,
//               ),
//               const SizedBox(height: 20),
//               Container(
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: lightVetGreen.withOpacity(0.5),
//                   borderRadius: BorderRadius.circular(8),
//                   border: Border.all(color: primaryTeal.withOpacity(0.3)),
//                 ),
//                 child: const Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       children: [
//                         Icon(Icons.tips_and_updates,
//                             size: 18, color: primaryTeal),
//                         SizedBox(width: 8),
//                         Text(
//                           'Pro Tip',
//                           style: TextStyle(
//                             fontSize: 14,
//                             fontWeight: FontWeight.bold,
//                             color: primaryTeal,
//                           ),
//                         ),
//                       ],
//                     ),
//                     SizedBox(height: 8),
//                     Text(
//                       'Staff emails will be: staffname@yourtemplate\nExample: john.doe@paw.vet',
//                       style: TextStyle(fontSize: 13, height: 1.4),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//         actions: [
//           ElevatedButton(
//             onPressed: () => Navigator.pop(context),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: primaryTeal,
//               foregroundColor: Colors.white,
//               padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(10),
//               ),
//             ),
//             child: const Text('Got It'),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildGuidelineItem(
//     String number,
//     String title,
//     String description,
//     IconData icon,
//     Color color,
//   ) {
//     return Container(
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: color.withOpacity(0.3)),
//       ),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Container(
//             width: 32,
//             height: 32,
//             decoration: BoxDecoration(
//               color: color,
//               shape: BoxShape.circle,
//             ),
//             child: Center(
//               child: Text(
//                 number,
//                 style: const TextStyle(
//                   color: Colors.white,
//                   fontWeight: FontWeight.bold,
//                   fontSize: 16,
//                 ),
//               ),
//             ),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     Icon(icon, size: 18, color: color),
//                     const SizedBox(width: 6),
//                     Text(
//                       title,
//                       style: TextStyle(
//                         fontSize: 14,
//                         fontWeight: FontWeight.bold,
//                         color: color,
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 6),
//                 Text(
//                   description,
//                   style: const TextStyle(fontSize: 13, height: 1.4),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (!_isEditing) {
//       return _buildDisplayMode();
//     } else {
//       return _buildEditMode();
//     }
//   }

//   Widget _buildDisplayMode() {
//     String displayTemplate = widget.clinicSettings.staffEmailTemplate;
//     if (displayTemplate.contains('{name}')) {
//       displayTemplate = displayTemplate.replaceAll('{name}', '');
//     }

//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [
//             Colors.white,
//             _isLocked ? Colors.orange[50]! : lightVetGreen.withOpacity(0.3),
//           ],
//         ),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(
//           color: _isLocked
//               ? vetOrange.withOpacity(0.4)
//               : primaryTeal.withOpacity(0.3),
//           width: 2,
//         ),
//       ),
//       child: Row(
//         children: [
//           Container(
//             padding: const EdgeInsets.all(8),
//             decoration: BoxDecoration(
//               color: _isLocked
//                   ? vetOrange.withOpacity(0.2)
//                   : primaryTeal.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: Icon(
//               _isLocked ? Icons.lock : Icons.email,
//               color: _isLocked ? vetOrange : primaryTeal,
//               size: 20,
//             ),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     const Text(
//                       'Staff Email Template',
//                       style: TextStyle(
//                         fontSize: 12,
//                         color: mediumGray,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                     if (_isLocked) ...[
//                       const SizedBox(width: 8),
//                       Container(
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 8,
//                           vertical: 2,
//                         ),
//                         decoration: BoxDecoration(
//                           color: vetOrange.withOpacity(0.2),
//                           borderRadius: BorderRadius.circular(10),
//                           border: Border.all(
//                             color: vetOrange.withOpacity(0.5),
//                           ),
//                         ),
//                         child: Row(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             Icon(
//                               Icons.lock,
//                               size: 10,
//                               color: Colors.orange[800],
//                             ),
//                             const SizedBox(width: 4),
//                             Text(
//                               'LOCKED',
//                               style: TextStyle(
//                                 fontSize: 10,
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.orange[800],
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ],
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   displayTemplate,
//                   style: const TextStyle(
//                     fontSize: 14,
//                     fontWeight: FontWeight.bold,
//                     color: primaryBlue,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           if (_isLocked)
//             IconButton(
//               onPressed: _showLockedInfo,
//               icon: const Icon(Icons.info_outline, color: vetOrange, size: 20),
//               tooltip: 'Why is this locked?',
//             )
//           else
//             IconButton(
//               onPressed: () => setState(() => _isEditing = true),
//               icon: const Icon(Icons.edit, color: primaryTeal, size: 20),
//               tooltip: 'Edit template',
//             ),
//           IconButton(
//             onPressed: _showTemplateGuidelines,
//             icon: const Icon(Icons.help_outline, color: primaryTeal, size: 20),
//             tooltip: 'Template guidelines',
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildEditMode() {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: primaryTeal.withOpacity(0.3), width: 2),
//         boxShadow: [
//           BoxShadow(
//             color: primaryTeal.withOpacity(0.1),
//             blurRadius: 8,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Row(
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(8),
//                 decoration: BoxDecoration(
//                   color: primaryTeal.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child:
//                     const Icon(Icons.edit_note, color: primaryTeal, size: 20),
//               ),
//               const SizedBox(width: 12),
//               const Expanded(
//                 child: Text(
//                   'Edit Email Template',
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//               IconButton(
//                 onPressed: _showTemplateGuidelines,
//                 icon: const Icon(Icons.help_outline,
//                     color: primaryTeal, size: 20),
//                 tooltip: 'View guidelines',
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),
//           Container(
//             padding: const EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               color: Colors.blue[50],
//               borderRadius: BorderRadius.circular(8),
//               border: Border.all(color: primaryBlue.withOpacity(0.3)),
//             ),
//             child: Row(
//               children: [
//                 Icon(Icons.warning_amber_rounded,
//                     color: Colors.blue[700], size: 20),
//                 const SizedBox(width: 10),
//                 const Expanded(
//                   child: Text(
//                     'This template will lock after creating your first staff account',
//                     style: TextStyle(
//                       fontSize: 13,
//                       fontWeight: FontWeight.w600,
//                       height: 1.3,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: 16),
//           TextField(
//             controller: _templateController,
//             decoration: InputDecoration(
//               labelText: 'Email Template',
//               hintText: '@yourclinic.vet',
//               helperText: 'Format: @domain.extension (e.g., @paw.vet)',
//               helperMaxLines: 2,
//               prefixIcon: const Icon(Icons.alternate_email),
//               border: const OutlineInputBorder(),
//               focusedBorder: const OutlineInputBorder(
//                 borderSide: BorderSide(color: primaryTeal, width: 2),
//               ),
//             ),
//             onChanged: (_) => setState(() => _errorMessage = null),
//           ),
//           if (_errorMessage != null) ...[
//             const SizedBox(height: 8),
//             Container(
//               padding: const EdgeInsets.all(10),
//               decoration: BoxDecoration(
//                 color: Colors.red[50],
//                 borderRadius: BorderRadius.circular(8),
//                 border: Border.all(color: Colors.red.withOpacity(0.3)),
//               ),
//               child: Row(
//                 children: [
//                   const Icon(Icons.error_outline, color: Colors.red, size: 18),
//                   const SizedBox(width: 8),
//                   Expanded(
//                     child: Text(
//                       _errorMessage!,
//                       style: const TextStyle(color: Colors.red, fontSize: 13),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//           const SizedBox(height: 12),
//           Container(
//             padding: const EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               color: lightVetGreen.withOpacity(0.3),
//               borderRadius: BorderRadius.circular(8),
//               border: Border.all(color: primaryTeal.withOpacity(0.2)),
//             ),
//             child: Row(
//               children: [
//                 const Icon(Icons.visibility, color: primaryTeal, size: 18),
//                 const SizedBox(width: 8),
//                 const Text(
//                   'Preview: ',
//                   style: TextStyle(
//                     fontSize: 13,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//                 Text(
//                   _generatePreview(),
//                   style: const TextStyle(
//                     fontSize: 13,
//                     color: primaryBlue,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: 16),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.end,
//             children: [
//               TextButton(
//                 onPressed: _isSaving
//                     ? null
//                     : () {
//                         _templateController.text =
//                             widget.clinicSettings.staffEmailTemplate;
//                         setState(() {
//                           _isEditing = false;
//                           _errorMessage = null;
//                         });
//                       },
//                 child: const Text(
//                   'Cancel',
//                   style: TextStyle(color: mediumGray),
//                 ),
//               ),
//               const SizedBox(width: 12),
//               ElevatedButton.icon(
//                 onPressed: _isSaving ? null : _saveTemplate,
//                 icon: _isSaving
//                     ? const SizedBox(
//                         width: 16,
//                         height: 16,
//                         child: CircularProgressIndicator(
//                           strokeWidth: 2,
//                           color: Colors.white,
//                         ),
//                       )
//                     : const Icon(Icons.save, size: 18),
//                 label: Text(_isSaving ? 'Saving...' : 'Save Template'),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: primaryTeal,
//                   foregroundColor: Colors.white,
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 20,
//                     vertical: 12,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }
