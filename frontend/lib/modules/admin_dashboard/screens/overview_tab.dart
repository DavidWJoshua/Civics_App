import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../widgets/kpi_card.dart';
import '../../../core/theme/app_colors.dart';

class OverviewTab extends StatefulWidget {
  const OverviewTab({Key? key}) : super(key: key);

  @override
  State<OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<OverviewTab> {
  final AdminService _adminService = AdminService();
  Map<String, dynamic>? _stats;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await _adminService.getOverviewStats();
      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text('Error: $_error'));
    if (_stats == null) return const Center(child: Text('No data available'));

    final total = _stats!['total_complaints'] ?? 0;
    final slaBreaches = _stats!['sla_breaches'] ?? 0;
    final activeEscalations = _stats!['active_escalations'] ?? 0;
    final pendingBudgets = _stats!['pending_budgets'] ?? 0;
    final statusCounts = _stats!['status_counts'] as Map<String, dynamic>? ?? {};

    return RefreshIndicator(
      onRefresh: _loadStats,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Key Performance Indicators",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                KpiCard(
                  title: "Total Complaints",
                  value: total.toString(),
                  icon: Icons.folder_open,
                  color: AppColors.primary,
                ),
                KpiCard(
                  title: "Unresolve Rate",
                  value: "${getResolutionRate(total, statusCounts)}%",
                  icon: Icons.check_circle,
                  color: AppColors.success,
                ),
                KpiCard(
                  title: "SLA Completion",
                  value: slaBreaches.toString(),
                  icon: Icons.timer_off,
                  color: AppColors.error,
                ),
                KpiCard(
                  title: "Pending Budgets",
                  value: pendingBudgets.toString(),
                  icon: Icons.attach_money,
                  color: AppColors.warning,
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              "Status Breakdown",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            // Simple Bar Chart or List for verification
            ...statusCounts.entries.map((e) => ListTile(
              title: Text(e.key),
              trailing: Text(e.value.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
              leading: Icon(Icons.circle, size: 12),
            )).toList(),
          ],
        ),
      ),
    );
  }

  String getResolutionRate(int total, Map<String, dynamic> counts) {
    if (total == 0) return "0";
    final resolved = (counts['RESOLVED'] ?? 0) + (counts['CLOSED'] ?? 0);
    return ((resolved / total) * 100).toStringAsFixed(1);
  }
}
