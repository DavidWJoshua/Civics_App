import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../services/je_service.dart';

class JEComplaintReassignmentScreen extends StatefulWidget {
  const JEComplaintReassignmentScreen({super.key});

  @override
  State<JEComplaintReassignmentScreen> createState() =>
      _JEComplaintReassignmentScreenState();
}

class _JEComplaintReassignmentScreenState extends State<JEComplaintReassignmentScreen> {
  List<dynamic> complaints = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadComplaints();
  }

  Future<void> loadComplaints() async {
    try {
      final data = await JEService.getComplaintsForReassignment();
      setState(() {
        complaints = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showReassignDialog(String complaintId, String currentWard, String area) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return _ReassignBottomSheet(
          complaintId: complaintId,
          ward: currentWard,
          area: area,
          onReassigned: () {
            Navigator.pop(context);
            loadComplaints();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Complaint Reassignment")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : complaints.isEmpty
              ? const Center(child: Text("No complaints pending reassignment.", style: TextStyle(fontSize: 16, color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: complaints.length,
                  itemBuilder: (context, index) {
                    final c = complaints[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    c['category'] ?? 'N/A',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ),
                                _buildStatusChip(c['status']),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text("Area: ${c['area']} (Ward ${c['ward']})"),
                            Text("Severity: ${c['severity']}"),
                            Text("Raised: ${_formatDate(c['created_at'])}"),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => _showReassignDialog(c['id'], c['ward'].toString(), c['area'].toString()),
                                icon: const Icon(Icons.assignment_return),
                                label: const Text("Reassign Officer"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildStatusChip(String? status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange)
      ),
      child: const Text("Pending Reassignment", style: TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.bold)),
    );
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return 'Unknown Date';
    try {
      final date = DateTime.parse(isoDate).toLocal();
      return DateFormat('dd MMM yyyy, hh:mm a').format(date);
    } catch (_) {
      return isoDate;
    }
  }
}

class _ReassignBottomSheet extends StatefulWidget {
  final String complaintId;
  final String ward;
  final String area;
  final VoidCallback onReassigned;

  const _ReassignBottomSheet({required this.complaintId, required this.ward, required this.area, required this.onReassigned});

  @override
  State<_ReassignBottomSheet> createState() => _ReassignBottomSheetState();
}

class _ReassignBottomSheetState extends State<_ReassignBottomSheet> {
  List<dynamic> officers = [];
  bool isLoading = true;
  bool isSubmitting = false;
  String? selectedOfficerId;

  @override
  void initState() {
    super.initState();
    _loadOfficers();
  }

  Future<void> _loadOfficers() async {
    try {
      final data = await JEService.getFieldOfficers();
      // Filter out only completely inactive ones, keep those on leave to show status.
      setState(() {
        officers = data.where((o) => o['is_active'] == true).toList();
        isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading officers: $e')));
        Navigator.pop(context);
      }
    }
  }

  Future<void> _submitReassignment() async {
    if (selectedOfficerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an officer')));
      return;
    }

    setState(() => isSubmitting = true);
    try {
      await JEService.reassignComplaint(widget.complaintId, selectedOfficerId!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Complaint Reassigned successfully!'), backgroundColor: Colors.green));
        widget.onReassigned();
      }
    } catch (e) {
      setState(() => isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Select Officer for Reassignment", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text("Complaint Location: ${widget.area} (Ward ${widget.ward})", style: TextStyle(color: Colors.grey.shade700)),
          const SizedBox(height: 16),
          
          if (isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
          else if (officers.isEmpty)
            const Padding(padding: EdgeInsets.all(20), child: Text("No active field officers available.", style: TextStyle(color: Colors.red)))
          else
            Container(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: officers.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final o = officers[index];
                  final bool isOnLeave = o['is_on_leave'] == true;
                  final String officerName = o['name'] ?? 'Unknown';
                  final String officerWards = "Wards ${o['ward_from']}-${o['ward_to']}";
                  
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    enabled: !isOnLeave,
                    leading: CircleAvatar(
                      backgroundColor: isOnLeave ? Colors.red.shade100 : Colors.green.shade100,
                      child: Icon(Icons.person, color: isOnLeave ? Colors.red : Colors.green),
                    ),
                    title: Text(officerName, style: TextStyle(color: isOnLeave ? Colors.grey : null)),
                    subtitle: Text(officerWards),
                    trailing: isOnLeave 
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(10)),
                          child: const Text("ON LEAVE", style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                        )
                      : Radio<String>(
                          value: o['user_id'],
                          groupValue: selectedOfficerId,
                          onChanged: (val) {
                            setState(() => selectedOfficerId = val);
                          },
                        ),
                    onTap: isOnLeave ? null : () {
                      setState(() => selectedOfficerId = o['user_id']);
                    },
                  );
                },
              ),
            ),
            
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (isSubmitting || selectedOfficerId == null) ? null : _submitReassignment,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
              child: isSubmitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text("Confirm Reassignment", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }
}
