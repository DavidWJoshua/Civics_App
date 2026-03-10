import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../../services/admin_service.dart';
import '../../models/operator_analytics.dart';

class OperatorMatrixView extends StatefulWidget {
  final DateTimeRange? dateRange;

  const OperatorMatrixView({super.key, this.dateRange});

  @override
  State<OperatorMatrixView> createState() => _OperatorMatrixViewState();
}

class _OperatorMatrixViewState extends State<OperatorMatrixView> {
  final AdminService _adminService = AdminService();
  bool _isDownloading = false;
  late Future<OperatorTaskMatrix> _future;

  @override
  void initState() {
    super.initState();
    _future = _buildFuture();
  }

  @override
  void didUpdateWidget(OperatorMatrixView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dateRange != widget.dateRange) {
      setState(() {
        _future = _buildFuture();
      });
    }
  }

  Future<OperatorTaskMatrix> _buildFuture() {
    final refDate = widget.dateRange?.end ?? DateTime.now();
    final dateStr = DateFormat('yyyy-MM-dd').format(refDate);
    return _adminService.getOperatorTaskMatrix(date: dateStr);
  }

  Future<void> _handleExport() async {
    setState(() => _isDownloading = true);
    try {
      final bytes = await _adminService.downloadReportBytes(
        'operator',
        'excel',
        startDate: widget.dateRange?.start,
        endDate: widget.dateRange?.end,
      );

      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File('${dir.path}/operator_matrix_$timestamp.csv');

      await file.writeAsBytes(bytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Export downloaded. Opening file...')),
        );
        await OpenFilex.open(file.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final refDate = widget.dateRange?.end ?? DateTime.now();
    final dateLabel = DateFormat('yyyy-MM-dd').format(refDate);

    return Column(
      children: [
        /// HEADER
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Task Compliance Matrix',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Ref Date: $dateLabel',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _isDownloading ? null : _handleExport,
                icon: _isDownloading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.download, size: 16),
                label: const Text('Export'),
              ),
            ],
          ),
        ),

        /// LIST OF CARDS
        Expanded(
          child: FutureBuilder<OperatorTaskMatrix>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(
                  child: Text('Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red)),
                );
              } else if (!snapshot.hasData || snapshot.data!.tasks.isEmpty) {
                return const Center(
                    child: Text('No operator compliance data found.'));
              }

              final tasks = snapshot.data!.tasks;

              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 24, left: 12, right: 12),
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  final role = task.stationType.replaceAll('_OPERATOR', '');

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /// OPERATOR INFO
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.blue.shade100,
                                child: Text(
                                  task.operatorName.isNotEmpty
                                      ? task.operatorName[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                      color: Colors.blue.shade900,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      task.operatorName,
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      '${task.stationName} ($role)',
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade700),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),

                          /// STATUS MATRIX
                          Row(
                            children: [
                              Expanded(
                                  child: _buildStatusColumn(
                                      'Daily',
                                      task.daily.isNotEmpty
                                          ? task.daily.values.first
                                          : 'Pending')),
                              Expanded(
                                  child: _buildStatusColumn(
                                      'Weekly',
                                      task.weekly.isNotEmpty
                                          ? task.weekly.values.first
                                          : 'Pending')),
                              Expanded(
                                  child: _buildStatusColumn(
                                      'Monthly',
                                      task.monthly.isNotEmpty
                                          ? task.monthly.values.first
                                          : 'Pending')),
                              Expanded(
                                  child: _buildStatusColumn(
                                      'Yearly',
                                      task.yearly.isEmpty
                                          ? 'Pending'
                                          : task.yearly)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatusColumn(String title, String statusText) {
    final String normalized = statusText.toLowerCase().trim();
    Color color = Colors.orange;
    String label = 'Pending';
    String? datePart;

    if (normalized.startsWith('completed') ||
        normalized.startsWith('done') ||
        normalized.startsWith('submitted')) {
      color = Colors.green;
      label = 'Done';
    } else if (normalized.startsWith('missed') ||
        normalized.startsWith('overdue') ||
        normalized.startsWith('failed')) {
      color = Colors.red;
      label = 'Missed';
    }

    final match = RegExp(r'\(([^)]+)\)').firstMatch(statusText);
    if (match != null) {
      datePart = match.group(1);
    }

    return Column(
      children: [
        Text(title,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color, width: 1),
          ),
          child: Text(
            label,
            style: TextStyle(
                color: color, fontSize: 10, fontWeight: FontWeight.w800),
          ),
        ),
        if (datePart != null && datePart.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              datePart,
              style: const TextStyle(fontSize: 9, color: Colors.grey),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }
}