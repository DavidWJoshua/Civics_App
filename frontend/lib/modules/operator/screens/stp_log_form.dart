import 'package:flutter/material.dart';
import '../../../core/utils/token_storage.dart';
import '../../citizen/screens/citizen_login_phone.dart';
import '../models/operator_models.dart';
import '../services/operator_service.dart';
import '../../../core/theme/app_colors.dart';

class StpLogForm extends StatefulWidget {
  final Station station;
  final String frequency;

  const StpLogForm({super.key, required this.station, required this.frequency});

  @override
  State<StpLogForm> createState() => _StpLogFormState();
}

class _StpLogFormState extends State<StpLogForm> {
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
      await OperatorService.submitStpLog(_data, widget.frequency);
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
        title: Text("STP ${widget.frequency} Log"),
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
          _section("Inlet (Raw Sewage) Check"),
          _text("Inlet Flow Rate (MLD)", "inlet_flow_rate", isNumber: true),
          _text("Inlet pH", "inlet_ph", isNumber: true),
          _text("Inlet BOD (mg/L)", "inlet_bod", isNumber: true),
          _text("Inlet COD (mg/L)", "inlet_cod", isNumber: true),
          _text("Inlet TSS (mg/L)", "inlet_tss", isNumber: true),
          _text("Inlet Oil/Grease (mg/L)", "inlet_oil_grease", isNumber: true),
          _text("Inlet Temperature (°C)", "inlet_temp", isNumber: true),
          _dropdown("Inlet Color/Odour", "inlet_color_odour", ["Normal", "Abnormal"], required: true),
          _section("Process Control"),
          _text("Dissolved Oxygen (mg/L)", "do_level", isNumber: true),
          _text("MLSS (mg/L)", "mlss", isNumber: true),
          _text("MCRT Sludge Age (Days)", "mcrt", isNumber: true),
          _text("SV30 (mL/L)", "sv30", isNumber: true),
          _text("F/M Ratio", "fm_ratio", isNumber: true),
          _text("Blower Running Hours", "blower_hours", isNumber: true),
          _text("Sludge Blanket Depth (m)", "sludge_depth", isNumber: true),
          _text("RAS Flow Rate (m³/hr)", "ras_flow", isNumber: true),
          _text("WAS Flow Rate (m³/hr)", "was_flow", isNumber: true),
          _switch("Scum Presence?", "scum_present"),
          _section("Output (Treated Effluent)"),
          _text("Outlet Flow Rate (MLD)", "outlet_flow_rate", isNumber: true),
          _text("Outlet pH", "outlet_ph", isNumber: true),
          _text("Outlet BOD (mg/L)", "outlet_bod", isNumber: true),
          _text("Outlet COD (mg/L)", "outlet_cod", isNumber: true),
          _text("Outlet TSS (mg/L)", "outlet_tss", isNumber: true),
          _text("Outlet Oil/Grease (mg/L)", "outlet_oil_grease", isNumber: true),
          _text("Outlet Fecal Coliform (MPN)", "outlet_fecal_coliform", isNumber: true),
          _text("Residual Chlorine (mg/L)", "residual_chlorine", isNumber: true),
          _section("Sludge & Energy"),
          _text("Sludge Generated (m³/day)", "sludge_generated", isNumber: true),
          _text("Sludge Dried (MT)", "sludge_dried", isNumber: true),
          _text("Moisture Content (%)", "moisture_content", isNumber: true),
          _text("Disposal Method", "disposal_method"),
          _dropdown("Drying Bed Condition", "drying_bed_condition", ["OK", "Not OK"], required: true),
          _text("Power Consumption (kWh)", "power_kwh", isNumber: true),
          _text("Energy per MLD (kWh/MLD)", "energy_per_mld", isNumber: true),
          _text("Chlorine Consumption (kg)", "chlorine_usage", isNumber: true),
          _text("Polymer Usage (kg)", "polymer_usage", isNumber: true),
          _dropdown("Chemical Stock Status", "chemical_stock_status", ["Adequate", "Low"], required: true),
        ];
      case 'weekly':
        return [
          _section("Maintenance & Calibration"),
          _switch("Blower Maintenance Done?", "blower_maint_done"),
          _switch("Diffuser Cleaning Done?", "diffuser_cleaning_done"),
          _dropdown("Clarifier Mechanism Check", "clarifier_check", ["OK", "Issue"], required: true),
          _switch("Lab Equipment Calibrated?", "lab_calibrated"),
          _dropdown("Online Analyzer Status", "analyzer_status", ["Working", "Faulty"], required: true),
          _text("Remark", "remark"),
        ];
      case 'monthly':
        return [
          _section("Mechanical & Electrical Assets"),
          _dropdown("Pump Maintenance Status", "pump_maint_status", ["Done", "Pending"], required: true),
          _dropdown("Motor Service Done", "motor_service_done", ["Yes", "No"], required: true),
          _dropdown("Valve Lubrication", "valve_lubrication", ["OK", "Required"], required: true),
          _dropdown("Electrical Panel Inspection", "panel_inspection", ["Pass", "Fail"], required: true),
          _switch("Emergency Power Test Done?", "emergency_power_test"),
          _section("Process Optimization"),
          _dropdown("Sand Filter Backwash", "sand_filter_status", ["OK", "Clogged"], required: true),
          _dropdown("Carbon Filter Status", "carbon_filter_status", ["Effective", "Needs Change"], required: true),
          _section("Document Evidence"),
          _text("Monthly Remark", "remark"),
          _imagePicker("Monthly Report Photo", "photo_url"),
        ];
      case 'yearly':
        return [
          _section("Yearly Audit & Overhaul"),
          _switch("Structural Audit Done?", "structural_audit"),
          _switch("Deep Tank Cleaning Done?", "tank_cleaning"),
          _switch("Sludge Handling Unit Overhaul?", "sludge_unit_overhaul"),
          _switch("Electrical Safety Audit?", "electrical_safety_audit"),
          _dropdown("Instrumentation Calibration", "instrument_calibration", ["Certified", "Pending"], required: true),
          _dropdown("Grit Chamber Service", "grit_chamber_service", ["Done", "Pending"], required: true),
          _section("Yearly Remarks"),
          _text("Yearly Remark", "remark"),
          _imagePicker("Yearly Evidence/Certificate", "photo_url"),
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
          OutlinedButton.icon(
            onPressed: () {},
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
