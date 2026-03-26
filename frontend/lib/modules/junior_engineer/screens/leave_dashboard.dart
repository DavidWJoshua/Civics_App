import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../field_officer/services/leave_service.dart';

class LeaveApprovalDashboard extends StatefulWidget {
  const LeaveApprovalDashboard({super.key});

  @override
  State<LeaveApprovalDashboard> createState() => _LeaveApprovalDashboardState();
}

class _LeaveApprovalDashboardState extends State<LeaveApprovalDashboard> {
  List<LeaveRequest> _pendingLeaves = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPendingLeaves();
  }

  Future<void> _loadPendingLeaves() async {
    setState(() => _isLoading = true);
    try {
      final leaves = await LeaveService.getPendingLeaves();
      if (mounted) {
        setState(() {
          _pendingLeaves = leaves;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleApproval(int leaveId, String status) async {
    try {
      await LeaveService.approveRejectLeave(leaveId, status);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Leave $status successfully')));
        _loadPendingLeaves();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave Approvals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPendingLeaves,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pendingLeaves.isEmpty
              ? const Center(child: Text('No pending leave requests'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _pendingLeaves.length,
                  itemBuilder: (context, index) {
                    final leave = _pendingLeaves[index];
                    return _buildLeaveCard(leave);
                  },
                ),
    );
  }

  Widget _buildLeaveCard(LeaveRequest leave) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    String formattedFrom = 'N/A';
    String formattedTo = 'N/A';
    
    try {
      formattedFrom = dateFormat.format(DateTime.parse(leave.fromDate));
      formattedTo = dateFormat.format(DateTime.parse(leave.toDate));
    } catch (_) {}

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Officer ID: \${leave.officerId ?? "Unknown"}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    leave.status,
                    style: TextStyle(color: Colors.orange.shade900, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text('$formattedFrom - $formattedTo', style: const TextStyle(color: Colors.black87)),
              ],
            ),
            const SizedBox(height: 8),
            const Text('Reason:', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(leave.reason),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => _handleApproval(leave.id!, 'REJECTED'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Reject'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () => _handleApproval(leave.id!, 'APPROVED'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  child: const Text('Approve'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
