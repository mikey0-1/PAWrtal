import 'package:flutter/material.dart';

class SuperAdminSortButton extends StatefulWidget {
  final Function(String)? onSortChanged;

  const SuperAdminSortButton({
    super.key,
    this.onSortChanged,
  });

  @override
  State<SuperAdminSortButton> createState() => _SuperAdminSortButtonState();
}

class _SuperAdminSortButtonState extends State<SuperAdminSortButton> {
  String selectedSort = 'name';

  // Color Palette
  static const Color primaryColor = Color.fromRGBO(81, 115, 153, 1);
  static const Color backgroundColor = Color.fromARGB(255, 248, 253, 255);
  static const Color accentTeal = Color(0xFF5B9BD5);
  static const Color darkBlue = Color.fromRGBO(51, 75, 103, 1);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryColor, accentTeal],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showSortMenu,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: const Icon(Icons.filter_list, color: Colors.white),
          ),
        ),
      ),
    );
  }

  void _showSortMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, backgroundColor],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryColor.withOpacity(0.2), accentTeal.withOpacity(0.1)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.sort, color: primaryColor, size: 24),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Sort Clinics By',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: darkBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSortOption(
              'Alphabetically (A-Z)',
              'Sort by clinic name',
              Icons.sort_by_alpha_rounded,
              'name',
              [primaryColor, darkBlue],
            ),
            const SizedBox(height: 12),
            _buildSortOption(
              'Registration Date',
              'Newest first',
              Icons.calendar_today_rounded,
              'date',
              [accentTeal, primaryColor],
            ),
            const SizedBox(height: 12),
            _buildSortOption(
              'Operating Status',
              'Open clinics first',
              Icons.toggle_on_rounded,
              'status',
              [const Color(0xFF34D399), accentTeal],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(
    String title,
    String subtitle,
    IconData icon,
    String sortValue,
    List<Color> colors,
  ) {
    final isSelected = selectedSort == sortValue;

    return InkWell(
      onTap: () {
        setState(() => selectedSort = sortValue);
        widget.onSortChanged?.call(sortValue);
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(colors: [colors[0].withOpacity(0.15), colors[1].withOpacity(0.1)])
              : null,
          color: isSelected ? null : Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? colors[0] : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: colors),
                borderRadius: BorderRadius.circular(12),
                boxShadow: isSelected
                    ? [BoxShadow(color: colors[0].withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
                    : null,
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? colors[0] : darkBlue,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: colors[0], size: 24),
          ],
        ),
      ),
    );
  }
}