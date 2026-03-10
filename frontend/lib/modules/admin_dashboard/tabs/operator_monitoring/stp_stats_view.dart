import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/operator_analytics.dart';
import '../../services/admin_service.dart';

class STPStatsView extends StatefulWidget {
  final DateTimeRange? dateRange;
  const STPStatsView({super.key, this.dateRange});

  @override
  State<STPStatsView> createState() => _STPStatsViewState();
}

class _STPStatsViewState extends State<STPStatsView> {
  final AdminService _adminService = AdminService();
  late Future<STPStats> _statsFuture;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  @override
  void didUpdateWidget(STPStatsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.dateRange != oldWidget.dateRange) {
      _fetchStats();
    }
  }

  void _fetchStats() {
    setState(() {
      _statsFuture = _adminService.getSTPStats(
        startDate: widget.dateRange?.start,
        endDate: widget.dateRange?.end,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => _fetchStats(),
      child: FutureBuilder<STPStats>(
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

                // ── Parameter Compliance Overview ──────────────────────────
                if (stats.parameterCompliance.isNotEmpty) ...[
                  _buildComplianceCard(stats.parameterCompliance),
                  const SizedBox(height: 16),
                ],

                // ── BOD Trend Chart ────────────────────────────────────────
                _buildChartCard(
                  title: 'BOD Trend — Inlet vs Outlet',
                  subtitle: 'Daily average BOD (mg/L). Outlet limit: 30 mg/L',
                  xLabel: 'Date',
                  yLabel: 'BOD (mg/L)',
                  legend: Row(
                    children: [
                      _legendItem(Colors.blue, 'Inlet BOD'),
                      const SizedBox(width: 16),
                      _legendItem(Colors.green, 'Outlet BOD'),
                      const SizedBox(width: 16),
                      _legendItem(Colors.red.shade300, 'Limit 30 mg/L',
                          dashed: true),
                    ],
                  ),
                  chart: _buildDualLineChart(stats.bodTrend),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─── KPI Cards ───────────────────────────────────────────────────────────

  Widget _buildKPIGrid(STPStats stats) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.3,
      children: [
        _buildKPI('Total Plants', stats.totalSTPs.toString(), Icons.factory),
        _buildKPI(
          'Avg Outlet BOD',
          '${stats.avgBOD.toStringAsFixed(1)} mg/L',
          Icons.science,
          color: stats.avgBOD > 30 ? Colors.red : Colors.green,
          subtitle: stats.avgBOD > 30 ? '⚠ Exceeds 30 mg/L' : '✓ Within limit',
        ),
        _buildKPI(
          'Avg Outlet COD',
          '${stats.avgCOD.toStringAsFixed(1)} mg/L',
          Icons.science,
          color: stats.avgCOD > 250 ? Colors.red : AppColors.primary,
          subtitle:
              stats.avgCOD > 250 ? '⚠ Exceeds 250 mg/L' : '✓ Within limit',
        ),
        _buildKPI(
          'Avg Outlet TSS',
          '${stats.avgTSS.toStringAsFixed(1)} mg/L',
          Icons.water,
          color: stats.avgTSS > 100 ? Colors.orange : AppColors.primary,
          subtitle:
              stats.avgTSS > 100 ? '⚠ Exceeds 100 mg/L' : '✓ Within limit',
        ),
      ],
    );
  }

  Widget _buildKPI(String label, String value, IconData icon,
      {Color? color, String? subtitle}) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 6.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color ?? AppColors.primary, size: 22),
            const SizedBox(height: 2),
            Text(value,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(label,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            if (subtitle != null)
              Text(subtitle,
                  style: TextStyle(fontSize: 9, color: color ?? Colors.grey),
                  textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  // ─── Parameter Compliance Card ────────────────────────────────────────────

  Widget _buildComplianceCard(List<ParameterCompliance> items) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Parameter Compliance Overview',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const Text(
              'Days within standard discharge limits vs days exceeding limits',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            // legend
            Row(
              children: [
                _legendItem(Colors.green.shade600, 'Compliant days'),
                const SizedBox(width: 16),
                _legendItem(Colors.red.shade400, 'Non-compliant days'),
              ],
            ),
            const SizedBox(height: 14),
            ...items.map((p) => _buildComplianceRow(p)),
          ],
        ),
      ),
    );
  }

  Widget _buildComplianceRow(ParameterCompliance p) {
    final total = p.totalDays;
    final pct = p.compliancePct.clamp(0.0, 100.0);
    final isFullyCompliant = p.daysFail == 0 && total > 0;
    final statusColor = pct >= 80
        ? Colors.green.shade700
        : pct >= 50
            ? Colors.orange.shade700
            : Colors.red.shade700;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              // Parameter + limit badge
              Expanded(
                child: Row(
                  children: [
                    Text(
                      p.paramName,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        p.limit,
                        style: const TextStyle(
                            fontSize: 9, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
              // Percentage badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  total == 0
                      ? 'No data'
                      : '${pct.toStringAsFixed(1)}% compliant',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Segmented progress bar
          if (total == 0)
            Container(
              height: 14,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(7),
              ),
              child: const Center(
                child: Text('No logs in selected range',
                    style: TextStyle(fontSize: 9, color: Colors.grey)),
              ),
            )
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: Row(
                children: [
                  if (p.daysOk > 0)
                    Flexible(
                      flex: p.daysOk,
                      child: Container(
                        height: 14,
                        color: Colors.green.shade500,
                      ),
                    ),
                  if (p.daysFail > 0)
                    Flexible(
                      flex: p.daysFail,
                      child: Container(
                        height: 14,
                        color: Colors.red.shade400,
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 4),

          // Day counts
          if (total > 0)
            Row(
              children: [
                _dayBadge('${p.daysOk} day${p.daysOk != 1 ? 's' : ''} ✓',
                    Colors.green.shade600),
                const SizedBox(width: 8),
                _dayBadge('${p.daysFail} day${p.daysFail != 1 ? 's' : ''} ✗',
                    Colors.red.shade400),
                const Spacer(),
                Text('of $total total days',
                    style:
                        const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          if (isFullyCompliant)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                '🎉 100% compliant in this period!',
                style: TextStyle(
                    fontSize: 10,
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }

  Widget _dayBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 10, color: color, fontWeight: FontWeight.w600)),
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
            Text(title,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700)),
            Text(subtitle,
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
            if (legend != null) ...[const SizedBox(height: 6), legend],
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RotatedBox(
                  quarterTurns: 3,
                  child: Text(yLabel,
                      style:
                          const TextStyle(fontSize: 10, color: Colors.grey)),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    children: [
                      SizedBox(height: 220, child: chart),
                      const SizedBox(height: 4),
                      Text(xLabel,
                          style: const TextStyle(
                              fontSize: 10, color: Colors.grey)),
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

  Widget _legendItem(Color color, String label, {bool dashed = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 3,
          decoration: BoxDecoration(
            color: dashed ? Colors.transparent : color,
            border: dashed
                ? Border(bottom: BorderSide(color: color, width: 2))
                : null,
          ),
        ),
        const SizedBox(width: 5),
        Text(label,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade700)),
      ],
    );
  }

  // ─── Dual Line Chart (Inlet vs Outlet BOD) ────────────────────────────────

  Widget _buildDualLineChart(List<MultiLineSeries> points) {
    if (points.isEmpty) return const Center(child: Text('No Data'));

    double maxY = 30;
    for (final p in points) {
      if (p.value1 > maxY) maxY = p.value1;
      if (p.value2 > maxY) maxY = p.value2;
    }
    maxY = maxY * 1.15;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (v) =>
              FlLine(color: Colors.grey.shade200, strokeWidth: 1),
        ),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: 30,
              color: Colors.red.shade300,
              strokeWidth: 1.5,
              dashArray: [6, 4],
              label: HorizontalLineLabel(
                show: true,
                labelResolver: (_) => 'Limit 30',
                style: TextStyle(fontSize: 9, color: Colors.red.shade300),
              ),
            ),
          ],
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              interval: (maxY / 5).ceilToDouble(),
              getTitlesWidget: (value, meta) => Text(
                value.toStringAsFixed(0),
                style:
                    const TextStyle(fontSize: 9, color: Colors.grey),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval:
                  points.length > 7 ? (points.length / 6).ceilToDouble() : 1,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= points.length) return const SizedBox();
                final label = points[idx].label.length >= 10
                    ? points[idx].label.substring(5)
                    : points[idx].label;
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(label,
                      style:
                          const TextStyle(fontSize: 8, color: Colors.grey)),
                );
              },
            ),
          ),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade400),
            left: BorderSide(color: Colors.grey.shade400),
          ),
        ),
        minX: 0,
        maxX: (points.length - 1).toDouble(),
        minY: 0,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: points
                .asMap()
                .entries
                .map((e) => FlSpot(e.key.toDouble(), e.value.value1))
                .toList(),
            isCurved: true,
            color: Colors.blue,
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
            belowBarData:
                BarAreaData(show: true, color: Colors.blue.withOpacity(0.06)),
          ),
          LineChartBarData(
            spots: points
                .asMap()
                .entries
                .map((e) => FlSpot(e.key.toDouble(), e.value.value2))
                .toList(),
            isCurved: true,
            color: Colors.green,
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
                show: true, color: Colors.green.withOpacity(0.06)),
          ),
        ],
      ),
    );
  }
}
