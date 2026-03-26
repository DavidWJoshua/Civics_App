import 'package:flutter/material.dart';
import '../services/je_service.dart';
import '../../../core/theme/app_colors.dart';

class JEBudgetList extends StatefulWidget {
  const JEBudgetList({super.key});

  @override
  State<JEBudgetList> createState() => _JEBudgetListState();
}

class _JEBudgetListState extends State<JEBudgetList> {
  List<dynamic> budgets = [];
  bool loading = true;
  final reasonCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadBudgets();
  }

  Future<void> loadBudgets() async {
    try {
      final data = await JEService.getPendingBudgets();
      setState(() {
        budgets = data;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void approve(String id) async {
    await JEService.approveBudget(id);
    loadBudgets();
  }

  void reject(String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Reject Budget"),
        content: TextField(
          controller: reasonCtrl,
          decoration: const InputDecoration(labelText: "Reason"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              await JEService.rejectBudget(id, reasonCtrl.text);
              reasonCtrl.clear();
              Navigator.pop(context);
              loadBudgets();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text("Reject"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Budget Approvals")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : budgets.isEmpty
              ? const Center(child: Text("No pending budgets"))
              : ListView.builder(
                  itemCount: budgets.length,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  itemBuilder: (context, i) {
                    final b = budgets[i];
                    return Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        title: Text(
                          "Complaint ID: ${b['complaint_id']}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text("Estimated Cost: ₹${b['estimated_cost']}"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check_circle_outline, color: AppColors.success),
                              onPressed: () => approve(b['complaint_id']),
                            ),
                            IconButton(
                              icon: const Icon(Icons.cancel_outlined, color: AppColors.error),
                              onPressed: () => reject(b['complaint_id']),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
