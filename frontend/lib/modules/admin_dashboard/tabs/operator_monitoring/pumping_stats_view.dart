import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/operator_analytics.dart';
import '../../services/admin_service.dart';

class PumpingStatsView extends StatefulWidget {
  final DateTimeRange? dateRange;
  const PumpingStatsView({super.key, this.dateRange});

  @override
  State<PumpingStatsView> createState() => _PumpingStatsViewState();
}

class _PumpingStatsViewState extends State<PumpingStatsView> {
  final AdminService _adminService = AdminService();
  late Future<PumpingStats> _statsFuture;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  @override
  void didUpdateWidget(PumpingStatsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.dateRange != oldWidget.dateRange) {
      _fetchStats();
    }
  }

  void _fetchStats() {
    setState(() {
      _statsFuture = _adminService.getPumpingStats(
        startDate: widget.dateRange?.start,
        endDate: widget.dateRange?.end,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => _fetchStats(),
      child: FutureBuilder<PumpingStats>(
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
                  title: 'Flow Rate Trend',
                  subtitle: 'Daily average flow rate across all pumping stations',
                  xLabel: 'Date',
                  yLabel: 'MLD',
                  legend: _buildLegendItem(Colors.blue, 'Flow Rate (MLD)'),
                  chart: _buildLineChart(stats.flowRateTrend, Colors.blue),
                ),
                const SizedBox(height: 16),
                _buildChartCard(
                  title: 'Outlet Pressure Trend',
                  subtitle: 'Daily average outlet pressure across all stations',
                  xLabel: 'Date',
                  yLabel: 'Bar',
                  legend: _buildLegendItem(Colors.purple, 'Pressure (Bar)'),
                  chart: _buildLineChart(stats.pressureTrend, Colors.purple),
                ),
                const SizedBox(height: 16),
                if (stats.stationPerformance.isNotEmpty) ...[
                  const Text('Station Avg Flow Rate (MLD)',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
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

  Widget _buildKPIGrid(PumpingStats stats) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.3,
      children: [
        _buildKPI('Total Stations', stats.totalStations.toString(), Icons.water_drop),
        _buildKPI('Avg Flow Rate', '${stats.avgFlowRate.toStringAsFixed(1)} MLD', Icons.waves),
        _buildKPI('Avg Power Factor', stats.avgPowerFactor.toStringAsFixed(2), Icons.electric_bolt,
            color: stats.avgPowerFactor < 0.9 ? Colors.orange : Colors.green),
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

  // ─── Chart Card ──────────────────────────────────────────────────────────

  Widget _buildChartCard({
    required String title,
    required String subtitle,
    required String xLabel,
    required String yLabel,
    required Widget chart,
    Widget? legend,
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
            if (legend != null) ...[const SizedBox(height: 6), legend],
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RotatedBox(
                  quarterTurns: 3,
                  child: Text(yLabel, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    children: [
                      SizedBox(height: 200, child: chart),
                      const SizedBox(height: 4),
                      Text(xLabel, style: const TextStyle(fontSize: 10, color: Colors.grey)),
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

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 14, height: 4, color: color),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  // ─── Line Chart ──────────────────────────────────────────────────────────

  Widget _buildLineChart(List<ChartSeries> points, Color color) {
    if (points.isEmpty) return const Center(child: Text('No Data'));

    final maxY = points.map((p) => p.value).reduce((a, b) => a > b ? a : b);

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
              reservedSize: 42,
              interval: maxY > 0 ? (maxY / 4).ceilToDouble() : 1,
              getTitlesWidget: (value, meta) => Text(
                value.toStringAsFixed(1),
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
                .map((e) => FlSpot(e.key.toDouble(), e.value.value))
                .toList(),
            isCurved: true,
            color: color,
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: true, color: color.withOpacity(0.08)),
          ),
        ],
      ),
    );
  }

  // ─── Station Table ────────────────────────────────────────────────────────

  Widget _buildStationTable(List<StationStat> stations) {
    return Card(
      elevation: 1,
      child: Column(
        children: [
          Container(
            color: const Color(0xFF37474F),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: const Row(
              children: [
                Expanded(flex: 3, child: Text('Station', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(flex: 2, child: Text('Avg Flow (MLD)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.right)),
              ],
            ),
          ),
          ...stations.asMap().entries.map((entry) {
            final i = entry.key;
            final s = entry.value;
            return Container(
              color: i.isEven ? Colors.white : Colors.grey.shade50,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              child: Row(
                children: [
                  Expanded(flex: 3, child: Text(s.stationName, style: const TextStyle(fontSize: 12))),
                  Expanded(
                    flex: 2,
                    child: Text(
                      s.complianceRate.toStringAsFixed(2),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueAccent),
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
