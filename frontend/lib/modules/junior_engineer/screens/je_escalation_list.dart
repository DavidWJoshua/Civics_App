import 'package:flutter/material.dart';
import '../services/je_service.dart';
import '../../../core/utils/app_errors.dart';
import '../../../core/theme/app_colors.dart';

class JEEscalationList extends StatefulWidget {
  const JEEscalationList({super.key});

  @override
  State<JEEscalationList> createState() => _JEEscalationListState();
}

class _JEEscalationListState extends State<JEEscalationList> {
  List<dynamic> escalations = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadEscalations();
  }

  Future<void> loadEscalations() async {
    try {
      final data = await JEService.getEscalations();
      setState(() {
        escalations = data;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(AppErrors.friendly(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("SLA Escalations")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : escalations.isEmpty
              ? const Center(child: Text("No escalations"))
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
