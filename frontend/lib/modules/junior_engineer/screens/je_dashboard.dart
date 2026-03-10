import 'package:flutter/material.dart';
import '../../../core/utils/token_storage.dart';
import '../../citizen/screens/citizen_login_phone.dart';
import '../services/je_service.dart';
import 'je_budget_list.dart';
import 'je_escalation_list.dart';
import 'je_all_complaints.dart';
import 'je_leave_approval_screen.dart';
import 'leave_dashboard.dart';
import '../../admin_dashboard/screens/admin_dashboard_screen.dart';
import '../../../core/widgets/staff_profile_screen.dart';
import '../../../core/theme/app_colors.dart';
import 'je_complaint_reassignment.dart';

class JEDashboard extends StatefulWidget {
  const JEDashboard({super.key});

  @override
  State<JEDashboard> createState() => _JEDashboardState();
}

class _JEDashboardState extends State<JEDashboard> {
  Map<String, dynamic>? stats;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    try {
      final data = await JEService.getDashboard();
      setState(() {
        stats = data;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Junior Engineer"),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'My Profile',
            onPressed: () async {
              try {
                final profile = await JEService.getProfile();
                final merged = <String, dynamic>{...profile};
                if (stats != null) merged.addAll(stats!);
                merged['designation'] = 'Junior Engineer';
                if (context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StaffProfileScreen(
                        role: 'Junior Engineer',
                        profileData: merged,
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await TokenStorage.clear();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const CitizenLoginPhone()),
                  (_) => false,
                );
              }
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          children: [
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.3,
              children: [
                _stat("Pending Budgets",
                    stats?['pending_budgets'] ?? 0, AppColors.warning),
                _stat("Escalations",
                    stats?['escalations'] ?? 0, AppColors.error),
                _stat("Completed",
                    stats?['completed'] ?? 0, AppColors.success),
                _stat("Rejected",
                    stats?['rejected'] ?? 0, Colors.grey),
              ],
            ),
            const SizedBox(height: 24),

            _navTile("Budget Approvals", Icons.currency_rupee,
                const JEBudgetList()),

            _navTile("SLA Escalations", Icons.warning,
                const JEEscalationList()),

            _navTile("All Complaints", Icons.list,
                const JEAllComplaints()),

            _navTile("Complaint Reassignment", Icons.assignment_return,
                const JEComplaintReassignmentScreen()),
                
            _navTile("Leave Approvals", Icons.event_available,
                const JELeaveApprovalScreen()), // ✅ UPDATED

            const SizedBox(height: 24),
            _navTile("Analytics Dashboard", Icons.analytics,
                const AdminDashboardScreen()),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, int count, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _navTile(String title, IconData icon, Widget screen) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.1),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => screen),
          ).then((_) => loadData());
        },
      ),
    );
  }
}
