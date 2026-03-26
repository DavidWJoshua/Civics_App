import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../../../core/theme/app_colors.dart';

class ComplaintAnalyticsTab extends StatefulWidget {
  const ComplaintAnalyticsTab({Key? key}) : super(key: key);

  @override
  State<ComplaintAnalyticsTab> createState() => _ComplaintAnalyticsTabState();
}

class _ComplaintAnalyticsTabState extends State<ComplaintAnalyticsTab> {
  final AdminService _adminService = AdminService();
  Map<String, dynamic>? _data;
  bool _isLoading = true;
  String? _error;
  int _days = 30;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await _adminService.getComplaintAnalytics(days: _days);
      if (mounted) {
        setState(() {
          _data = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text('Error: $_error'));
    if (_data == null) return const Center(child: Text('No data available'));

    final trendData = _data!['trend_data'] as List<dynamic>? ?? [];
    final severityCounts = _data!['severity_counts'] as Map<String, dynamic>? ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          const Text("Complaint Trends (Last 30 Days)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          SizedBox(
            height: 250, 
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) =>
                      FlLine(color: Colors.grey.shade300, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: trendData.length > 7 ? (trendData.length / 6).ceilToDouble() : 1,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= trendData.length) return const SizedBox();
                        final dateStr = trendData[idx]['date']?.toString() ?? '';
                        final label = dateStr.length >= 10 ? dateStr.substring(5) : dateStr;
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true, 
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade400),
                    left: BorderSide(color: Colors.grey.shade400),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: _generateSpots(trendData),
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: true, color: Colors.blue.withOpacity(0.1)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Text("Severity Distribution", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sections: _generatePieSections(severityCounts),
                      centerSpaceRadius: 40,
                      sectionsSpace: 2,
                    ),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _generatePieLegend(severityCounts),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text("Analytics Overview", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)),
        DropdownButton<int>(
          value: _days,
          items: const [
            DropdownMenuItem(value: 7, child: Text("Last 7 Days")),
            DropdownMenuItem(value: 30, child: Text("Last 30 Days")),
            DropdownMenuItem(value: 90, child: Text("Last 3 Months")),
          ],
          onChanged: (val) {
            if (val != null) {
              setState(() => _days = val);
              _loadData();
            }
          },
        ),
      ],
    );
  }

  List<FlSpot> _generateSpots(List<dynamic> data) {
    // Mapping date strings to index (0, 1, 2...) for X axis
    List<FlSpot> spots = [];
    for (int i = 0; i < data.length; i++) {
      final count = data[i]['count'] as int? ?? 0;
      spots.add(FlSpot(i.toDouble(), count.toDouble()));
    }
    return spots;
  }

  List<PieChartSectionData> _generatePieSections(Map<String, dynamic> counts) {
    if (counts.isEmpty) return [];
    
    final colors = [Colors.green, Colors.orange, Colors.red, Colors.grey];
    int index = 0;
    
    return counts.entries.map((e) {
      final color = colors[index % colors.length];
      index++;
      final value = (e.value as int).toDouble();
      
      return PieChartSectionData(
        color: color,
        value: value,
        title: '${value.toInt()}',
        radius: 60,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();
  }

  List<Widget> _generatePieLegend(Map<String, dynamic> counts) {
    if (counts.isEmpty) return [const Text('No data')];
    final colors = [Colors.green, Colors.orange, Colors.red, Colors.grey];
    int index = 0;
    return counts.entries.map((e) {
      final color = colors[index % colors.length];
      index++;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            Container(width: 12, height: 12, color: color),
            const SizedBox(width: 8),
            Text('${e.key} (${e.value})', style: const TextStyle(fontSize: 12)),
          ],
        ),
      );
    }).toList();
  }
}
