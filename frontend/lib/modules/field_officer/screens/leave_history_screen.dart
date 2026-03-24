import 'package:flutter/material.dart';
import '../services/officer_service.dart';
import '../../../../core/theme/app_colors.dart';

class LeaveHistoryScreen extends StatefulWidget {
  const LeaveHistoryScreen({super.key});

  @override
  State<LeaveHistoryScreen> createState() => _LeaveHistoryScreenState();
}

class _LeaveHistoryScreenState extends State<LeaveHistoryScreen> {
  List<dynamic>? history;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  Future<void> loadHistory() async {
    try {
      final data = await OfficerService.getLeaveHistory();
      setState(() {
        history = data;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Leave History"),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : history == null || history!.isEmpty
              ? const Center(child: Text("No leave history found"))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  itemCount: history!.length,
                  itemBuilder: (context, index) {
                    final leave = history![index];
                    return _leaveCard(leave);
                  },
                ),
    );
  }

  Widget _leaveCard(dynamic leave) {
    final status = leave['status'] ?? "PENDING";
    final color = status == "APPROVED"
        ? AppColors.success
        : status == "REJECTED"
            ? AppColors.error
            : AppColors.warning;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withOpacity(0.1),
                  child: Icon(Icons.history, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${leave['from_date']} to ${leave['to_date']}",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Status: $status",
                        style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w600,
                            fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Text(
                  leave['created_at'] != null 
                      ? leave['created_at'].toString().split('T')[0]
                      : "",
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            const Divider(height: 24),
            Text(
              "Reason: ${leave['reason'] ?? '-'}",
              style: const TextStyle(color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}
