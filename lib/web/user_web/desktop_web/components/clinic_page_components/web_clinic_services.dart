import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/web/user_web/desktop_web/components/clinic_page_components/web_services_updated.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WebClinicServicesUpdated extends StatefulWidget {
  final Clinic clinic;
  
  const WebClinicServicesUpdated({super.key, required this.clinic});

  @override
  State<WebClinicServicesUpdated> createState() => _WebClinicServicesUpdatedState();
}

class _WebClinicServicesUpdatedState extends State<WebClinicServicesUpdated> {
  List<String> _services = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClinicServices();
  }

  Future<void> _loadClinicServices() async {
    try {
      // Try to get services from clinic settings first
      final authRepository = Get.find<AuthRepository>();
      final clinicSettings = await authRepository.getClinicSettingsByClinicId(widget.clinic.documentId ?? '');
      
      if (clinicSettings != null && clinicSettings.services.isNotEmpty) {
        setState(() {
          _services = clinicSettings.services;
          _isLoading = false;
        });
      } else {
        // Fallback to clinic.services field
        setState(() {
          _services = _parseServicesFromClinic();
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _services = _parseServicesFromClinic();
        _isLoading = false;
      });
    }
  }

  List<String> _parseServicesFromClinic() {
    if (widget.clinic.services.isNotEmpty) {
      return widget.clinic.services
          .split(RegExp(r'[,;|\n•]'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    
    // Default services if none are set
    return [
      'General Checkup',
      'Vaccination',
      'Surgery',
      // 'Dental Care',
      'Emergency Care',
      'Laboratory Tests',
      'Pet Grooming',
      // 'Microchipping'
    ];
  }

  int _getColumnCount(double width) {
    if (width >= 800) {
      return 2; // Desktop: 2 columns
    } else if (width >= 600) {
      return 2; // Tablet: 2 columns
    } else {
      return 1; // Mobile: 1 column
    }
  }

  double _getChildAspectRatio(double width) {
    if (width >= 800) {
      return 10; // Desktop: keep original ratio
    } else if (width >= 600) {
      return 8; // Tablet: slightly shorter
    } else {
      return 6; // Mobile: even shorter for better fit
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_services.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.medical_services_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              "No services listed",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        
        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _getColumnCount(width),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: _getChildAspectRatio(width),
          ),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _services.length,
          itemBuilder: (context, index) {
            return WebServicesUpdated(serviceName: _services[index]);
          },
        );
      },
    );
  }
}