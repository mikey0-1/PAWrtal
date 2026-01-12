import 'package:capstone_app/notification/services/appointment_reminder_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// OPTIONAL: Debug widget for testing appointment reminder service
/// You can add this to your admin/super admin panel for monitoring
class ReminderServiceDebugWidget extends StatefulWidget {
  const ReminderServiceDebugWidget({super.key});

  @override
  State<ReminderServiceDebugWidget> createState() => _ReminderServiceDebugWidgetState();
}

class _ReminderServiceDebugWidgetState extends State<ReminderServiceDebugWidget> {
  final AppointmentReminderService _reminderService = Get.find();
  Map<String, dynamic> _stats = {};
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  void _loadStats() {
    setState(() {
      _stats = _reminderService.getReminderStats();
    });
  }

  Future<void> _manualCheck() async {
    setState(() {
      _isChecking = true;
    });

    try {
      await _reminderService.manualCheckReminders();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Manual check completed'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✗ Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
        _loadStats();
      }
    }
  }

  void _clearReminded() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Reminded Appointments?'),
        content: const Text(
          'This will reset the reminder tracking. Appointments that were previously reminded may be reminded again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _reminderService.clearRemindedAppointments();
              Navigator.pop(context);
              _loadStats();
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✓ Reminded appointments cleared'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(6),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.alarm, color: Colors.blue, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Appointment Reminder Service',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadStats,
                  tooltip: 'Refresh stats',
                ),
              ],
            ),
            const Divider(height: 32),
            
            // Service Status
            _buildStatRow(
              'Service Status',
              _stats['isRunning'] == true ? 'Running' : 'Stopped',
              _stats['isRunning'] == true ? Colors.green : Colors.red,
            ),
            const SizedBox(height: 12),
            
            // Configuration
            _buildStatRow(
              'Check Interval',
              '${_stats['checkIntervalMinutes'] ?? 0} minutes',
              Colors.blue,
            ),
            const SizedBox(height: 12),
            
            _buildStatRow(
              'Reminder Window',
              '${_stats['reminderWindowMinutes'] ?? 0} minutes before',
              Colors.orange,
            ),
            const SizedBox(height: 12),
            
            _buildStatRow(
              'Appointments Reminded',
              '${_stats['remindedCount'] ?? 0}',
              Colors.purple,
            ),
            
            const Divider(height: 32),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isChecking ? null : _manualCheck,
                    icon: _isChecking
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.search),
                    label: Text(_isChecking ? 'Checking...' : 'Manual Check'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _clearReminded,
                    icon: const Icon(Icons.delete_sweep),
                    label: const Text('Clear Tracking'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Info text
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Service automatically checks for upcoming appointments and sends reminders to users.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color
            ),
          ),
        ),
      ],
    );
  }
}