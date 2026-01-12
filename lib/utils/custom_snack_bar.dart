// import 'package:flutter/material.dart';
// import 'package:get/get.dart';

// class CustomToast {
//   static OverlayEntry? _currentOverlay;
//   static bool _isShowing = false;

//   /// Show error toast notification
//   static void showErrorSnackBar({
//     required BuildContext? context,
//     required String title,
//     required String message,
//     Duration? duration,
//   }) {
//     _showToast(
//       context: context,
//       title: title,
//       message: message,
//       type: ToastType.error,
//       duration: duration ?? const Duration(seconds: 4),
//     );
//   }

//   /// Show info toast notification
//   static void showInfoSnackBar({
//     required BuildContext? context,
//     required String title,
//     required String message,
//     Duration? duration,
//   }) {
//     _showToast(
//       context: context,
//       title: title,
//       message: message,
//       type: ToastType.info,
//       duration: duration ?? const Duration(seconds: 4),
//     );
//   }

//   /// Show success toast notification
//   static void showSuccessSnackBar({
//     required BuildContext? context,
//     required String title,
//     required String message,
//     Duration? duration,
//   }) {
//     _showToast(
//       context: context,
//       title: title,
//       message: message,
//       type: ToastType.success,
//       duration: duration ?? const Duration(seconds: 4),
//     );
//   }

//   /// Show warning toast notification
//   static void showWarningSnackBar({
//     required BuildContext? context,
//     required String title,
//     required String message,
//     Duration? duration,
//   }) {
//     _showToast(
//       context: context,
//       title: title,
//       message: message,
//       type: ToastType.warning,
//       duration: duration ?? const Duration(seconds: 4),
//     );
//   }

//   /// Internal method to show toast
//   static void _showToast({
//     required BuildContext? context,
//     required String title,
//     required String message,
//     required ToastType type,
//     required Duration duration,
//   }) {
//     // Remove existing toast if any
//     _removeCurrentToast();

//     final overlay = Overlay.of(context ?? Get.overlayContext!);
    
//     _currentOverlay = OverlayEntry(
//       builder: (context) => ToastWidget(
//         title: title,
//         message: message,
//         type: type,
//         duration: duration,
//         onDismiss: _removeCurrentToast,
//       ),
//     );

//     _isShowing = true;
//     overlay.insert(_currentOverlay!);
//   }

//   /// Remove current toast
//   static void _removeCurrentToast() {
//     if (_currentOverlay != null && _isShowing) {
//       _currentOverlay!.remove();
//       _currentOverlay = null;
//       _isShowing = false;
//     }
//   }

//   /// Dismiss any active toast
//   static void dismiss() {
//     _removeCurrentToast();
//   }
// }

// /// Toast types with associated styling
// enum ToastType {
//   success,
//   error,
//   info,
//   warning,
// }

// /// Individual toast widget with animations and styling
// class ToastWidget extends StatefulWidget {
//   final String title;
//   final String message;
//   final ToastType type;
//   final Duration duration;
//   final VoidCallback onDismiss;

//   const ToastWidget({
//     super.key,
//     required this.title,
//     required this.message,
//     required this.type,
//     required this.duration,
//     required this.onDismiss,
//   });

//   @override
//   State<ToastWidget> createState() => _ToastWidgetState();
// }

// class _ToastWidgetState extends State<ToastWidget>
//     with TickerProviderStateMixin {
//   late AnimationController _slideController;
//   late AnimationController _fadeController;
//   late AnimationController _progressController;
//   late Animation<Offset> _slideAnimation;
//   late Animation<double> _fadeAnimation;
//   late Animation<double> _progressAnimation;

//   @override
//   void initState() {
//     super.initState();
//     _initializeAnimations();
//     _startAnimations();
//   }

//   void _initializeAnimations() {
//     _slideController = AnimationController(
//       duration: const Duration(milliseconds: 350),
//       vsync: this,
//     );

//     _fadeController = AnimationController(
//       duration: const Duration(milliseconds: 300),
//       vsync: this,
//     );

//     _progressController = AnimationController(
//       duration: widget.duration,
//       vsync: this,
//     );

//     _slideAnimation = Tween<Offset>(
//       begin: const Offset(0, -1),
//       end: Offset.zero,
//     ).animate(CurvedAnimation(
//       parent: _slideController,
//       curve: Curves.elasticOut,
//     ));

//     _fadeAnimation = Tween<double>(
//       begin: 0.0,
//       end: 1.0,
//     ).animate(CurvedAnimation(
//       parent: _fadeController,
//       curve: Curves.easeIn,
//     ));

//     _progressAnimation = Tween<double>(
//       begin: 1.0,
//       end: 0.0,
//     ).animate(CurvedAnimation(
//       parent: _progressController,
//       curve: Curves.linear,
//     ));
//   }

//   void _startAnimations() {
//     _slideController.forward();
//     _fadeController.forward();
//     _progressController.forward();

//     _progressController.addStatusListener((status) {
//       if (status == AnimationStatus.completed) {
//         _dismissToast();
//       }
//     });
//   }

//   void _dismissToast() async {
//     await _fadeController.reverse();
//     widget.onDismiss();
//   }

//   @override
//   void dispose() {
//     _slideController.dispose();
//     _fadeController.dispose();
//     _progressController.dispose();
//     super.dispose();
//   }

//   ToastStyle _getToastStyle() {
//     switch (widget.type) {
//       case ToastType.success:
//         return ToastStyle(
//           backgroundColor: const Color(0xFF4CAF50),
//           iconColor: Colors.white,
//           icon: Icons.check_circle_outline,
//           progressColor: Colors.white.withOpacity(0.3),
//         );
//       case ToastType.error:
//         return ToastStyle(
//           backgroundColor: const Color(0xFFF44336),
//           iconColor: Colors.white,
//           icon: Icons.error_outline,
//           progressColor: Colors.white.withOpacity(0.3),
//         );
//       case ToastType.info:
//         return ToastStyle(
//           backgroundColor: const Color(0xFF2196F3),
//           iconColor: Colors.white,
//           icon: Icons.info_outline,
//           progressColor: Colors.white.withOpacity(0.3),
//         );
//       case ToastType.warning:
//         return ToastStyle(
//           backgroundColor: const Color(0xFFFF9800),
//           iconColor: Colors.white,
//           icon: Icons.warning_amber_outlined,
//           progressColor: Colors.white.withOpacity(0.3),
//         );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final style = _getToastStyle();
//     final isWeb = Theme.of(context).platform == TargetPlatform.fuchsia ||
//         GetPlatform.isWeb;
    
//     return Positioned(
//       top: MediaQuery.of(context).padding.top + 16,
//       left: 16,
//       right: 16,
//       child: FadeTransition(
//         opacity: _fadeAnimation,
//         child: SlideTransition(
//           position: _slideAnimation,
//           child: Material(
//             elevation: 8,
//             borderRadius: BorderRadius.circular(12),
//             color: Colors.transparent,
//             child: Container(
//               constraints: BoxConstraints(
//                 maxWidth: isWeb ? 400 : double.infinity,
//                 minHeight: 70,
//               ),
//               margin: isWeb 
//                   ? EdgeInsets.only(
//                       left: MediaQuery.of(context).size.width > 600 
//                           ? MediaQuery.of(context).size.width * 0.3 
//                           : 0
//                     )
//                   : EdgeInsets.zero,
//               decoration: BoxDecoration(
//                 color: style.backgroundColor,
//                 borderRadius: BorderRadius.circular(12),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.15),
//                     blurRadius: 10,
//                     offset: const Offset(0, 4),
//                   ),
//                 ],
//               ),
//               child: Stack(
//                 children: [
//                   // Progress indicator
//                   Positioned(
//                     bottom: 0,
//                     left: 0,
//                     right: 0,
//                     child: AnimatedBuilder(
//                       animation: _progressAnimation,
//                       builder: (context, child) {
//                         return Container(
//                           height: 3,
//                           decoration: BoxDecoration(
//                             borderRadius: const BorderRadius.only(
//                               bottomLeft: Radius.circular(12),
//                               bottomRight: Radius.circular(12),
//                             ),
//                             color: style.progressColor,
//                           ),
//                           child: LinearProgressIndicator(
//                             value: _progressAnimation.value,
//                             backgroundColor: Colors.transparent,
//                             valueColor: AlwaysStoppedAnimation<Color>(
//                               Colors.white.withOpacity(0.6),
//                             ),
//                           ),
//                         );
//                       },
//                     ),
//                   ),
                  
//                   // Main content
//                   Padding(
//                     padding: const EdgeInsets.all(16),
//                     child: Row(
//                       children: [
//                         // Icon
//                         Container(
//                           padding: const EdgeInsets.all(8),
//                           decoration: BoxDecoration(
//                             color: Colors.white.withOpacity(0.2),
//                             borderRadius: BorderRadius.circular(8),
//                           ),
//                           child: Icon(
//                             style.icon,
//                             color: style.iconColor,
//                             size: 24,
//                           ),
//                         ),
//                         const SizedBox(width: 12),
                        
//                         // Text content
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               Text(
//                                 widget.title,
//                                 style: const TextStyle(
//                                   color: Colors.white,
//                                   fontSize: 15,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                                 maxLines: 1,
//                                 overflow: TextOverflow.ellipsis,
//                               ),
//                               const SizedBox(height: 4),
//                               Text(
//                                 widget.message,
//                                 style: const TextStyle(
//                                   color: Colors.white,
//                                   fontSize: 13,
//                                   fontWeight: FontWeight.normal,
//                                 ),
//                                 maxLines: 2,
//                                 overflow: TextOverflow.ellipsis,
//                               ),
//                             ],
//                           ),
//                         ),
                        
//                         // Dismiss button
//                         GestureDetector(
//                           onTap: _dismissToast,
//                           child: Container(
//                             padding: const EdgeInsets.all(4),
//                             decoration: BoxDecoration(
//                               color: Colors.white.withOpacity(0.2),
//                               borderRadius: BorderRadius.circular(4),
//                             ),
//                             child: const Icon(
//                               Icons.close,
//                               color: Colors.white,
//                               size: 18,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// /// Toast styling configuration
// class ToastStyle {
//   final Color backgroundColor;
//   final Color iconColor;
//   final IconData icon;
//   final Color progressColor;

//   const ToastStyle({
//     required this.backgroundColor,
//     required this.iconColor,
//     required this.icon,
//     required this.progressColor,
//   });
// }

// /// Backward compatibility - Create an alias with the old class name
// /// This ensures existing code continues to work without modification
// class CustomSnackBar {
//   static void showErrorSnackBar({
//     required BuildContext? context,
//     required String title,
//     required String message,
//     Duration? duration,
//   }) {
//     CustomToast.showErrorSnackBar(
//       context: context,
//       title: title,
//       message: message,
//       duration: duration,
//     );
//   }

//   static void showInfoSnackBar({
//     required BuildContext? context,
//     required String title,
//     required String message,
//     Duration? duration,
//   }) {
//     CustomToast.showInfoSnackBar(
//       context: context,
//       title: title,
//       message: message,
//       duration: duration,
//     );
//   }

//   static void showSuccessSnackBar({
//     required BuildContext? context,
//     required String title,
//     required String message,
//     Duration? duration,
//   }) {
//     CustomToast.showSuccessSnackBar(
//       context: context,
//       title: title,
//       message: message,
//       duration: duration,
//     );
//   }

//   static void showWarningSnackBar({
//     required BuildContext? context,
//     required String title,
//     required String message,
//     Duration? duration,
//   }) {
//     CustomToast.showWarningSnackBar(
//       context: context,
//       title: title,
//       message: message,
//       duration: duration,
//     );
//   }
// }