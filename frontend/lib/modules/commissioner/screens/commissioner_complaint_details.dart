import 'package:flutter/material.dart';
import '../services/commissioner_service.dart';

class CommissionerComplaintDetails extends StatefulWidget {
  final String complaintId;

  const CommissionerComplaintDetails({
    super.key,
    required this.complaintId,
  });

  @override
  State<CommissionerComplaintDetails> createState() =>
      _CommissionerComplaintDetailsState();
}

class _CommissionerComplaintDetailsState
    extends State<CommissionerComplaintDetails> {
  Map<String, dynamic>? complaint;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadComplaint();
  }

  Future<void> loadComplaint() async {
    try {
      // Reuse budgets list to get complaint info
      final budgets = await CommissionerService.getPendingBudgets();

      final match = budgets.firstWhere(
        (b) => b['complaint_id'] == widget.complaintId,
        orElse: () => null,
      );

      setState(() {
        complaint = match;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
    }
  }

  Future<void> approveBudget() async {
    await CommissionerService.approveBudget(widget.complaintId);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Budget Approved")),
      );
      Navigator.pop(context); // go back to list
    }
  }

  Future<void> rejectBudget(String reason) async {
    await CommissionerService.rejectBudget(widget.complaintId, reason);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Budget Rejected")),
      );
      Navigator.pop(context);
    }
  }

  void showRejectDialog() {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Reject Budget"),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: "Reason",
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text("Reject"),
            onPressed: () {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) return;

              Navigator.pop(context);
              rejectBudget(reason);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (complaint == null) {
      return const Scaffold(
        body: Center(child: Text("Complaint not found")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Complaint Details"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Complaint ID:",
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                Text(widget.complaintId),
                const SizedBox(height: 16),

                Text(
                  "Estimated Cost:",
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                Text("₹${complaint!['estimated_cost']}"),
                const SizedBox(height: 16),

                Text(
                  "Status:",
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                Text(complaint!['status']),
                const Spacer(),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: approveBudget,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        child: const Text("Approve"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: showRejectDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text("Reject"),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
