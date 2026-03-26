class OperatorProfile {
  final String userId;
  final String phoneNumber;
  final String name;
  final String role;
  final String shift;
  final bool isActive;
  final int wardFrom;
  final int wardTo;
  final int? stationId;
  final String? stationType;
  final String? stationName;
  final String? wardNumber;
  final int pendingTickets;
  final int logsSubmitted;
  final double compliancePercentage;
  final int totalFaultsReported;
  final double performanceScore;

  OperatorProfile({
    required this.userId,
    required this.phoneNumber,
    required this.name,
    required this.role,
    required this.shift,
    required this.isActive,
    required this.wardFrom,
    required this.wardTo,
    this.stationId,
    this.stationType,
    this.stationName,
    this.wardNumber,
    this.pendingTickets = 0,
    this.logsSubmitted = 0,
    this.compliancePercentage = 0.0,
    this.totalFaultsReported = 0,
    this.performanceScore = 0.0,
  });

  factory OperatorProfile.fromJson(Map<String, dynamic> json) {
    return OperatorProfile(
      userId: json['user_id'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      name: json['name'] ?? '',
      role: json['role'] ?? '',
      shift: json['shift'] ?? '',
      isActive: json['is_active'] ?? true,
      wardFrom: json['ward_from'] ?? 0,
      wardTo: json['ward_to'] ?? 0,
      stationId: json['station_id'],
      stationType: json['station_type'],
      stationName: json['station_name'],
      wardNumber: json['ward_number'],
      pendingTickets: json['pending_tickets'] ?? 0,
      logsSubmitted: json['logs_submitted'] ?? 0,
      compliancePercentage: (json['compliance_percentage'] ?? 0).toDouble(),
      totalFaultsReported: json['total_faults_reported'] ?? 0,
      performanceScore: (json['performance_score'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'phone_number': phoneNumber,
      'name': name,
      'role': role,
      'shift': shift,
      'is_active': isActive,
      'ward_from': wardFrom,
      'ward_to': wardTo,
      'station_id': stationId,
      'station_type': stationType,
      'station_name': stationName,
      'ward_number': wardNumber,
      'pending_tickets': pendingTickets,
      'logs_submitted': logsSubmitted,
      'compliance_percentage': compliancePercentage,
      'total_faults_reported': totalFaultsReported,
      'performance_score': performanceScore,
    };
  }
}
