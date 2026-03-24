import 'package:flutter/material.dart';
import '../../../core/utils/token_storage.dart';
import '../services/commissioner_service.dart';
import 'commissioner_budget_list.dart';
import 'commissioner_escalation_list.dart';
import 'commissioner_all_complaints.dart';
import '../../admin_dashboard/screens/admin_dashboard_screen.dart';
import '../../../core/widgets/staff_profile_screen.dart';
import '../../../core/theme/app_colors.dart';

class CommissionerDashboard extends StatefulWidget {
  const CommissionerDashboard({super.key});

  @override
  State<CommissionerDashboard> createState() =>
      _CommissionerDashboardState();
}

class _CommissionerDashboardState extends State<CommissionerDashboard> {
  Map<String, dynamic>? stats;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    try {
      final data = await CommissionerService.getDashboard();
      setState(() {
        stats = data;
        loading = false;
      });
    } catch (_) {
      setState(() => loading = false);
    }
  }

  Future<void> logout() async {
    await TokenStorage.clear();
    if (mounted) {
      Navigator.of(context)
          .pushNamedAndRemoveUntil("/", (route) => false);
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
        title: const Text("Health Inspector Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'My Profile',
            onPressed: () async {
              try {
                final profile = await CommissionerService.getProfile();
                final merged = <String, dynamic>{...profile};
                if (stats != null) merged.addAll(stats!);
                merged['designation'] = 'Commissioner';
                if (mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StaffProfileScreen(
                        role: 'Commissioner',
                        profileData: merged,
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: logout,
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
                _statCard("Budgets", stats?['pending_budgets'], AppColors.warning),
                _statCard("Escalations", stats?['escalations'], AppColors.error),
                _statCard("Completed", stats?['completed'], AppColors.success),
                _statCard("All Active", (stats?['pending_budgets'] ?? 0) + (stats?['escalations'] ?? 0), AppColors.secondary),
              ],
            ),
            const SizedBox(height: 32),

            _navTile("Budget Approvals", Icons.currency_rupee, CommissionerBudgetList()),

            const Divider(),

            _navTile("SLA Escalations", Icons.warning, CommissionerEscalationList()),
            _navTile("All Complaints", Icons.list, CommissionerAllComplaints()),

            const Divider(height: 32),
            _navTile("Analytics Dashboard", Icons.analytics, const AdminDashboardScreen()),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String title, dynamic value, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              (value ?? 0).toString(),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
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
          ).then((_) => loadDashboard());
        },
      ),
    );
  }
}
