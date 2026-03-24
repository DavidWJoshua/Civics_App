import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// A reusable profile screen that adapts based on the user's role.
/// It receives the profile data as a Map and displays it in a consistent layout.
class StaffProfileScreen extends StatelessWidget {
  final String role;
  final Map<String, dynamic> profileData;

  const StaffProfileScreen({
    super.key,
    required this.role,
    required this.profileData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$role Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          children: [
            _buildProfileCard(context),
            const SizedBox(height: 24),
            _buildDetailsCard(context),
            if (_hasPerformanceData()) ...[
              const SizedBox(height: 24),
              _buildPerformanceCard(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context) {
    final name = profileData['name'] ?? profileData['full_name'] ?? role;
    final phone = profileData['phone'] ?? profileData['phone_number'] ?? profileData['mobile'] ?? '';
    final designation = profileData['designation'] ?? profileData['role'] ?? role;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 45,
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 50, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              name.toString(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              designation.toString(),
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
            if (phone.toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.phone, size: 16, color: Colors.white70),
                  const SizedBox(width: 6),
                  Text(
                    phone.toString(),
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard(BuildContext context) {
    // Build rows from profileData, excluding certain keys
    final excludeKeys = {'name', 'full_name', 'phone', 'phone_number', 'mobile',
        'designation', 'role', 'id', 'user_id', 'created_at', 'updated_at',
        'deleted_at', 'password', 'token', 'otp',
        'logs_submitted', 'pending_tickets', 'total_faults_reported',
        'performance_score', 'compliance_percentage',
        'completed', 'raised', 'rejected', 'not_completed', 'pending_budgets', 'escalations'};

    final details = <MapEntry<String, dynamic>>[];
    profileData.forEach((key, value) {
      if (!excludeKeys.contains(key) && value != null && value.toString().isNotEmpty) {
        details.add(MapEntry(key, value));
      }
    });

    if (details.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            ...details.map((entry) => _detailRow(
              _formatLabel(entry.key),
              entry.value.toString(),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Performance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.8,
              children: _buildStatCards(),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildStatCards() {
    final statKeys = {
      'completed': {'label': 'Completed', 'icon': Icons.check_circle, 'color': AppColors.success},
      'raised': {'label': 'Raised', 'icon': Icons.pending, 'color': AppColors.warning},
      'rejected': {'label': 'Rejected', 'icon': Icons.cancel, 'color': AppColors.error},
      'not_completed': {'label': 'In Progress', 'icon': Icons.hourglass_top, 'color': AppColors.secondary},
      'pending_budgets': {'label': 'Budgets', 'icon': Icons.attach_money, 'color': AppColors.warning},
      'escalations': {'label': 'Escalations', 'icon': Icons.warning, 'color': AppColors.error},
      'logs_submitted': {'label': 'Logs', 'icon': Icons.description, 'color': AppColors.primary},
      'pending_tickets': {'label': 'Pending', 'icon': Icons.pending_actions, 'color': AppColors.warning},
      'total_faults_reported': {'label': 'Faults', 'icon': Icons.report_problem, 'color': AppColors.error},
    };

    final widgets = <Widget>[];
    statKeys.forEach((key, meta) {
      if (profileData.containsKey(key) && profileData[key] != null) {
        widgets.add(_miniStatCard(
          meta['label'] as String,
          profileData[key].toString(),
          meta['icon'] as IconData,
          meta['color'] as Color,
        ));
      }
    });
    return widgets;
  }

  bool _hasPerformanceData() {
    final perfKeys = ['completed', 'raised', 'rejected', 'not_completed',
        'pending_budgets', 'escalations', 'logs_submitted', 'pending_tickets',
        'total_faults_reported'];
    return perfKeys.any((k) => profileData.containsKey(k) && profileData[k] != null);
  }

  Widget _miniStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
                Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatLabel(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ');
  }
}
