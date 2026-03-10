import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/officer_service.dart';
import '../../../../core/theme/app_colors.dart';

class ComplaintDetailScreen extends StatefulWidget {
  final Map<String, dynamic> complaint;
  final String type; // 'RAISED', 'TODO', 'COMPLETED', 'REJECTED'

  const ComplaintDetailScreen({
    super.key,
    required this.complaint,
    required this.type,
  });

  @override
  State<ComplaintDetailScreen> createState() => _ComplaintDetailScreenState();
}

class _ComplaintDetailScreenState extends State<ComplaintDetailScreen> {
  bool loading = false;
  bool isOnLeave = false;
  final costCtrl = TextEditingController();
  final daysCtrl = TextEditingController();
  final reasonCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkLeaveStatus();
  }

  Future<void> _checkLeaveStatus() async {
    try {
      final history = await OfficerService.getLeaveHistory();
      final now = DateTime.now();
      bool onLeave = false;
      for (var l in history) {
        if (l['status'] == 'APPROVED') {
          final from = DateTime.parse(l['from_date']);
          final to = DateTime.parse(l['to_date']);
          if (now.isAfter(from.subtract(const Duration(days: 1))) && 
              now.isBefore(to.add(const Duration(days: 1)))) {
            onLeave = true;
            break;
          }
        }
      }
      if (mounted) setState(() => isOnLeave = onLeave);
    } catch (e) {
      debugPrint("Error checking leave: $e");
    }
  }

  void _showLeavePopup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.amber),
            SizedBox(width: 10),
            Text("Action Restricted"),
          ],
        ),
        content: const Text(
          "You are currently on approved leave. You cannot accept, reject, or complete work orders until your leave period is over.",
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Future<void> _acceptComplaint() async {
    if (costCtrl.text.isEmpty || daysCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter estimated cost & days")),
      );
      return;
    }

    setState(() => loading = true);

    try {
      await OfficerService.acceptComplaint(
        widget.complaint['id'],
        double.parse(costCtrl.text),
        int.parse(daysCtrl.text),
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Complaint accepted")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _rejectComplaint() async {
    if (reasonCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter rejection reason")),
      );
      return;
    }

    setState(() => loading = true);

    try {
      await OfficerService.rejectComplaint(
        widget.complaint['id'],
        reasonCtrl.text,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Complaint rejected")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _completeComplaint() async {
    setState(() => loading = true);

    try {
      final picker = ImagePicker();
      final photo =
          await picker.pickImage(source: ImageSource.camera, imageQuality: 60);

      if (photo == null) {
        setState(() => loading = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      await OfficerService.completeComplaint(
        widget.complaint['id'],
        photo.path, //THIS is the real file path
        position.latitude,
        position.longitude,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Work completed successfully")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _navigateToComplaint() async {
    final lat = widget.complaint['latitude'];
    final lng = widget.complaint['longitude'];

    if (lat == null || lng == null || (lat == 0.0 && lng == 0.0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No valid location coordinates found for this complaint.")),
      );
      return;
    }

    setState(() => loading = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location permission denied. Cannot calculate route.")),
        );
        setState(() => loading = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final origin = '${position.latitude},${position.longitude}';
      final destination = '$lat,$lng';
      
      // Google Maps Route URL
      final Uri googleMapsUrl = Uri.parse("https://www.google.com/maps/dir/?api=1&origin=$origin&destination=$destination&travelmode=driving");

      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not launch Maps app")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text("Error routing: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.complaint;

    return Scaffold(
      appBar: AppBar(title: const Text("Complaint Details")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (c['photo_url'] != null &&
                c['photo_url'].toString().isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  OfficerService.fixImage(c['photo_url']),
                  height: 250, // Fixed height for consistency
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 250,
                    width: double.infinity,
                    color: Colors.grey.shade200,
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image, size: 50, color: Colors.grey),
                        SizedBox(height: 8),
                        Text("Image Failed to Load"),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            if (c['completion_photo_url'] != null &&
                c['completion_photo_url'].toString().isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  const Text(
                    "Completion Image",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      OfficerService.fixImage(c['completion_photo_url']),
                      height: 250,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 250,
                        width: double.infinity,
                        color: Colors.grey.shade200,
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image,
                                size: 50, color: Colors.grey),
                            SizedBox(height: 8),
                            Text("Image Failed to Load"),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            Text(
              "Severity: ${c['severity']}",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: c['severity']?.toString().toUpperCase() == 'HIGH'
                    ? AppColors.error
                    : c['severity']?.toString().toUpperCase() == 'MEDIUM'
                        ? AppColors.warning
                        : AppColors.success,
              ),
            ),

            const SizedBox(height: 12),
            Text("Area: ${c['area']}"),
            Text("Ward: ${c['ward'] ?? 'N/A'}"), // ✅ ADDED WARD
            Text("Status: ${c['status']}"),

            // ✅ ADDED: REJECTION REASON DISPLAY
            if (widget.type == 'REJECTED' &&
                c['rejection_reason'] != null &&
                c['rejection_reason'].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error.withOpacity(0.1)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, color: AppColors.error, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Rejection Reason: ${c['rejection_reason']}",
                          style: const TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            Text("Created at: ${c['created_at']}"),
            const SizedBox(height: 12),

             // ✅ ADDED: RATING & FEEDBACK
            if (c['rating'] != null && c['rating'] > 0)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text("Citizen Rating: ",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(width: 8),
                        ...List.generate(5, (index) {
                          return Icon(
                            index < (c['rating'] ?? 0)
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                            size: 24,
                          );
                        }),
                      ],
                    ),
                    if (c['feedback'] != null &&
                        c['feedback'].toString().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: Text(
                          "\"${c['feedback']}\"",
                          style: const TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.black87,
                            fontSize: 15,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

            const SizedBox(height: 30),

            // ACTION SECTION
            if (widget.type == 'RAISED') ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: loading
                          ? null
                          : () {
                              if (isOnLeave) {
                                _showLeavePopup();
                                return;
                              }
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text("Accept Work Order"),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      TextField(
                                        controller: costCtrl,
                                        decoration:
                                            const InputDecoration(
                                                labelText:
                                                    "Estimated Cost (₹)"),
                                        keyboardType:
                                            TextInputType.number,
                                      ),
                                      const SizedBox(height: 10),
                                      TextField(
                                        controller: daysCtrl,
                                        decoration:
                                            const InputDecoration(
                                                labelText:
                                                    "Estimated Days"),
                                        keyboardType:
                                            TextInputType.number,
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context),
                                      child: const Text("Cancel"),
                                    ),
                                    ElevatedButton(
                                      onPressed: _acceptComplaint,
                                      child: const Text("Accept"),
                                    ),
                                  ],
                                ),
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("Accept Work Order", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: loading
                          ? null
                          : () {
                              if (isOnLeave) {
                                _showLeavePopup();
                                return;
                              }
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text("Reject Work Order"),
                                  content: TextField(
                                    controller: reasonCtrl,
                                    decoration:
                                        const InputDecoration(
                                            labelText: "Reason"),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context),
                                      child: const Text("Cancel"),
                                    ),
                                    ElevatedButton(
                                      onPressed: _rejectComplaint,
                                      child: const Text("Reject"),
                                    ),
                                  ],
                                ),
                              );
                            },
                      child: const Text("Reject Work Order", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ] else if (widget.type == 'TODO') ...[
              Row(
                children: [
                   Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.map_outlined),
                      label: const Text("Navigate", style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: loading ? null : _navigateToComplaint,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.camera_alt),
                      label: const Text("Complete", style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: loading
                          ? null
                          : () {
                              if (isOnLeave) {
                                _showLeavePopup();
                                return;
                              }
                              _completeComplaint();
                            },
                    ),
                  ),
                ],
              ),
            ] else ...[
              const Center(
                child: Text(
                  "This complaint is closed.",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
