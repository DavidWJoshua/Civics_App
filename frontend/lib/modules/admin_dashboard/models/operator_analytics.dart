class TimePoint {
  final String date;
  final int count;

  TimePoint({required this.date, required this.count});

  factory TimePoint.fromJson(Map<String, dynamic> json) {
    return TimePoint(
      date: json['date'] ?? '',
      count: json['count'] ?? 0,
    );
  }
}

class ChartSeries {
  final String label;
  final double value;

  ChartSeries({required this.label, required this.value});

  factory ChartSeries.fromJson(Map<String, dynamic> json) {
    return ChartSeries(
      label: json['label'] ?? '',
      value: (json['value'] ?? 0).toDouble(),
    );
  }
}

class MultiLineSeries {
  final String label;
  final double value1;
  final double value2;

  MultiLineSeries({required this.label, required this.value1, required this.value2});

  factory MultiLineSeries.fromJson(Map<String, dynamic> json) {
    return MultiLineSeries(
      label: json['label'] ?? '',
      value1: (json['value1'] ?? 0).toDouble(),
      value2: (json['value2'] ?? 0).toDouble(),
    );
  }
}

class StationStat {
  final String stationName;
  final String type;
  final double complianceRate;
  final int faultCount;

  StationStat({
    required this.stationName,
    required this.type,
    required this.complianceRate,
    required this.faultCount,
  });

  factory StationStat.fromJson(Map<String, dynamic> json) {
    return StationStat(
      stationName: json['station_name'] ?? '',
      type: json['type'] ?? '',
      complianceRate: (json['compliance_rate'] ?? 0).toDouble(),
      faultCount: (json['fault_count'] ?? 0) is int
          ? json['fault_count'] ?? 0
          : (json['fault_count'] ?? 0).toInt(),
    );
  }
}

class LiftingStats {
  final int totalStations;
  final int activeOperators;
  final double logSubmissionRate;
  final int faultCount;
  final List<TimePoint> submissionTrend;
  final List<ChartSeries> pumpRunningHours;
  final Map<String, int> abnormalConditions;
  final Map<String, int> sumpLevelStatus;
  final Map<String, int> panelStatus;
  final List<StationStat> stationPerformance;

  LiftingStats({
    required this.totalStations,
    required this.activeOperators,
    required this.logSubmissionRate,
    required this.faultCount,
    required this.submissionTrend,
    required this.pumpRunningHours,
    required this.abnormalConditions,
    required this.sumpLevelStatus,
    required this.panelStatus,
    this.stationPerformance = const [],
  });

  factory LiftingStats.fromJson(Map<String, dynamic> json) {
    Map<String, int> safeIntMap(dynamic raw) {
      if (raw == null || raw is! Map) return {};
      return raw.map<String, int>((k, v) => MapEntry(k.toString(), (v ?? 0) is int ? v : (v ?? 0).toInt()));
    }

    return LiftingStats(
      totalStations: (json['total_stations'] ?? 0) is int ? json['total_stations'] ?? 0 : (json['total_stations'] ?? 0).toInt(),
      activeOperators: (json['active_operators'] ?? 0) is int ? json['active_operators'] ?? 0 : (json['active_operators'] ?? 0).toInt(),
      logSubmissionRate: (json['log_submission_rate'] ?? 0).toDouble(),
      faultCount: (json['fault_count'] ?? 0) is int ? json['fault_count'] ?? 0 : (json['fault_count'] ?? 0).toInt(),
      submissionTrend: (json['submission_trend'] as List?)
              ?.map((e) => TimePoint.fromJson(e))
              .toList() ??
          [],
      pumpRunningHours: (json['pump_running_hours'] as List?)
              ?.map((e) => ChartSeries.fromJson(e))
              .toList() ??
          [],
      abnormalConditions: safeIntMap(json['abnormal_conditions']),
      sumpLevelStatus: safeIntMap(json['sump_level_status']),
      panelStatus: safeIntMap(json['panel_status']),
      stationPerformance: (json['station_performance'] as List?)
              ?.map((e) => StationStat.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class PumpingStats {
  final int totalStations;
  final double avgFlowRate;
  final double avgPowerFactor;
  final int faultCount;
  final List<ChartSeries> flowRateTrend;
  final List<ChartSeries> pressureTrend;
  final List<StationStat> stationPerformance;

  PumpingStats({
    required this.totalStations,
    required this.avgFlowRate,
    required this.avgPowerFactor,
    required this.faultCount,
    required this.flowRateTrend,
    required this.pressureTrend,
    this.stationPerformance = const [],
  });

  factory PumpingStats.fromJson(Map<String, dynamic> json) {
    return PumpingStats(
      totalStations: (json['total_stations'] ?? 0) is int ? json['total_stations'] ?? 0 : (json['total_stations'] ?? 0).toInt(),
      avgFlowRate: (json['avg_flow_rate'] ?? 0).toDouble(),
      avgPowerFactor: (json['avg_power_factor'] ?? 0).toDouble(),
      faultCount: (json['fault_count'] ?? 0) is int ? json['fault_count'] ?? 0 : (json['fault_count'] ?? 0).toInt(),
      flowRateTrend: (json['flow_rate_trend'] as List?)
              ?.map((e) => ChartSeries.fromJson(e))
              .toList() ??
          [],
      pressureTrend: (json['pressure_trend'] as List?)
              ?.map((e) => ChartSeries.fromJson(e))
              .toList() ??
          [],
      stationPerformance: (json['station_performance'] as List?)
              ?.map((e) => StationStat.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class ParameterCompliance {
  final String paramName;
  final int daysOk;
  final int daysFail;
  final int totalDays;
  final double compliancePct;
  final String limit;

  ParameterCompliance({
    required this.paramName,
    required this.daysOk,
    required this.daysFail,
    required this.totalDays,
    required this.compliancePct,
    required this.limit,
  });

  factory ParameterCompliance.fromJson(Map<String, dynamic> json) {
    int safeInt(dynamic v) => v == null ? 0 : (v is int ? v : (v as num).toInt());
    return ParameterCompliance(
      paramName: json['param_name'] ?? '',
      daysOk: safeInt(json['days_ok']),
      daysFail: safeInt(json['days_fail']),
      totalDays: safeInt(json['total_days']),
      compliancePct: (json['compliance_pct'] ?? 0).toDouble(),
      limit: json['limit'] ?? '',
    );
  }
}

class STPStats {
  final int totalSTPs;
  final double avgBOD;
  final double avgCOD;
  final double avgTSS;
  final List<MultiLineSeries> bodTrend;
  final List<ParameterCompliance> parameterCompliance;

  STPStats({
    required this.totalSTPs,
    required this.avgBOD,
    required this.avgCOD,
    required this.avgTSS,
    required this.bodTrend,
    this.parameterCompliance = const [],
  });

  factory STPStats.fromJson(Map<String, dynamic> json) {
    return STPStats(
      totalSTPs: (json['total_stps'] ?? 0) is int ? json['total_stps'] ?? 0 : (json['total_stps'] ?? 0).toInt(),
      avgBOD: (json['avg_bod'] ?? 0).toDouble(),
      avgCOD: (json['avg_cod'] ?? 0).toDouble(),
      avgTSS: (json['avg_tss'] ?? 0).toDouble(),
      bodTrend: (json['bod_trend'] as List?)
              ?.map((e) => MultiLineSeries.fromJson(e))
              .toList() ??
          [],
      parameterCompliance: (json['parameter_compliance'] as List?)
              ?.map((e) => ParameterCompliance.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class OperatorTaskMatrix {
  final int totalOperators;
  final List<OperatorTaskStatus> tasks;

  OperatorTaskMatrix({required this.totalOperators, required this.tasks});

  factory OperatorTaskMatrix.fromJson(Map<String, dynamic> json) {
    return OperatorTaskMatrix(
      totalOperators: json['total_operators'] ?? 0,
      tasks: (json['tasks'] as List?)
              ?.map((e) => OperatorTaskStatus.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class OperatorTaskStatus {
  final String operatorName;
  final String stationName;
  final String stationType;
  final Map<String, String> daily;
  final Map<String, String> weekly;
  final Map<String, String> monthly;
  final String yearly;

  OperatorTaskStatus({
    required this.operatorName,
    required this.stationName,
    required this.stationType,
    required this.daily,
    required this.weekly,
    required this.monthly,
    required this.yearly,
  });

  factory OperatorTaskStatus.fromJson(Map<String, dynamic> json) {
    Map<String, String> safeCastMap(dynamic mapObj) {
      if (mapObj == null || mapObj is! Map) return {};
      return mapObj.map<String, String>((key, value) => MapEntry(key.toString(), value.toString()));
    }

    return OperatorTaskStatus(
      operatorName: json['operator_name'] ?? '',
      stationName: json['station_name'] ?? '',
      stationType: json['station_type'] ?? '',
      daily: safeCastMap(json['daily']),
      weekly: safeCastMap(json['weekly']),
      monthly: safeCastMap(json['monthly']),
      // yearly string safe cast
      yearly: json['yearly']?.toString() ?? '',
    );
  }
}
