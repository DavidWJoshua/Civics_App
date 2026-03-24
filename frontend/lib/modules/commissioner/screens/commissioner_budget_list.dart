import 'package:flutter/material.dart';
import '../services/commissioner_service.dart';
import 'commissioner_complaint_details.dart';
import '../../../core/theme/app_colors.dart';

class CommissionerBudgetList extends StatefulWidget {
  const CommissionerBudgetList({super.key});

  @override
  State<CommissionerBudgetList> createState() =>
      _CommissionerBudgetListState();
}

class _CommissionerBudgetListState
    extends State<CommissionerBudgetList> {
  List<dynamic> budgets = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadBudgets();
  }

  Future<void> loadBudgets() async {
    try {
      final data = await CommissionerService.getPendingBudgets();
      setState(() {
        budgets = data;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
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
        title: const Text("Budget Approvals"),
      ),
      body: budgets.isEmpty
          ? const Center(child: Text("No pending budgets"))
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              itemCount: budgets.length,
              itemBuilder: (ctx, i) {
                final b = budgets[i];

                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(20),
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: const Icon(Icons.currency_rupee, color: AppColors.primary),
                    ),
                    title: Text(
                      "Complaint ID: ${b['complaint_id']}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text("Estimated Cost: ₹${b['estimated_cost']}"),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              CommissionerComplaintDetails(
                            complaintId: b['complaint_id'],
                          ),
                        ),
                      ).then((_) => loadBudgets());
                    },
                  ),
                );
              },
            ),
    );
  }
}
