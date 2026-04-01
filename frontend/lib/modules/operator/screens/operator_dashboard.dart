import 'package:flutter/material.dart';
import '../../../core/utils/token_storage.dart';
import '../../citizen/screens/citizen_login_phone.dart';
import '../models/operator_models.dart';
import '../services/operator_service.dart';
import 'operator_task_list.dart';
import 'profile_screen.dart';
import '../../../core/theme/app_colors.dart';

class OperatorDashboard extends StatefulWidget {
  const OperatorDashboard({super.key});

  @override
  State<OperatorDashboard> createState() => _OperatorDashboardState();
}

class _OperatorDashboardState extends State<OperatorDashboard> {
  String role = "";
  List<Station> stations = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final r = await TokenStorage.getRole();
    if (r == null) {
        _logout();
        return;
    }
    
    try {
      final allStations = await OperatorService.getStations();
      if (!mounted) return;
      
      String requiredType = "";
      if (r == "LIFTING_OPERATOR") requiredType = "lifting";
      else if (r == "PUMPING_OPERATOR") requiredType = "pumping";
      else if (r == "STP_OPERATOR") requiredType = "stp";

      setState(() {
        role = r;
        stations = allStations.where((s) => s.type == requiredType).toList();
        loading = false;
      });

      if (stations.isNotEmpty && mounted) {
         // Auto-redirect to the first station's task list
         Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => OperatorTaskList(station: stations.first)),
         );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
        setState(() => loading = false);
      }
    }
  }

  Future<void> _logout() async {
    await TokenStorage.clear();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const CitizenLoginPhone()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(role.replaceAll("_", " ")),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : stations.isEmpty
              ? const Center(child: Text("No assigned stations found."))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  itemCount: stations.length,
                  itemBuilder: (context, index) {
                    final station = stations[index];
                    return Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          child: const Icon(Icons.water_drop, color: AppColors.primary),
                        ),
                        title: Text(
                          station.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Text("Ward: ${station.wardNumber}"),
                        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => OperatorTaskList(station: station)),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
