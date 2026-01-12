import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'staff_full_details.dart';
import 'package:capstone_app/data/models/staff_model.dart' as StaffModel;

class StaffTile extends StatefulWidget {
  final StaffModel.Staff staff;
  final void Function(List<String>) onUpdate;
  final VoidCallback onRemove;

  const StaffTile({
    super.key,
    required this.staff,
    required this.onUpdate,
    required this.onRemove,
  });

  @override
  State<StaffTile> createState() => _StaffTileState();
}

class _StaffTileState extends State<StaffTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  static const Color primaryBlue = Color(0xFF4A6FA5);
  static const Color primaryTeal = Color(0xFF5B9BD5);
  static const Color lightTeal = Color(0xFF9FC5E8);
  static const Color deepBlue = Color(0xFF2F4F7F);
  static const Color softBlue = Color(0xFF6FA8DC);
  static const Color lightGray = Color(0xFFF3F4F6);
  static const Color mediumGray = Color(0xFF9CA3AF);
  static const Color darkText = Color(0xFF374151);
  static const Color vetGreen = Color(0xFF34D399);
  static const Color vetOrange = Color(0xFFF59E0B);
  static const Color lightVetGreen = Color(0xFFE5F7E5);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showStaffDetails() {
    Uint8List? imageBytes;
    if (widget.staff.image.isNotEmpty) {
      imageBytes = null;
    }

    final staffEmail = widget.staff.email;

    showDialog(
      context: context,
      builder: (_) => StaffFullDetails(
        staffName: widget.staff.name,
        username: widget.staff.username,
        phone: widget.staff.phone,
        email: staffEmail.isNotEmpty ? staffEmail : null,
        initialAuthorities: widget.staff.authorities,
        onAuthoritiesUpdated: widget.onUpdate,
        onRemove: widget.onRemove,
        imageBytes: imageBytes,
        staffDocumentId: widget.staff.documentId!,
        currentImageUrl:
            widget.staff.image.isNotEmpty ? widget.staff.image : null,
        isDoctor: widget.staff.isDoctor, // ADD THIS LINE
      ),
    );
  }

  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _controller.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTap: _showStaffDetails,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                gradient: _isHovered
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white,
                          lightVetGreen.withOpacity(0.3),
                          primaryTeal.withOpacity(0.1),
                        ],
                      )
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white,
                          lightVetGreen.withOpacity(0.1),
                        ],
                      ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: _isHovered
                        ? primaryTeal.withOpacity(0.2)
                        : primaryTeal.withOpacity(0.1),
                    blurRadius: _isHovered ? 15 : 8,
                    offset: Offset(0, _isHovered ? 6 : 3),
                    spreadRadius: _isHovered ? 2 : 1,
                  ),
                ],
                border: Border.all(
                  color: _isHovered
                      ? primaryTeal.withOpacity(0.4)
                      : primaryTeal.withOpacity(0.2),
                  width: _isHovered ? 2 : 1.5,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: _showStaffDetails,
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Profile Image with Badge
                        Stack(
                          children: [
                            Container(
                              width: 76,
                              height: 76,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: widget.staff.image.isEmpty
                                    ? LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          primaryTeal.withOpacity(0.15),
                                          primaryBlue.withOpacity(0.1),
                                          lightTeal.withOpacity(0.1),
                                        ],
                                      )
                                    : null,
                                border: Border.all(
                                  color: _isHovered
                                      ? primaryTeal
                                      : primaryTeal.withOpacity(0.4),
                                  width: _isHovered ? 3 : 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryTeal.withOpacity(0.2),
                                    blurRadius: _isHovered ? 12 : 6,
                                    offset: Offset(0, _isHovered ? 4 : 2),
                                  ),
                                ],
                                image: widget.staff.image.isNotEmpty
                                    ? DecorationImage(
                                        image: NetworkImage(widget.staff.image),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: widget.staff.image.isEmpty
                                  ? const Icon(
                                      Icons.person,
                                      size: 36,
                                      color: primaryTeal,
                                    )
                                  : null,
                            ),
                            // DOCTOR BADGE - Top right position
                            if (widget.staff.isDoctor)
                              Positioned(
                                top: -2,
                                right: -2,
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Colors.red, Colors.redAccent],
                                    ),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 3,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.red.withOpacity(0.4),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.medical_services,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ),
                                ),
                              ),
                            // PERMISSIONS BADGE - Bottom right position
                            if (widget.staff.authorities.isNotEmpty)
                              Positioned(
                                bottom: -2,
                                right: -2,
                                child: Container(
                                  width: 26,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [vetGreen, primaryTeal],
                                    ),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 3,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: vetGreen.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${widget.staff.authorities.length}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Name
                        Text(
                          widget.staff.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            foreground: Paint()
                              ..shader = const LinearGradient(
                                colors: [darkText, primaryTeal],
                              ).createShader(
                                  const Rect.fromLTWH(0, 0, 200, 50)),
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                        // NEW: Doctor Badge below name
                        if (widget.staff.isDoctor) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Colors.red, Colors.redAccent],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.verified,
                                  color: Colors.white,
                                  size: 12,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Licensed Veterinarian',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 16),

                        // Permissions Preview (RESPONSIVE TO CONTENT)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                lightGray,
                                lightVetGreen.withOpacity(0.3),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border:
                                Border.all(color: primaryTeal.withOpacity(0.2)),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          primaryTeal.withOpacity(0.2),
                                          primaryBlue.withOpacity(0.1),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(Icons.security,
                                        size: 12, color: primaryTeal),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'Permissions',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: darkText,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              if (widget.staff.authorities.isEmpty)
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  child: Text(
                                    'No permissions assigned',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[500],
                                      fontStyle: FontStyle.italic,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                )
                              else
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children:
                                      widget.staff.authorities.map((auth) {
                                    IconData icon;
                                    List<Color> colors;
                                    switch (auth) {
                                      case 'Clinic':
                                        icon = Icons.local_hospital;
                                        colors = [primaryTeal, primaryBlue];
                                        break;
                                      case 'Appointments':
                                        icon = Icons.calendar_month;
                                        colors = [primaryBlue, softBlue];
                                        break;
                                      case 'Messages':
                                        icon = Icons.message;
                                        colors = [vetOrange, primaryTeal];
                                        break;
                                      default:
                                        icon = Icons.check_circle;
                                        colors = [mediumGray, mediumGray];
                                    }

                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              colors.first.withOpacity(0.2),
                                              colors.last.withOpacity(0.1),
                                            ],
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                              color: colors.first
                                                  .withOpacity(0.3)),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(icon,
                                                size: 12, color: colors.first),
                                            const SizedBox(width: 6),
                                            Text(
                                              auth,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: colors.first,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
