import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/mobile/user/components/general_components/app_bar.dart';
import 'package:capstone_app/mobile/user/components/general_components/drawer.dart';
import 'package:capstone_app/mobile/user/pages/appointment_page.dart';
import 'package:capstone_app/mobile/user/pages/dashboard_page.dart';
import 'package:capstone_app/mobile/user/pages/messages_page.dart';
import 'package:capstone_app/mobile/user/pages/pawmap.dart';
import 'package:capstone_app/mobile/user/pages/pets_page.dart';
import 'package:capstone_app/web/pages/web_user_home/web_user_home_controller.dart';
import 'package:flutter/material.dart';
import 'package:capstone_app/pages/user_home/user_home_controller.dart';
import 'package:get/get.dart';

class UserHomePage extends StatefulWidget {
  final int initialIndex;
  final ValueChanged<int>? onItemSelected;
  
  const UserHomePage({
    super.key,
    this.initialIndex = 0,
    this.onItemSelected,
  });

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  final UserHomeController controller =
      UserHomeController(Get.find<AuthRepository>());

  late int _currentIndex;

  final List<Widget> _pages = const [
    DashboardPage(),
    EnhancedAppointmentPage(),
    Messages(),
    PetsPage()
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    // Try to find the controller, but don't fail if it doesn't exist
    final webController = Get.isRegistered<WebUserHomeController>() 
        ? Get.find<WebUserHomeController>() 
        : null;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: const MyAppBar(),
      drawer: const MyDrawer(),
      body: Stack(
        children: [
          // Page content - show map OR current page
          Obx(() {
            final bool showMapView = webController?.showMapView.value ?? false;
            
            // If map view is active, show Pawmap regardless of current tab
            if (showMapView) {
              return const Pawmap();
            }
            
            // Otherwise show the current page
            return _pages[_currentIndex];
          }),
          
          // Bottom navigation overlay
          Stack(
            alignment: Alignment.bottomCenter,
            children: [
              // Nav bar - conditionally shown
              Obx(() {
                // Hide nav bar when map view is active
                final bool showMapView = webController?.showMapView.value ?? false;
                final bool showNavBar = !showMapView;

                return Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    // Nav bar - conditionally shown
                    if (showNavBar)
                      Positioned(
                        bottom: 24,
                        left: 24,
                        right: 24,
                        child: CustomPaint(
                          painter: NotchedNavbarPainter(),
                          child: SizedBox(
                            height: 70,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _navButton(const Icon(Icons.home_rounded), 0),
                                _navButton(const Icon(Icons.calendar_month_rounded), 1),
                                const SizedBox(width: 30),
                                _navButton(const Icon(Icons.message_rounded), 2),
                                _navButton(const Icon(Icons.pets_rounded), 3),
                              ]
                            ),
                          ),
                        ),
                      ),
                    // Center button - always shown
                    Positioned(
                      bottom: showNavBar ? (24 + 60 - 28) : 24 + 60 - 28,
                      child: FloatingActionButton(  
                        backgroundColor: Colors.white,
                        heroTag: "userHomeLoc",
                        shape: const CircleBorder(),
                        onPressed: () {
                          // Toggle map view if controller exists
                          if (webController != null) {
                            webController.toggleMapView();
                          } else {
                            // Fallback: Navigate to standalone Pawmap
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const Pawmap(),
                              )
                            );
                          }
                        },
                        child: Obx(() {
                          final bool showMapView = webController?.showMapView.value ?? false;
                          return Icon(
                            showMapView
                                ? Icons.list_rounded
                                : Icons.location_on_rounded,
                            color: Colors.black,
                          );
                        }),
                      ),
                    )
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _navButton(Icon icon, int index) {
    return IconButton(
      onPressed: () {
        setState(() {
          _currentIndex = index;
        });
        widget.onItemSelected?.call(index);
        
        // Close map view when switching tabs
        if (Get.isRegistered<WebUserHomeController>()) {
          Get.find<WebUserHomeController>().setMapView(false);
        }
      },
      icon: icon,
      iconSize: 30,
      color: _currentIndex == index ? Colors.black : Colors.grey,
    );
  }
}

class NotchedNavbarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.grey.shade100
      ..style = PaintingStyle.fill;

    final Path path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(35),
      ));

    const double notchRadius = 35;
    final double notchCenter = size.width / 2;
    const double notchTop = -25;

    final Path notchPath = Path()
      ..addOval(Rect.fromCircle(
        center: Offset(notchCenter, notchTop + notchRadius),
        radius: notchRadius,
      ));

    final Path finalPath = Path.combine(
      PathOperation.difference,
      path,
      notchPath,
    );

    canvas.drawPath(finalPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}