import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/operator_analytics.dart';
import '../../services/admin_service.dart';

class LiftingStatsView extends StatefulWidget {
  final DateTimeRange? dateRange;
  const LiftingStatsView({super.key, this.dateRange});

  @override
  State<LiftingStatsView> createState() => _LiftingStatsViewState();
}

class _LiftingStatsViewState extends State<LiftingStatsView> {
  final AdminService _adminService = AdminService();
  late Future<LiftingStats> _statsFuture;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  @override
  void didUpdateWidget(LiftingStatsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.dateRange != oldWidget.dateRange) {
      _fetchStats();
    }
  }

  void _fetchStats() {
    setState(() {
      _statsFuture = _adminService.getLiftingStats(
        startDate: widget.dateRange?.start,
        endDate: widget.dateRange?.end,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => _fetchStats(),
      child: FutureBuilder<LiftingStats>(
        future: _statsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData) {
            return const Center(child: Text("No Data"));
          }

          final stats = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildKPIGrid(stats),
                const SizedBox(height: 24),
                _buildChartCard(
                  title: 'Daily Log Submissions',
                  subtitle: 'Number of logs submitted per day',
                  xLabel: 'Date',
                  yLabel: 'Submissions',
                  chart: _buildSubmissionLineChart(stats.submissionTrend),
                ),
                const SizedBox(height: 16),
                _buildChartCard(
                  title: 'Avg Pump Running Hours per Day',
                  subtitle: 'Average hours_reading across all stations',
                  xLabel: 'Date',
                  yLabel: 'Hours',
                  chart: _buildBarChart(stats.pumpRunningHours),
                ),
                const SizedBox(height: 16),
                _buildSectionTitle('Abnormal Conditions'),
                const SizedBox(height: 8),
                _buildAbnormalGrid(stats.abnormalConditions),
                const SizedBox(height: 16),
                if (stats.stationPerformance.isNotEmpty) ...[
                  _buildSectionTitle('Station Compliance (%)'),
                  const SizedBox(height: 8),
                  _buildStationTable(stats.stationPerformance),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  // ─── KPI Cards ───────────────────────────────────────────────────────────

  Widget _buildKPIGrid(LiftingStats stats) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.3,
      children: [
        _buildKPI('Total Stations', stats.totalStations.toString(), Icons.location_on),
        _buildKPI('Active Operators', stats.activeOperators.toString(), Icons.people),
        _buildKPI(
          'Submission Rate',
          '${stats.logSubmissionRate.toStringAsFixed(1)}%',
          Icons.assignment_turned_in,
          color: stats.logSubmissionRate > 80 ? Colors.green : Colors.orange,
        ),
        _buildKPI('Faults Reported', stats.faultCount.toString(), Icons.warning, color: Colors.red),
      ],
    );
  }

  Widget _buildKPI(String label, String value, IconData icon, {Color? color}) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color ?? AppColors.primary, size: 24),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(label,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  // ─── Chart Card wrapper ────────────────────────────────────────────────

  Widget _buildChartCard({
    required String title,
    required String subtitle,
    required String xLabel,
    required String yLabel,
    required Widget chart,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 16),
            // Y-axis label + chart
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RotatedBox(
                  quarterTurns: 3,
                  child: Text(yLabel,
                      style: const TextStyle(fontSize: 10, color: Colors.grey)),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    children: [
                      SizedBox(height: 200, child: chart),
                      const SizedBox(height: 4),
                      Text(xLabel,
                          style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700));
  }

  // ─── Line Chart (Submission Trend) ───────────────────────────────────────

  Widget _buildSubmissionLineChart(List<TimePoint> points) {
    if (points.isEmpty) return const Center(child: Text('No Data'));

    final maxY = points.map((p) => p.count.toDouble()).reduce((a, b) => a > b ? a : b);

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (v) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              interval: maxY > 0 ? (maxY / 4).ceilToDouble() : 1,
              getTitlesWidget: (value, meta) => Text(
                value.toInt().toString(),
                style: const TextStyle(fontSize: 9, color: Colors.grey),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: points.length > 7 ? (points.length / 6).ceilToDouble() : 1,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= points.length) return const SizedBox();
                // Show day/month part only: "MM-DD"
                final label = points[idx].date.length >= 10
                    ? points[idx].date.substring(5) // "MM-DD"
                    : points[idx].date;
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(label, style: const TextStyle(fontSize: 8, color: Colors.grey)),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
            show: true,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade400),
              left: BorderSide(color: Colors.grey.shade400),
            )),
        minX: 0,
        maxX: (points.length - 1).toDouble(),
        minY: 0,
        lineBarsData: [
          LineChartBarData(
            spots: points
                .asMap()
                .entries
                .map((e) => FlSpot(e.key.toDouble(), e.value.count.toDouble()))
                .toList(),
            isCurved: true,
            color: AppColors.primary,
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: true, color: AppColors.primary.withOpacity(0.08)),
          ),
        ],
      ),
    );
  }

  // ─── Bar Chart (Pump Running Hours) ──────────────────────────────────────

  Widget _buildBarChart(List<ChartSeries> points) {
    if (points.isEmpty) return const Center(child: Text('No Data'));

    final maxY = points.map((p) => p.value).reduce((a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY * 1.2,
        barGroups: points.asMap().entries.map((e) {
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: e.value.value,
                color: Colors.blueAccent,
                width: points.length > 10 ? 6 : 12,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              )
            ],
          );
        }).toList(),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              interval: maxY > 0 ? (maxY / 4).ceilToDouble() : 1,
              getTitlesWidget: (value, meta) => Text(
                value.toStringAsFixed(0),
                style: const TextStyle(fontSize: 9, color: Colors.grey),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: points.length > 7 ? (points.length / 6).ceilToDouble() : 1,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= points.length) return const SizedBox();
                final label = points[idx].label.length >= 10
                    ? points[idx].label.substring(5)
                    : points[idx].label;
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(label, style: const TextStyle(fontSize: 8, color: Colors.grey)),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (v) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
        ),
        borderData: FlBorderData(
            show: true,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade400),
              left: BorderSide(color: Colors.grey.shade400),
            )),
      ),
    );
  }

  // ─── Abnormal Conditions Grid ─────────────────────────────────────────────

  Widget _buildAbnormalGrid(Map<String, int> conditions) {
    if (conditions.isEmpty) return const Text('No abnormal conditions data.', style: TextStyle(color: Colors.grey));
    return GridView.count(
      crossAxisCount: 3,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.1,
      children: conditions.entries.map((e) {
        return Card(
          color: e.value > 0 ? Colors.red.shade50 : Colors.white,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(e.value.toString(),
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold, color: e.value > 0 ? Colors.red : Colors.black)),
              const SizedBox(height: 4),
              Text(e.key, style: const TextStyle(fontSize: 11), textAlign: TextAlign.center),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ─── Station Performance Table ────────────────────────────────────────────

  Widget _buildStationTable(List<StationStat> stations) {
    return Card(
      elevation: 1,
      child: Column(
        children: [
          // Header
          Container(
            color: const Color(0xFF37474F),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: const Row(
              children: [
                Expanded(flex: 3, child: Text('Station', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(flex: 2, child: Text('Compliance %', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.right)),
              ],
            ),
          ),
          ...stations.asMap().entries.map((entry) {
            final i = entry.key;
            final s = entry.value;
            final rate = s.complianceRate;
            final rateColor = rate >= 80 ? Colors.green : (rate >= 50 ? Colors.orange : Colors.red);
            return Container(
              color: i.isEven ? Colors.white : Colors.grey.shade50,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              child: Row(
                children: [
                  Expanded(flex: 3, child: Text(s.stationName, style: const TextStyle(fontSize: 12))),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${rate.toStringAsFixed(1)}%',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: rateColor),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
