import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import '../services/officer_service.dart';
import 'complaint_detail.dart';
import '../../../../core/theme/app_colors.dart';

class ComplaintListScreen extends StatefulWidget {
  final String type;

  const ComplaintListScreen({super.key, required this.type});

  @override
  State<ComplaintListScreen> createState() => _ComplaintListScreenState();
}

class _ComplaintListScreenState extends State<ComplaintListScreen> {
  List<dynamic> complaints = [];
  bool loading = true;
  Map<String, dynamic> filters = {};

  final areaCtrl = TextEditingController();
  // final wardCtrl = TextEditingController(); // REMOVED
  String? selectedWard; // NEW
  final startDateCtrl = TextEditingController();
  final endDateCtrl = TextEditingController();
  String? selectedSeverity;
  String? selectedCategory;

  List<String> allowedWards = []; // NEW
  bool loadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadProfileAndComplaints();
  }

  Future<void> _loadProfileAndComplaints() async {
    try {
      final profile = await OfficerService.getProfile();
      if (profile['ward_from'] != null && profile['ward_to'] != null) {
        final int from = profile['ward_from'];
        final int to = profile['ward_to'];
        if (to >= from) {
          allowedWards =
              List.generate(to - from + 1, (i) => (from + i).toString());
        } else {
           debugPrint("Invalid ward range: $from - $to");
        }
      }
    } catch (e) {
      debugPrint("Error loading profile for wards: $e");
    } finally {
      if (mounted) {
        setState(() => loadingProfile = false);
      }
      loadComplaints();
    }
  }

  Future<void> loadComplaints() async {
    try {
      late List<dynamic> data;

      switch (widget.type) {
        case 'RAISED':
          data = await OfficerService.getRaisedComplaints(filters);
          break;
        case 'TODO':
          data = await OfficerService.getToDoComplaints(filters);
          break;
        case 'COMPLETED':
          data = await OfficerService.getCompletedComplaints(filters);
          break;
        case 'REJECTED':
          data = await OfficerService.getRejectedComplaints(filters);
          break;
        default:
          data = [];
      }

      if (mounted) {
        setState(() {
          complaints = data;
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => loading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  String _getTitle() {
    switch (widget.type) {
      case 'RAISED':
        return "Assigned Complaints";
      case 'TODO':
        return "My To-Do List";
      case 'COMPLETED':
        return "Completed Complaints";
      case 'REJECTED':
        return "Rejected Complaints";
      default:
        return "Complaints";
    }
  }

  Future<void> _quickNavigate(Map<String, dynamic> c) async {
    final lat = c['latitude'];
    final lng = c['longitude'];

    if (lat == null || lng == null || (lat == 0.0 && lng == 0.0)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No valid coordinates found.")),
        );
      }
      return;
    }

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Location permission denied.")),
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final origin = '${position.latitude},${position.longitude}';
      final destination = '$lat,$lng';
      final Uri url = Uri.parse("https://www.google.com/maps/dir/?api=1&origin=$origin&destination=$destination&travelmode=driving");

      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Could not launch Maps app")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text("Error routing: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle()),
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
              ? const Center(child: Text("No complaints found"))
              : ListView.builder(
                  itemCount: complaints.length,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  itemBuilder: (context, index) {
                    final c = complaints[index];

                    return Card(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.grey.shade200,
                              ),
                              child: Builder(
                                builder: (context) {
                                  final img = (c['completion_photo_url'] != null && c['completion_photo_url'].toString().isNotEmpty) 
                                      ? c['completion_photo_url'] 
                                      : c['photo_url'];
                                  return img != null && img.toString().isNotEmpty
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.network(
                                            OfficerService.fixImage(img),
                                            width: 60,
                                            height: 60,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                const Icon(Icons.broken_image,
                                                    size: 30, color: Colors.grey),
                                          ),
                                        )
                                      : const Icon(Icons.image_not_supported,
                                          size: 30, color: Colors.grey);
                                },
                              ),
                            ),
                            title: Text(
                              c['category'] ?? "Complaint",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              "${c['area'] ?? ''} • ${c['severity'] ?? ''} • Ward: ${c['ward'] ?? 'N/A'}",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: widget.type == 'TODO'
                                ? IconButton(
                                    icon: const Icon(Icons.directions, color: Colors.blue),
                                    onPressed: () => _quickNavigate(c),
                                  )
                                : Icon(Icons.arrow_forward_ios,
                                    size: 16, color: Colors.grey.shade400),
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ComplaintDetailScreen(
                                    complaint: c,
                                    type: widget.type,
                                  ),
                                ),
                              );
                              loadComplaints();
                            },
                          ),
                          if (widget.type == 'COMPLETED' &&
                              c['rating'] != null &&
                              c['rating'] > 0)
                            Padding(
                              padding: const EdgeInsets.only(
                                  left: 16.0, right: 16.0, bottom: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
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
                            ),
                        ],
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
              left: 16,
              right: 16,
              top: 16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Filter Complaints",
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
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
                        decoration: InputDecoration(
                          labelText: "Start Date",
                          prefixIcon: const Icon(Icons.calendar_today, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
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
                        decoration: InputDecoration(
                          labelText: "End Date",
                          prefixIcon: const Icon(Icons.calendar_today, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
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
                          // wardCtrl.clear();
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: const Text("Apply Filters"),
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
}
