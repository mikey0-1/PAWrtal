import 'package:capstone_app/web/admin_web/components/appointments/admin_web_appointment_controller.dart';
import 'appointment_view_mode.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class WebAppointmentStats extends StatelessWidget {
  const WebAppointmentStats({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<WebAppointmentController>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth < 1200 && screenWidth >= 768;

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(controller),
          const SizedBox(height: 20),
          if (isTablet)
            _buildTabletStatsGrid(controller)
          else
            _buildDesktopStatsGrid(controller),
        ],
      ),
    );
  }

  Widget _buildHeader(WebAppointmentController controller) {
    return Obx(() => Container(
          padding:
              const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color.fromARGB(255, 81, 115, 153),
                Colors.blue.shade400,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.15),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('EEEE, MMMM dd, yyyy')
                              .format(DateTime.now()),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Appointment Management",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Improved today count display
                        if (controller.selectedCalendarDate.value != null)
                          Row(
                            children: [
                              Icon(
                                Icons.filter_alt,
                                size: 16,
                                color: Colors.white.withOpacity(0.9),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "Filtered: ${DateFormat('MMM dd, yyyy').format(controller.selectedCalendarDate.value!)}",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 14,
                                  color: Colors.white.withOpacity(0.95),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Total Appointments: ',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  '${controller.appointmentStats['today']}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Improved total display
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${controller.appointmentStats['total']}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Appointments',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            controller.selectedCalendarDate.value != null
                                ? 'Selected Date'
                                : controller.viewMode.value.label,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.95),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: AppointmentViewMode.values.map((mode) {
                    final isSelected = controller.viewMode.value == mode;
                    return Padding(
                      padding: const EdgeInsets.only(right: 2),
                      child: InkWell(
                        onTap: () => controller.setViewMode(mode),
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isSelected ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            mode.label,
                            style: TextStyle(
                              color: isSelected
                                  ? const Color.fromARGB(255, 81, 115, 153)
                                  : Colors.white,
                              fontSize: 11,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              if (controller.selectedCalendarDate.value != null) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () => controller.setCalendarDate(null),
                  icon: const Icon(Icons.clear, color: Colors.white, size: 14),
                  label: const Text(
                    'Clear date filter',
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ],
            ],
          ),
        ));
  }

  Widget _buildTabletStatsGrid(WebAppointmentController controller) {
    return Obx(() {
      final stats = controller.appointmentStats;
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                  child: _buildStatCard('Pending', stats['pending']!,
                      Icons.pending, Colors.orange)),
              const SizedBox(width: 16),
              Expanded(
                  child: _buildStatCard('Scheduled', stats['scheduled']!,
                      Icons.schedule, Colors.green)),
              const SizedBox(width: 16),
              Expanded(
                  child: _buildStatCard('In Progress', stats['in_progress']!,
                      Icons.medical_services, Colors.purple)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: _buildStatCard('Completed', stats['completed']!,
                      Icons.check_circle, Colors.teal)),
              const SizedBox(width: 16),
              Expanded(
                  child: _buildStatCard('Cancelled', stats['cancelled']!,
                      Icons.cancel, Colors.grey)),
              const SizedBox(width: 16),
              Expanded(
                  child: _buildStatCard('Declined', stats['declined']!,
                      Icons.cancel_outlined, Colors.red)),
            ],
          ),
        ],
      );
    });
  }

  Widget _buildDesktopStatsGrid(WebAppointmentController controller) {
    return Obx(() {
      final stats = controller.appointmentStats;
      return LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          // If space gets tight before tablet breakpoint, use scrollable view
          if (screenWidth < 1400) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  SizedBox(
                    width: 190,
                    child: _buildStatCard('Pending', stats['pending']!,
                        Icons.pending, Colors.orange,
                        isDesktop: true),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 190,
                    child: _buildStatCard('Scheduled', stats['scheduled']!,
                        Icons.schedule, Colors.green,
                        isDesktop: true),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 190,
                    child: _buildStatCard('In Progress', stats['in_progress']!,
                        Icons.medical_services, Colors.purple,
                        isDesktop: true),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 190,
                    child: _buildStatCard('Completed', stats['completed']!,
                        Icons.check_circle, Colors.teal,
                        isDesktop: true),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 190,
                    child: _buildStatCard('Cancelled', stats['cancelled']!,
                        Icons.cancel, Colors.grey,
                        isDesktop: true),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 190,
                    child: _buildStatCard('Declined', stats['declined']!,
                        Icons.cancel_outlined, Colors.red,
                        isDesktop: true),
                  ),
                ],
              ),
            );
          }

          // Normal layout for larger screens
          return Row(
            children: [
              Expanded(
                child: _buildStatCard(
                    'Pending ', stats['pending']!, Icons.pending, Colors.orange,
                    isDesktop: true),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard('Scheduled', stats['scheduled']!,
                    Icons.schedule, Colors.green,
                    isDesktop: true),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard('In Progress', stats['in_progress']!,
                    Icons.medical_services, Colors.purple,
                    isDesktop: true),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard('Completed', stats['completed']!,
                    Icons.check_circle, Colors.teal,
                    isDesktop: true),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                    'Cancelled', stats['cancelled']!, Icons.cancel, Colors.grey,
                    isDesktop: true),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard('Declined', stats['declined']!,
                    Icons.cancel_outlined, Colors.red,
                    isDesktop: true),
              ),
            ],
          );
        },
      );
    });
  }

  Widget _buildStatCard(String title, int value, IconData icon, Color color,
      {bool isDesktop = false}) {
    final controller = Get.find<WebAppointmentController>();
    return Container(
      padding: EdgeInsets.all(isDesktop ? 12 : 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: isDesktop ? 18 : 16,
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        value.toString(),
                        style: TextStyle(
                          fontSize: isDesktop ? 24 : 20,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: isDesktop ? 12 : 11,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
