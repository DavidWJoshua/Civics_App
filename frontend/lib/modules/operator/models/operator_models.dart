class Station {
  final int id;
  final String name;
  final String type;
  final String wardNumber;

  Station({required this.id, required this.name, required this.type, required this.wardNumber});

  factory Station.fromJson(Map<String, dynamic> json) {
    return Station(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      wardNumber: json['ward_number'],
    );
  }
}

class Equipment {
  final int id;
  final int stationId;
  final String name;
  final String type;

  Equipment({required this.id, required this.stationId, required this.name, required this.type});

  factory Equipment.fromJson(Map<String, dynamic> json) {
    return Equipment(
      id: json['id'],
      stationId: json['station_id'],
      name: json['name'],
      type: json['type'],
    );
  }
}

class LiftingDailyLog {
  int? stationId;
  String logDate;
  String shiftType;
  int? equipmentId;
  String pumpStatus;
  double? hoursReading;
  double? voltage;
  double? currentReading;
  bool vibrationIssue;
  bool noiseIssue;
  bool leakageIssue;
  String sumpLevelStatus;
  String panelStatus;
  bool cleaningDone;
  String remark;

  LiftingDailyLog({
    this.stationId,
    required this.logDate,
    required this.shiftType,
    this.equipmentId,
    required this.pumpStatus,
    this.hoursReading,
    this.voltage,
    this.currentReading,
    this.vibrationIssue = false,
    this.noiseIssue = false,
    this.leakageIssue = false,
    required this.sumpLevelStatus,
    required this.panelStatus,
    this.cleaningDone = false,
    this.remark = "",
  });

  Map<String, dynamic> toJson() {
    return {
      if (stationId != null) "station_id": stationId,
      "log_date": logDate,
      "shift_type": shiftType,
      if (equipmentId != null) "equipment_id": equipmentId,
      "pump_status": pumpStatus,
      "hours_reading": hoursReading,
      "voltage": voltage,
      "current_reading": currentReading,
      "vibration_issue": vibrationIssue,
      "noise_issue": noiseIssue,
      "leakage_issue": leakageIssue,
      "sump_level_status": sumpLevelStatus,
      "panel_status": panelStatus,
      "cleaning_done": cleaningDone,
      "remark": remark,
    };
  }
}

// Add Pumping and STP logs similarly...
