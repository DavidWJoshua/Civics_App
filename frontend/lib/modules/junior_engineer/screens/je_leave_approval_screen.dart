import 'package:flutter/material.dart';
import '../../field_officer/services/officer_service.dart';
import '../../../core/theme/app_colors.dart';

class JELeaveApprovalScreen extends StatefulWidget {
  const JELeaveApprovalScreen({super.key});

  @override
  State<JELeaveApprovalScreen> createState() => _JELeaveApprovalScreenState();
}

class _JELeaveApprovalScreenState extends State<JELeaveApprovalScreen> {
  List<dynamic>? pendingLeaves;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadLeaves();
  }

  Future<void> loadLeaves() async {
    try {
      final data = await OfficerService.jeGetPendingLeaves();
      setState(() {
        pendingLeaves = data;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  Future<void> updateStatus(String id, String status) async {
    try {
      await OfficerService.jeUpdateLeaveStatus(id, status);
      await loadLeaves();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Leave $status successfully")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Leave Applications"),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : pendingLeaves == null || pendingLeaves!.isEmpty
              ? const Center(child: Text("No pending leave applications"))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  itemCount: pendingLeaves!.length,
                  itemBuilder: (context, index) {
                    final leave = pendingLeaves![index];
                    return _approvalCard(leave);
                  },
                ),
    );
  }

  Widget _approvalCard(dynamic leave) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(20),
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.1),
          child: Text(
            (leave['officer_name'] ?? 'F').substring(0, 1).toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
        ),
        title: Text(
          leave['officer_name'] ?? "Field Officer",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          "Applied for ${leave['from_date']} to ${leave['to_date']}\nReason: ${leave['reason'] ?? '-'}",
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.check_circle_outline, color: AppColors.success),
              onPressed: () => _confirmAction(leave['id'], "APPROVED"),
            ),
            IconButton(
              icon: const Icon(Icons.cancel_outlined, color: AppColors.error),
              onPressed: () => _confirmAction(leave['id'], "REJECTED"),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmAction(String id, String status) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Confirm $status"),
        content: Text("Are you sure you want to $status this leave application?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              updateStatus(id, status);
            },
            child: Text(status, style: TextStyle(color: status == "APPROVED" ? AppColors.success : AppColors.error)),
          ),
        ],
      ),
    );
  }
}
