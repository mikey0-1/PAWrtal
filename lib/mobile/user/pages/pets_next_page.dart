import 'package:capstone_app/data/models/pet_model.dart';
import 'package:capstone_app/mobile/user/controllers/mobile_pets_controller.dart';
import 'package:capstone_app/mobile/user/pages/pet_card_creation.dart';
import 'package:capstone_app/mobile/user/components/pets_components/pet_medical_history.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class PetsNextPage extends StatefulWidget {
  final Pet pet;
  const PetsNextPage({super.key, required this.pet});

  @override
  State<PetsNextPage> createState() => _PetsNextPageState();
}

class _PetsNextPageState extends State<PetsNextPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isLoadingHistory = true;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _animationController.forward();

    // Fetch histories when page opens
    _fetchHistories();
  }

  Future<void> _fetchHistories() async {
    if (!mounted) return;

    setState(() {
      _isLoadingHistory = true;
    });

    try {
      if (Get.isRegistered<MobilePetsController>()) {
        final controller = Get.find<MobilePetsController>();

        // Clear previous data first
        controller.clearHistories();

        // Fetch all data and AWAIT completion
        await Future.wait([
          controller.fetchPetMedicalAppointmentsAllClinics(widget.pet.petId),
          controller.fetchPetMedicalRecordsForAppointments(widget.pet.petId),
          controller.fetchPetVaccinationHistory(widget.pet.petId),
        ]);
      }
    } catch (e) {
      debugPrint('>>> ❌ Error fetching histories: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingHistory = false;
        });
      }
    }
  }

  @override
  void didUpdateWidget(PetsNextPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if pet changed
    if (oldWidget.pet.petId != widget.pet.petId) {
      _fetchHistories();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // App Bar with Image
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: const Color(0xFF667eea),
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_ios_new, size: 18),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.edit, size: 20),
                ),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PetCardCreation(existingPet: widget.pet),
                    ),
                  );
                  if (result == true) {
                    Get.back(result: true);
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.white),
                onPressed: () => _confirmDelete(context),
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    widget.pet.image ??
                        'https://images.unsplash.com/photo-1601758228041-f3b2795255f1?w=600&h=600&fit=crop',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.pets, size: 100),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.pet.name,
                          style: GoogleFonts.inter(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF667eea),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            widget.pet.type,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Basic Information Card
                    _buildInfoCard(
                      title: "Basic Information",
                      icon: Icons.info_outline,
                      children: [
                        _buildInfoRow(Icons.pets, "Breed", widget.pet.breed),
                        const Divider(height: 24),
                        _buildInfoRow(
                          Icons.palette,
                          "Color",
                          widget.pet.color ?? "Not specified",
                        ),
                        const Divider(height: 24),
                        _buildInfoRow(
                          Icons.monitor_weight,
                          "Weight",
                          widget.pet.weight != null
                              ? "${widget.pet.weight} kg"
                              : "Not specified",
                        ),
                        const Divider(height: 24),
                        _buildInfoRow(
                          Icons.wc,
                          "Gender",
                          widget.pet.gender ?? "Not specified",
                        ),
                        // NEW: Add birthdate and age
                        if (widget.pet.hasBirthdate) ...[
                          const Divider(height: 24),
                          _buildInfoRow(
                            Icons.cake,
                            "Birthdate",
                            DateFormat('MMMM dd, yyyy')
                                .format(widget.pet.birthdate!),
                          ),
                          const Divider(height: 24),
                          _buildInfoRow(
                            Icons.access_time,
                            "Age",
                            widget.pet.ageString,
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Notes Card
                    if (widget.pet.notes != null &&
                        widget.pet.notes!.isNotEmpty)
                      _buildInfoCard(
                        title: "Notes",
                        icon: Icons.notes,
                        children: [
                          Text(
                            widget.pet.notes!,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              color: Colors.grey[700],
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 16),

                    // Health Records Section Title
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Health Records',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2C3E50),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

// Show loading or buttons
                    _isLoadingHistory
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(40),
                              child: Column(
                                children: [
                                  CircularProgressIndicator(
                                    color: const Color(0xFF667eea),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Loading health records...',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : Column(
                            children: [
                              // Medical Appointments History Button (PRIMARY)
                              GetX<MobilePetsController>(
                                builder: (controller) {
                                  return _buildHistoryButton(
                                    title: 'Medical Appointments',
                                    subtitle:
                                        'View all medical appointments with records',
                                    icon: Icons.local_hospital_outlined,
                                    onTap: () => _navigateToMedicalHistory(
                                        MedicalHistoryType.appointments),
                                    count:
                                        controller.medicalAppointments.length,
                                    isPrimary: true,
                                    color: const Color(0xFF667eea),
                                  );
                                },
                              ),

                              const SizedBox(height: 12),

                              // Vaccination History Button
                              GetX<MobilePetsController>(
                                builder: (controller) {
                                  return _buildHistoryButton(
                                    title: 'Vaccination History',
                                    subtitle: 'View vaccination records',
                                    icon: Icons.vaccines_outlined,
                                    onTap: () => _navigateToMedicalHistory(
                                        MedicalHistoryType.vaccinations),
                                    count: controller.vaccinations.length,
                                    isPrimary: false,
                                    color: const Color(0xFF9B59B6),
                                  );
                                },
                              ),
                            ],
                          ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF667eea).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFF667eea),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2C3E50),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[400], size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: const Color(0xFF2C3E50),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    required int count,
    required bool isPrimary,
    required Color color,
  }) {
    return Card(
      elevation: isPrimary ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isPrimary ? color : Colors.grey[300]!,
          width: isPrimary ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: isPrimary
                ? LinearGradient(
                    colors: [color.withOpacity(0.05), Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: color.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '$count',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    count == 1 ? 'record' : 'records',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios,
                size: 18,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToMedicalHistory(MedicalHistoryType type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PetMedicalHistory(
          pet: widget.pet,
          initialType: type,
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          "Delete Pet",
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2C3E50),
          ),
        ),
        content: Text(
          "Are you sure you want to delete ${widget.pet.name}? This action cannot be undone.",
          style: GoogleFonts.inter(
            color: Colors.grey[600],
          ),
        ),
        actions: [
          TextButton(
            child: Text(
              "Cancel",
              style: GoogleFonts.inter(color: Colors.grey[600]),
            ),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text("Delete"),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirm ?? false) {
      try {
        // Delete image if exists
        if (widget.pet.image != null && widget.pet.image!.isNotEmpty) {
          final imageId = widget.pet.image!.split('/files/')[1].split('/')[0];
          await Get.find<AuthRepository>().deleteImage(imageId);
        }

        // Delete pet
        await Get.find<AuthRepository>().deletePet(widget.pet.documentId!);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("${widget.pet.name} deleted successfully"),
              backgroundColor: Colors.green,
            ),
          );
        }

        Get.back(result: true);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Failed to delete pet: $e"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
