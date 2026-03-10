
import 'package:flutter/material.dart';

class DateRangeSelector extends StatelessWidget {
  final DateTimeRange? selectedRange;
  final Function(DateTimeRange?) onRangeChanged;

  const DateRangeSelector({
    Key? key,
    required this.selectedRange,
    required this.onRangeChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String label = "Select Date Range";
    if (selectedRange != null) {
      label = "${selectedRange!.start.toString().split(' ')[0]} - ${selectedRange!.end.toString().split(' ')[0]}";
    }

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.blue),
                const SizedBox(width: 8),
                Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.filter_list),
              onSelected: (value) => _handlePresetSelection(context, value),
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'today', child: Text("Today")),
                const PopupMenuItem(value: 'yesterday', child: Text("Yesterday")),
                const PopupMenuItem(value: 'last7', child: Text("Last 7 Days")),
                const PopupMenuItem(value: 'last30', child: Text("Last 30 Days")),
                const PopupMenuItem(value: 'custom', child: Text("Custom Range...")),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handlePresetSelection(BuildContext context, String value) async {
    final now = DateTime.now();
    DateTimeRange? range;

    switch (value) {
      case 'today':
        range = DateTimeRange(start: now, end: now);
        break;
      case 'yesterday':
        final yesterday = now.subtract(const Duration(days: 1));
        range = DateTimeRange(start: yesterday, end: yesterday);
        break;
      case 'last7':
        range = DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now);
        break;
      case 'last30':
        range = DateTimeRange(start: now.subtract(const Duration(days: 30)), end: now);
        break;
      case 'custom':
        range = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2023),
          lastDate: now,
          initialDateRange: selectedRange,
        );
        break;
    }

    if (range != null) {
      onRangeChanged(range);
    }
  }
}
