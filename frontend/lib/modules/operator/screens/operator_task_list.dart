import 'package:flutter/material.dart';
import '../../../core/utils/token_storage.dart';
import '../../citizen/screens/citizen_login_phone.dart';
import '../models/operator_models.dart';
import '../services/operator_service.dart';
import 'lifting_log_form.dart';
import 'pumping_log_form.dart';
import 'stp_log_form.dart';
import '../../../core/theme/app_colors.dart';

class OperatorTaskList extends StatefulWidget {
  final Station station;

  const OperatorTaskList({super.key, required this.station});

  @override
  State<OperatorTaskList> createState() => _OperatorTaskListState();
}

class _OperatorTaskListState extends State<OperatorTaskList> {
  bool loading = true;
  Map<String, bool> completedToday = {
    'daily': false,
    'weekly': false,
    'monthly': false,
    'yearly': false,
  };

  @override
  void initState() {
    super.initState();
    _loadCompletionStatus();
  }

  Future<void> _loadCompletionStatus() async {
    try {
      final status = await OperatorService.getTodayTaskStatus(widget.station.id, widget.station.type);
      if (!mounted) return;
      setState(() {
        completedToday = status;
        loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.station.name} Tasks"),
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
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadCompletionStatus,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                children: [
                  _buildInfoCard(),
                  const SizedBox(height: 16),
                  _buildTaskTile(
                    context,
                    "Daily Log",
                    Icons.today,
                    "daily",
                    "Submit every shift",
                    Colors.blue,
                  ),
                  _buildTaskTile(
                    context,
                    "Weekly Log",
                    Icons.calendar_view_week,
                    "weekly",
                    "Submit once per week",
                    Colors.orange,
                  ),
                  _buildTaskTile(
                    context,
                    "Monthly Log",
                    Icons.calendar_month,
                    "monthly",
                    "Submit once per month",
                    Colors.purple,
                  ),
                  _buildTaskTile(
                    context,
                    "Yearly Log",
                    Icons.calendar_today,
                    "yearly",
                    "Submit once per year",
                    Colors.teal,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary.withOpacity(0.15),
            child: const Icon(Icons.water_drop, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.station.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  "Ward: ${widget.station.wardNumber}  •  Type: ${widget.station.type.toUpperCase()}",
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskTile(
    BuildContext context,
    String title,
    IconData icon,
    String frequency,
    String subtitle,
    Color color,
  ) {
    final done = completedToday[frequency] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: done ? Colors.green.shade200 : Colors.grey.shade200,
          width: 1.5,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.12),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: done ? Colors.green.shade50 : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    done ? Icons.check_circle : Icons.pending,
                    size: 14,
                    color: done ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    done ? "Submitted Today" : "Pending",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: done ? Colors.green.shade700 : Colors.orange.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        trailing: done
            ? const Icon(Icons.check_circle, color: Colors.green, size: 28)
            : Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
        onTap: () async {
          await _navigateToForm(context, frequency);
          _loadCompletionStatus(); // Refresh after returning
        },
      ),
    );
  }

  Future<void> _navigateToForm(BuildContext context, String frequency) async {
    final type = widget.station.type.toLowerCase().trim();
    if (type == "lifting") {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => LiftingLogForm(station: widget.station, frequency: frequency)));
    } else if (type == "pumping") {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => PumpingLogForm(station: widget.station, frequency: frequency)));
    } else if (type == "stp") {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => StpLogForm(station: widget.station, frequency: frequency)));
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Unknown station type: ${widget.station.type}")));
      }
    }
  }
}
