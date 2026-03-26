import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'lifting_stats_view.dart';
import 'pumping_stats_view.dart';
import 'stp_stats_view.dart';
import 'operator_matrix_view.dart';

import '../../widgets/date_range_selector.dart';

class OperatorMonitoringTab extends StatefulWidget {
  const OperatorMonitoringTab({super.key});

  @override
  State<OperatorMonitoringTab> createState() => _OperatorMonitoringTabState();
}

class _OperatorMonitoringTabState extends State<OperatorMonitoringTab> with SingleTickerProviderStateMixin {
  DateTimeRange? _selectedDateRange;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDateRange = DateTimeRange(
      start: now.subtract(const Duration(days: 30)),
      end: now,
    );
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Rebuild on tab change
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Shared date range selector for all tabs
        DateRangeSelector(
          selectedRange: _selectedDateRange,
          onRangeChanged: (range) {
            setState(() {
              _selectedDateRange = range;
            });
          },
        ),

        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.primary,
            isScrollable: true,
            tabs: const [
              Tab(text: "Lifting Stations"),
              Tab(text: "Pumping Stations"),
              Tab(text: "STP Plants"),
              Tab(text: "Task Matrix"),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              LiftingStatsView(dateRange: _selectedDateRange),
              PumpingStatsView(dateRange: _selectedDateRange),
              STPStatsView(dateRange: _selectedDateRange),
              OperatorMatrixView(dateRange: _selectedDateRange),
            ],
          ),
        ),
      ],
    );
  }
}
