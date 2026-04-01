import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/utils/token_storage.dart';
import '../../citizen/screens/citizen_login_phone.dart';
import '../models/operator_models.dart';
import '../services/operator_service.dart';
import '../../../core/theme/app_colors.dart';
import 'package:intl/intl.dart';

class PumpingLogForm extends StatefulWidget {
  final Station station;
  final String frequency;

  const PumpingLogForm({super.key, required this.station, required this.frequency});

  @override
  State<PumpingLogForm> createState() => _PumpingLogFormState();
}

class _PumpingLogFormState extends State<PumpingLogForm> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _data = {};
  bool _loading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields"), backgroundColor: Colors.red),
      );
      return;
    }
    _formKey.currentState!.save();
    _data['station_id'] = widget.station.id;
    _data['log_date'] = DateTime.now().toIso8601String().split('T')[0];

    setState(() => _loading = true);
    try {
      await OperatorService.submitPumpingLog(_data, widget.frequency);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Log Submitted Successfully"), backgroundColor: Colors.green));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final freq = widget.frequency.trim().toLowerCase();
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.station.name} - ${widget.frequency} Log"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await TokenStorage.clear();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const CitizenLoginPhone()), (r) => false);
              }
            },
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ..._buildFields(freq),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("SUBMIT LOG", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFields(String freq) {
    switch (freq) {
      case 'daily':
        return [
          _section("Shift Date & Info"),
          _readOnlyText("Log Date", DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now())),
          _dropdown("Shift Type", "shift_type", ["Day", "Night"], required: true),
          _text("Equipment ID (Optional)", "equipment_id", isNumber: true, isInt: true),
          _dropdown("Pump Running Status", "pump_status", ["Running", "Standby", "Stopped"], required: true),
          _text("Number of Pumps Running", "pumps_running_count", isNumber: true, isInt: true),
          _dropdown("Inlet Level Status", "inlet_level_status", ["Low", "Normal", "High"], required: true),
          _text("Outlet Pressure", "outlet_pressure", isNumber: true),
          _text("Flow Rate (m³/hr)", "flow_rate", isNumber: true),
          _text("Voltage (V)", "voltage", isNumber: true),
          _text("Current (A)", "current_reading", isNumber: true),
          _text("Power Factor", "power_factor", isNumber: true),
          _dropdown("Panel Alarm Status", "panel_alarm_status", ["Normal", "Alarm"], required: true),
          _dropdown("Sump Cleanliness", "sump_cleanliness", ["Clean", "Dirty"], required: true),
          _section("Checks & Flags"),
          _switch("Vibration Abnormal?", "vibration_issue"),
          _switch("Noise Abnormal?", "noise_issue"),
          _switch("Leakage Detected?", "leakage_issue"),
          _switch("Screen Bar Cleaned?", "screen_bar_cleaned"),
          _section("Remarks"),
          _text("Daily Remark", "remark"),
          _imagePicker("Photo Evidence", "photo_url"),
        ];
      case 'weekly':
        return [
          _text("Equipment ID", "equipment_id", isNumber: true, isInt: true, required: true),
          _switch("Lubrication Done?", "lubrication_done"),
          _dropdown("Valve Operation", "valve_check", ["Smooth", "Jammed"], required: true),
          _switch("Standby Pump Tested?", "standby_test"),
          _switch("Control Panel Cleaned?", "panel_cleaned"),
          _dropdown("Earthing Status", "earthing_status", ["OK", "Issue"], required: true),
          _dropdown("Cable Condition", "cable_condition", ["Good", "Damaged"], required: true),
          _switch("Minor Fault Observed?", "minor_fault"),
          _section("Remarks"),
          _text("Weekly Remark", "remark"),
          _imagePicker("Photo Evidence", "photo_url"),
        ];
      case 'monthly':
        return [
          _text("Equipment ID", "equipment_id", isNumber: true, isInt: true, required: true),
          _text("Motor Insulation (MΩ)", "insulation_resistance", isNumber: true),
          _dropdown("Bearing Condition", "bearing_condition", ["Good", "Worn"], required: true),
          _dropdown("Alignment Status", "alignment_status", ["OK", "Misaligned"], required: true),
          _dropdown("Foundation Bolt Check", "foundation_bolt_status", ["Tight", "Loose"], required: true),
          _dropdown("Starter Panel Test", "starter_test_status", ["Normal", "Fault"], required: true),
          _switch("Load Test Conducted?", "load_test_done"),
          _text("Energy Consumption (kWh)", "energy_consumption", isNumber: true),
          _text("Preventive Action Taken", "preventive_action"),
          _section("Remarks"),
          _text("Monthly Remark", "remark"),
          _imagePicker("Photo Evidence", "photo_url"),
        ];
      case 'yearly':
        return [
          _text("Equipment ID", "equipment_id", isNumber: true, isInt: true, required: true),
          _switch("Pump Overhaul Done?", "overhaul_done"),
          _switch("Motor Rewinding Done?", "rewinding_done"),
          _dropdown("Impeller Condition", "impeller_condition", ["Good", "Replaced"], required: true),
          _switch("Seal Gasket Replaced?", "seal_replaced"),
          _switch("Electrical Calibration Done?", "calibration_done"),
          _dropdown("Capacity Test Result", "capacity_test_result", ["Pass", "Fail"], required: true),
          _switch("Safety Audit Done?", "safety_audit_done"),
          _switch("Third Party Inspection Done?", "inspection_flag"),
          _section("Remarks"),
          _text("Yearly Remark", "remark"),
          _imagePicker("Yearly Evidence", "photo_url"),
        ];
      default:
        return [
          Center(child: Text("Unknown frequency: ${widget.frequency}", style: const TextStyle(color: Colors.red))),
        ];
    }
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.primary)),
            const Divider(thickness: 1.5, color: AppColors.primary),
          ],
        ),
      );

  Widget _readOnlyText(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        initialValue: value,
        decoration: _inputDec(label).copyWith(fillColor: Colors.grey[100]),
        enabled: false,
        style: const TextStyle(color: Colors.black87),
      ),
    );
  }

  Widget _text(String label, String key, {bool isNumber = false, bool isInt = false, bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        decoration: _inputDec(required ? "$label *" : label),
        keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
        onSaved: (val) {
          if (val == null || val.isEmpty) return;
          if (isNumber) {
            _data[key] = isInt ? (int.tryParse(val) ?? 0) : (double.tryParse(val) ?? 0.0);
          } else {
            _data[key] = val;
          }
        },
        validator: (val) {
          if (required && (val == null || val.trim().isEmpty)) return "$label is required";
          if (isNumber && val != null && val.isNotEmpty) {
            if (isInt && int.tryParse(val) == null) return "Enter valid integer";
            if (!isInt && double.tryParse(val) == null) return "Enter valid number";
          }
          return null;
        },
      ),
    );
  }

  Widget _dropdown(String label, String key, List<String> items, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<String>(
        decoration: _inputDec(label),
        hint: const Text("Select...", style: TextStyle(color: Colors.grey)),
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: (val) => _data[key] = val,
        onSaved: (val) { if (val != null) _data[key] = val; },
        validator: required ? (val) => val == null ? "Please select $label" : null : null,
      ),
    );
  }

  Widget _switch(String label, String key) {
    _data.putIfAbsent(key, () => false);
    return StatefulBuilder(
      builder: (context, setSwitchState) => SwitchListTile(
        title: Text(label),
        value: _data[key] as bool,
        activeColor: AppColors.primary,
        contentPadding: EdgeInsets.zero,
        onChanged: (val) {
          setSwitchState(() => _data[key] = val);
        },
      ),
    );
  }

  Widget _imagePicker(String label, String key) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 8),
          if (_data[key] != null && _data[key].toString().length > 100)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(base64Decode(_data[key]), height: 100, width: 100, fit: BoxFit.cover),
              )
            ),
          OutlinedButton.icon(
            onPressed: () async {
              final picker = ImagePicker();
              final pickedFile = await picker.pickImage(source: ImageSource.camera, imageQuality: 50);
              if (pickedFile != null) {
                final bytes = await pickedFile.readAsBytes();
                setState(() {
                   _data[key] = base64Encode(bytes);
                });
              }
            },
            icon: const Icon(Icons.camera_alt),
            label: Text(_data[key] != null ? "Retake Photo" : "Take Photo"),
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDec(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      );
}
