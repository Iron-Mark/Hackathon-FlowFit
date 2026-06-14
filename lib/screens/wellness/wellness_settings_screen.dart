import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/wellness_state_provider.dart';

/// Settings screen for wellness tracker privacy and preferences
class WellnessSettingsScreen extends ConsumerStatefulWidget {
  const WellnessSettingsScreen({super.key});

  @override
  ConsumerState<WellnessSettingsScreen> createState() =>
      _WellnessSettingsScreenState();
}

class _WellnessSettingsScreenState
    extends ConsumerState<WellnessSettingsScreen> {
  bool _monitoringEnabled = false;
  bool _stressAlertsEnabled = true;
  bool _cardioAlertsEnabled = true;
  int _alertFrequency = 30; // minutes

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // Load settings from SharedPreferences
    // This is a placeholder - actual implementation would load from prefs
    setState(() {
      _monitoringEnabled = true;
      _stressAlertsEnabled = true;
      _cardioAlertsEnabled = true;
      _alertFrequency = 30;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F6FD),
      appBar: AppBar(
        title: const Text(
          'Wellness Settings',
          style: TextStyle(
            fontFamily: 'GeneralSans',
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),

            // Monitoring Toggle
            _buildSection(
              title: 'Monitoring',
              children: [
                _buildSwitchTile(
                  title: 'Enable Wellness Monitoring',
                  subtitle: 'Track your wellness state throughout the day',
                  value: _monitoringEnabled,
                  onChanged: (value) async {
                    setState(() => _monitoringEnabled = value);
                    // TODO: Enable/disable monitoring service
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Notification Settings
            _buildSection(
              title: 'Notifications',
              children: [
                _buildSwitchTile(
                  title: 'Stress Alerts',
                  subtitle: 'Get notified when stress is detected',
                  value: _stressAlertsEnabled,
                  onChanged: (value) {
                    setState(() => _stressAlertsEnabled = value);
                  },
                ),
                _buildSwitchTile(
                  title: 'Exercise Detection',
                  subtitle: 'Get notified when cardio activity is detected',
                  value: _cardioAlertsEnabled,
                  onChanged: (value) {
                    setState(() => _cardioAlertsEnabled = value);
                  },
                ),
                _buildDropdownTile(
                  title: 'Alert Frequency',
                  subtitle: 'Minimum time between alerts',
                  value: _alertFrequency,
                  items: const [
                    DropdownMenuItem(value: 15, child: Text('15 minutes')),
                    DropdownMenuItem(value: 30, child: Text('30 minutes')),
                    DropdownMenuItem(value: 60, child: Text('1 hour')),
                    DropdownMenuItem(value: 120, child: Text('2 hours')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _alertFrequency = value);
                    }
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Privacy Section
            _buildSection(
              title: 'Privacy',
              children: [
                _buildInfoTile(
                  icon: Icons.lock_outline,
                  title: 'Data Privacy',
                  subtitle:
                      'All biometric data is processed on your device only',
                  color: Colors.green,
                ),
                _buildActionTile(
                  icon: Icons.delete_outline,
                  title: 'Clear Wellness History',
                  subtitle: 'Delete all stored wellness data',
                  color: Colors.red,
                  onTap: () => _showClearDataDialog(),
                ),
                _buildActionTile(
                  icon: Icons.info_outline,
                  title: 'Privacy Policy',
                  subtitle: 'Learn how we protect your data',
                  color: Colors.blue,
                  onTap: () {
                    // Navigate to privacy policy
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Data Transparency
            _buildSection(
              title: 'Data Collection',
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.blue.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.info,
                              color: Colors.blue,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'What We Collect',
                              style: TextStyle(
                                fontFamily: 'GeneralSans',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue[900],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildDataItem('Heart rate measurements'),
                        _buildDataItem('Movement/activity data'),
                        _buildDataItem('Wellness state transitions'),
                        _buildDataItem('Usage timestamps'),
                        const SizedBox(height: 12),
                        Text(
                          '✓ Data stays private on your device\n'
                          '✓ No data is sent to external servers\n'
                          '✓ You can delete your data anytime',
                          style: TextStyle(
                            fontFamily: 'GeneralSans',
                            fontSize: 12,
                            color: Colors.blue[700],
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            title,
            style: const TextStyle(
              fontFamily: 'GeneralSans',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: 'GeneralSans',
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontFamily: 'GeneralSans',
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeThumbColor: const Color(0xFF3B82F6),
    );
  }

  Widget _buildDropdownTile({
    required String title,
    required String subtitle,
    required int value,
    required List<DropdownMenuItem<int>> items,
    required ValueChanged<int?> onChanged,
  }) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: 'GeneralSans',
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontFamily: 'GeneralSans',
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
      trailing: DropdownButton<int>(
        value: value,
        items: items,
        onChanged: onChanged,
        underline: Container(),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: 'GeneralSans',
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontFamily: 'GeneralSans',
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: 'GeneralSans',
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontFamily: 'GeneralSans',
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildDataItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const Text('• ', style: TextStyle(fontSize: 16)),
          Text(
            text,
            style: TextStyle(
              fontFamily: 'GeneralSans',
              fontSize: 12,
              color: Colors.blue[900],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showClearDataDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Clear Wellness History?',
          style: TextStyle(fontFamily: 'GeneralSans'),
        ),
        content: const Text(
          'This will permanently delete all your wellness data including state history and statistics. This action cannot be undone.',
          style: TextStyle(fontFamily: 'GeneralSans'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // Clear wellness history
      await ref.read(wellnessStateProvider.notifier).clearHistory();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Wellness history cleared'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
}
