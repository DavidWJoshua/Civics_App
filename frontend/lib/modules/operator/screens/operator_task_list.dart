import 'package:flutter/material.dart';
import '../../../core/utils/token_storage.dart';
import '../../citizen/screens/citizen_login_phone.dart';
import '../models/operator_models.dart';
import 'lifting_log_form.dart';
import 'pumping_log_form.dart';
import 'stp_log_form.dart';
import '../../../core/theme/app_colors.dart';

class OperatorTaskList extends StatelessWidget {
  final Station station;

  const OperatorTaskList({super.key, required this.station});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${station.name} Tasks"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await TokenStorage.clear();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const CitizenLoginPhone()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          _buildTaskTile(
            context,
            "Daily Log",
            Icons.today,
            "Daily",
          ),
          _buildTaskTile(
            context, 
            "Weekly Log", 
            Icons.calendar_view_week, 
            "Weekly"
          ),
          _buildTaskTile(
            context, 
            "Monthly Log", 
            Icons.calendar_month, 
            "Monthly"
          ),
          _buildTaskTile(
            context, 
            "Yearly Log", 
            Icons.calendar_today, 
            "Yearly"
          ),
        ],
      ),
    );
  }

  Widget _buildTaskTile(BuildContext context, String title, IconData icon, String frequency) {
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
        onTap: () => _navigateToForm(context, frequency),
      ),
    );
  }

  void _navigateToForm(BuildContext context, String frequency) {
    final type = station.type.toLowerCase().trim();
    if (type == "lifting") {
      Navigator.push(context, MaterialPageRoute(builder: (_) => LiftingLogForm(station: station, frequency: frequency)));
    } else if (type == "pumping") {
      Navigator.push(context, MaterialPageRoute(builder: (_) => PumpingLogForm(station: station, frequency: frequency)));
    } else if (type == "stp") {
      Navigator.push(context, MaterialPageRoute(builder: (_) => StpLogForm(station: station, frequency: frequency)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Unknown station type: ${station.type}")));
    }
  }
}
