import 'package:flutter/material.dart';
import '../../../../core/utils/token_storage.dart';
import '../../citizen/screens/citizen_login_phone.dart';
import '../services/officer_service.dart';
import 'complaint_list.dart';
import 'leave_history_screen.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/staff_profile_screen.dart';

class OfficerDashboard extends StatefulWidget {
  const OfficerDashboard({super.key});

  @override
  State<OfficerDashboard> createState() => _OfficerDashboardState();
}

class _OfficerDashboardState extends State<OfficerDashboard> {
  Map<String, dynamic>? profile;
  Map<String, dynamic>? stats;
  bool isOnLeave = false;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    try {
      final p = await OfficerService.getProfile();
      final s = await OfficerService.getStats();
      
      // Check leave status
      final history = await OfficerService.getLeaveHistory();
      final now = DateTime.now();
      bool onLeave = false;
      for (var l in history) {
        if (l['status'] == 'APPROVED') {
          final from = DateTime.parse(l['from_date']);
          final to = DateTime.parse(l['to_date']);
          if (now.isAfter(from.subtract(const Duration(days: 1))) && 
              now.isBefore(to.add(const Duration(days: 1)))) {
            onLeave = true;
            break;
          }
        }
      }

      if (mounted) {
        setState(() {
          profile = p;
          stats = s;
          isOnLeave = onLeave;
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => loading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error: $e")));
      }
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            if (isOnLeave) _buildLeaveBanner(),
            const SizedBox(height: 16),
            _buildStatsGrid(),
            const SizedBox(height: 16),
            _buildActions(),
            const SizedBox(height: 40), // extra bottom spacing
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white,
            child: Icon(Icons.person, size: 36, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile?['name'] ?? "Field Officer",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Shift: ${profile?['shift'] ?? '-'}",
                  style: const TextStyle(color: Colors.white70),
                ),
                Text(
                  "Active: ${profile?['is_active'] == true ? 'Yes' : 'No'}",
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            tooltip: 'My Profile',
            onPressed: () {
              final merged = <String, dynamic>{};
              if (profile != null) merged.addAll(profile!);
              if (stats != null) merged.addAll(stats!);
              merged['designation'] = 'Field Officer';
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StaffProfileScreen(
                    role: 'Field Officer',
                    profileData: merged,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.beach_access, color: Colors.white),
            onPressed: () => _showApplyLeaveDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
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
    );
  }

  Widget _buildStatsGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.3,
        children: [
          _statCard("Raised", stats?['raised'] ?? 0, AppColors.warning),
          _statCard("In Progress", stats?['not_completed'] ?? 0, AppColors.secondary),
          _statCard("Completed", stats?['completed'] ?? 0, AppColors.success),
          _statCard("Rejected", stats?['rejected'] ?? 0, AppColors.error),
        ],
      ),
    );
  }

  Widget _statCard(String title, int count, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
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
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _actionTile(
            title: "New Work Orders",
            subtitle: "Complaints waiting for acceptance",
            icon: Icons.assignment,
            color: AppColors.warning,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const ComplaintListScreen(type: 'RAISED'),
                ),
              ).then((_) => loadData());
            },
          ),
          const SizedBox(height: 12),
          _actionTile(
            title: "To-Do List",
            subtitle: "Accepted work orders in progress",
            icon: Icons.playlist_add_check,
            color: AppColors.secondary,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const ComplaintListScreen(type: 'TODO'),
                ),
              ).then((_) => loadData());
            },
          ),
          const SizedBox(height: 12),
          _actionTile(
            title: "Completed Work",
            subtitle: "Successfully completed complaints",
            icon: Icons.check_circle,
            color: AppColors.success,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const ComplaintListScreen(type: 'COMPLETED'),
                ),
              ).then((_) => loadData());
            },
          ),
          const SizedBox(height: 12),
          _actionTile(
            title: "Rejected Complaints",
            subtitle: "Complaints rejected by you",
            icon: Icons.cancel,
            color: AppColors.error,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const ComplaintListScreen(type: 'REJECTED'),
                ),
              ).then((_) => loadData());
            },
          ),
          _actionTile(
            title: "My Leave History",
            subtitle: "Check status of leave applications",
            icon: Icons.history,
            color: Colors.blueGrey,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const LeaveHistoryScreen(), // ✅ UPDATED
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.amber.shade900),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              "You are currently on Approved Leave. Work actions are restricted.",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  void _showApplyLeaveDialog() {
    final daysController = TextEditingController();
    final reasonController = TextEditingController();
    DateTime? fromDate;
    DateTime? toDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Apply for Leave",
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Your application will be sent to the Sanitary Inspector for approval. You will remain active until approved.",
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 90)),
                        );
                        if (picked != null) {
                          setDialogState(() => fromDate = picked);
                        }
                      },
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(fromDate == null
                          ? "From"
                          : "${fromDate!.day}/${fromDate!.month}"),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: fromDate ?? DateTime.now(),
                          firstDate: fromDate ?? DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 90)),
                        );
                        if (picked != null) {
                          setDialogState(() => toDate = picked);
                        }
                      },
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(toDate == null
                          ? "To"
                          : "${toDate!.day}/${toDate!.month}"),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                decoration: InputDecoration(
                  hintText: "Reason for leave",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.all(12),
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (fromDate == null || toDate == null || reasonController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please fill all fields")),
                  );
                  return;
                }
                
                try {
                  await OfficerService.applyLeave(
                    fromDate!.toIso8601String().split('T')[0],
                    toDate!.toIso8601String().split('T')[0],
                    reasonController.text,
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Application submitted")),
                    );
                    loadData();
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Error: $e")),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(0, 48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text("Submit Application",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
