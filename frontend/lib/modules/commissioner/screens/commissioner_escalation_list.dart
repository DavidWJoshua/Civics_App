import 'package:flutter/material.dart';
import '../services/commissioner_service.dart';
import '../../../core/theme/app_colors.dart';

class CommissionerEscalationList extends StatefulWidget {
  const CommissionerEscalationList({super.key});

  @override
  State<CommissionerEscalationList> createState() =>
      _CommissionerEscalationListState();
}

class _CommissionerEscalationListState
    extends State<CommissionerEscalationList> {
  List<dynamic> escalations = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadEscalations();
  }

  Future<void> loadEscalations() async {
    try {
      final data = await CommissionerService.getEscalations();
      setState(() {
        escalations = data;
        loading = false;
      });
    } catch (_) {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Escalations")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: escalations.length,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              itemBuilder: (context, i) {
                final e = escalations[i];
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(20),
                    leading: CircleAvatar(
                      backgroundColor: AppColors.error.withOpacity(0.1),
                      child: const Icon(Icons.warning_amber_rounded, color: AppColors.error),
                    ),
                    title: Text(
                      "Complaint ID: ${e['complaint_id']}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "From: ${e['from_role']}\nReason: ${e['reason']}",
                    ),
                  ),
                );
              },
            ),
    );
  }
}
