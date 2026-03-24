import 'package:flutter/material.dart';
import '../services/commissioner_service.dart';
import '../../../core/utils/api_constants.dart';
import '../../../core/theme/app_colors.dart';

class CommissionerAllComplaints extends StatefulWidget {
  const CommissionerAllComplaints({super.key});

  @override
  State<CommissionerAllComplaints> createState() =>
      _CommissionerAllComplaintsState();
}

class _CommissionerAllComplaintsState
    extends State<CommissionerAllComplaints> {
  List<dynamic> complaints = [];
  bool loading = true;
  Map<String, dynamic> filters = {};

  final areaCtrl = TextEditingController();
  String? selectedWard;
  final startDateCtrl = TextEditingController();
  final endDateCtrl = TextEditingController();
  String? selectedSeverity;
  String? selectedCategory;

  List<String> allowedWards = [];
  bool loadingProfile = true;

  @override
  @override
  void initState() {
    super.initState();
    _loadProfileAndComplaints();
  }

  Future<void> _loadProfileAndComplaints() async {
    try {
      final profile = await CommissionerService.getProfile();
      if (profile['ward_from'] != null && profile['ward_to'] != null) {
        final int from = profile['ward_from'];
        final int to = profile['ward_to'];
        if (to >= from) {
          allowedWards =
              List.generate(to - from + 1, (i) => (from + i).toString());
        }
      }
    } catch (e) {
      debugPrint("Error loading profile details: $e");
    } finally {
      if (mounted) {
        setState(() => loadingProfile = false);
      }
      loadComplaints();
    }
  }

  Future<void> loadComplaints() async {
    try {
      final data = await CommissionerService.getAllComplaints(filters);
      setState(() {
        complaints = data;
        loading = false;
      });
    } catch (e) {
      debugPrint("Error loading complaints: $e");
      setState(() => loading = false);
    }
  }

  String fixImage(String? path) {
    if (path == null || path.isEmpty) return "";
    if (path.contains("fe_uploads/")) {
      final cleanPath = path.substring(path.indexOf("fe_uploads/"));
      return "${ApiConstants.baseUrl}/$cleanPath";
    }
    if (path.contains("uploads/")) {
      final idx = path.indexOf("uploads/");
      if (idx == 0 || path[idx - 1] == '/') {
        final cleanPath = path.substring(idx);
        return "${ApiConstants.baseUrl}/$cleanPath";
      }
    }
    if (path.startsWith("http")) return path;
    if (!path.startsWith('/')) return "${ApiConstants.baseUrl}/$path";
    return "${ApiConstants.baseUrl}$path";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("All Complaints"),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : complaints.isEmpty
              ? const Center(child: Text("No complaints"))
                : ListView.builder(
                    itemCount: complaints.length,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    itemBuilder: (context, i) {
                      final c = complaints[i];

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                              Text(
                                c['category'] ?? "General",
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text("ID: ${c['id']}", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                              Text("Ward: ${c['ward'] ?? 'N/A'}", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                              const SizedBox(height: 4),
                              _statusBadge(c['status'] ?? 'UNKNOWN'),
                            const SizedBox(height: 10),

                            // BEFORE IMAGE
                            if (c['image_url'] != null &&
                                c['image_url'].toString().isNotEmpty)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Before",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      fixImage(c['image_url']),
                                      height: 200,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        height: 200,
                                        color: Colors.grey.shade200,
                                        child: const Center(
                                            child: Icon(Icons.broken_image,
                                                color: Colors.grey)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                ],
                              ),

                            // AFTER IMAGE
                            if (c['completion_photo_url'] != null &&
                                c['completion_photo_url']
                                    .toString()
                                    .isNotEmpty)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("After",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      fixImage(c['completion_photo_url']),
                                      height: 200,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        height: 200,
                                        color: Colors.grey.shade200,
                                        child: const Center(
                                            child: Icon(Icons.broken_image,
                                                color: Colors.grey)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                            /// RATING & FEEDBACK
                            if (c['rating'] != null && c['rating'] > 0)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 10),
                                  const Divider(),
                                  Row(
                                    children: [
                                      const Text("Citizen Rating: ",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      ...List.generate(5, (index) {
                                        return Icon(
                                          index < (c['rating'] ?? 0)
                                              ? Icons.star
                                              : Icons.star_border,
                                          color: Colors.amber,
                                          size: 20,
                                        );
                                      }),
                                    ],
                                  ),
                                  if (c['feedback'] != null &&
                                      c['feedback'].toString().isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Text(
                                        "\"${c['feedback']}\"",
                                        style: const TextStyle(
                                            fontStyle: FontStyle.italic,
                                            color: Colors.grey),
                                      ),
                                    ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Filter Complaints",
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(
                  controller: areaCtrl,
                  decoration: const InputDecoration(labelText: "Area"),
                ),
                loadingProfile
                    ? const Center(child: CircularProgressIndicator())
                    : DropdownButtonFormField<String>(
                        value: selectedWard,
                        decoration: const InputDecoration(labelText: "Ward"),
                        items: allowedWards.isEmpty
                            ? []
                            : allowedWards
                                .map((e) =>
                                    DropdownMenuItem(value: e, child: Text(e)))
                                .toList(),
                        onChanged: (v) => setState(() => selectedWard = v),
                        hint: allowedWards.isEmpty
                            ? const Text("No wards assigned")
                            : null,
                      ),
                DropdownButtonFormField<String>(
                  value: selectedSeverity,
                  decoration: const InputDecoration(labelText: "Severity"),
                  items: ["Low", "Medium", "High"]
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => selectedSeverity = v,
                ),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(labelText: "Category"),
                  items: [
                    "Pipe Breakage",
                    "Leakage",
                    "Overflow",
                    "Sinkhole",
                    "Manhole Missing",
                    "Clogged Drain",
                    "Others"
                  ]
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => selectedCategory = v,
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: startDateCtrl,
                        decoration:
                            const InputDecoration(labelText: "Start Date"),
                        readOnly: true,
                        onTap: () async {
                          final d = await showDatePicker(
                              context: context,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now());
                          if (d != null) {
                            startDateCtrl.text =
                                d.toIso8601String().split('T')[0];
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: endDateCtrl,
                        decoration:
                            const InputDecoration(labelText: "End Date"),
                        readOnly: true,
                        onTap: () async {
                          final d = await showDatePicker(
                              context: context,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now());
                          if (d != null) {
                            endDateCtrl.text =
                                d.toIso8601String().split('T')[0];
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          areaCtrl.clear();
                          selectedWard = null;
                          startDateCtrl.clear();
                          endDateCtrl.clear();
                          selectedSeverity = null;
                          selectedCategory = null;
                          filters.clear();
                        });
                        Navigator.pop(context);
                        loadComplaints();
                      },
                      child: const Text("Clear"),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          filters = {
                            "area": areaCtrl.text,
                            "ward": selectedWard,
                            "severity": selectedSeverity,
                            "category": selectedCategory,
                            "start_date": startDateCtrl.text,
                            "end_date": endDateCtrl.text,
                          };
                        });
                        Navigator.pop(context);
                        loadComplaints();
                      },
                      child: const Text("Apply"),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _statusBadge(String status) {
    Color color;
    IconData icon;
    switch (status.toUpperCase()) {
      case 'COMPLETED':
      case 'RESOLVED':
        color = AppColors.success;
        icon = Icons.check_circle;
        break;
      case 'IN_PROGRESS':
        color = AppColors.secondary;
        icon = Icons.hourglass_top;
        break;
      case 'RAISED':
        color = AppColors.warning;
        icon = Icons.pending;
        break;
      default:
        color = AppColors.error;
        icon = Icons.cancel;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 5),
          Text(
            status.toUpperCase(),
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
