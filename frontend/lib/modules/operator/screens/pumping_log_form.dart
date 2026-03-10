import 'package:flutter/material.dart';
import '../../../core/utils/token_storage.dart';
import '../../citizen/screens/citizen_login_phone.dart';
import '../models/operator_models.dart';
import '../services/operator_service.dart';
import 'form_helpers.dart';
import '../../../core/theme/app_colors.dart';

class PumpingLogForm extends StatefulWidget {
  final Station station;
  final String frequency;

  const PumpingLogForm({super.key, required this.station, required this.frequency});

  @override
  State<PumpingLogForm> createState() => _PumpingLogFormState();
}

class _PumpingLogFormState extends State<PumpingLogForm> with FormHelpers {
  final _formKey = GlobalKey<FormState>();
  bool loading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => loading = true);
    
    try {
      formData['station_id'] = widget.station.id;
      formData['log_date'] = DateTime.now().toString().split(' ')[0];
      
      await OperatorService.submitPumpingLog(formData, widget.frequency);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Log Submitted Successfully")));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.station.name} - ${widget.frequency} Log"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await TokenStorage.clear();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const CitizenLoginPhone()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          children: [
             // --- DAILY ---
             if (widget.frequency == 'Daily') ...[
               buildDropdown("Shift Type", "shift_type", ["Day", "Night"]),
               buildTextField("Equipment ID (Optional)", "equipment_id", isNumber: true, isInt: true),

               buildDropdown("Pump Running Status", "pump_status", ["Running", "Standby", "Stopped"]),
               buildTextField("Number of Pumps Running", "pumps_running_count", isNumber: true, isInt: true),
               buildDropdown("Inlet Level Status", "inlet_level_status", ["Low", "Normal", "High"]),
               buildTextField("Outlet Pressure", "outlet_pressure", isNumber: true),
               buildTextField("Flow Rate (m³/hr)", "flow_rate", isNumber: true),
               buildTextField("Voltage (V)", "voltage", isNumber: true),
               buildTextField("Current (A)", "current_reading", isNumber: true),
               buildTextField("Power Factor", "power_factor", isNumber: true),
               buildDropdown("Panel Alarm Status", "panel_status", ["Normal", "Alarm"]),
               buildDropdown("Sump Cleanliness", "sump_cleanliness", ["Clean", "Dirty"]),
               
               buildSectionHeader("Checks & Flags"),
               buildSwitch("Vibration Abnormal?", "vibration_issue"),
               buildSwitch("Noise Abnormal?", "noise_issue"),
               buildSwitch("Leakage Detected?", "leakage_issue"),
               buildSwitch("Screen Bar Cleaned?", "screen_cleaned"),

               buildSectionHeader("Remarks"),
               buildTextField("Daily Remark", "remark"),
               buildImagePicker("Photo Evidence", "photo_url"),
             ],
             
              // --- WEEKLY ---
             if (widget.frequency == 'Weekly') ...[
               buildTextField("Equipment ID (Optional)", "equipment_id", isNumber: true, isInt: true),

               buildSwitch("Lubrication Done?", "lubrication_done"),
               buildDropdown("Valve Operation", "valve_status", ["Smooth", "Jammed"]),
               buildSwitch("Standby Pump Tested?", "standby_tested"),
               buildSwitch("Control Panel Cleaned?", "panel_cleaned"),
               buildDropdown("Earthing Status", "earthing_status", ["OK", "Issue"]),
               buildDropdown("Cable Condition", "cable_condition", ["Good", "Damaged"]),
               buildSwitch("Minor Fault Observed?", "minor_fault_found"),

               buildTextField("Weekly Remark", "remark"),
               buildImagePicker("Photo Evidence", "photo_url"),
             ],

             // --- MONTHLY ---
             if (widget.frequency == 'Monthly') ...[
               buildTextField("Equipment ID (Optional)", "equipment_id", isNumber: true, isInt: true),

               buildTextField("Motor Insulation (MΩ)", "insulation_resistance", isNumber: true),
               buildDropdown("Bearing Condition", "bearing_condition", ["Good", "Worn"]),
               buildDropdown("Alignment Status", "alignment_status", ["OK", "Misaligned"]),
               buildDropdown("Foundation Bolt Check", "bolt_status", ["Tight", "Loose"]),
               buildDropdown("Starter Panel Test", "starter_status", ["Normal", "Fault"]),
               buildSwitch("Load Test Conducted?", "load_test_done"),
               buildTextField("Energy Consumption (kWh)", "energy_consumption", isNumber: true),
               buildTextField("Preventive Action Taken", "preventive_action"),
               buildTextField("Monthly Remark", "remark"),
             ],

             // --- YEARLY ---
             if (widget.frequency == 'Yearly') ...[
               buildTextField("Equipment ID (Optional)", "equipment_id", isNumber: true, isInt: true),

               buildSwitch("Pump Overhaul Done?", "pump_overhaul_done"),
               buildSwitch("Motor Rewinding Done?", "motor_rewinding_done"),
               buildDropdown("Impeller Condition", "impeller_condition", ["Good", "Replaced"]),
               buildSwitch("Seal Gasket Replaced?", "seal_replaced"),
               buildSwitch("Electrical Calibration Done?", "calibration_done"),
               buildDropdown("Capacity Test Result", "capacity_test_result", ["Pass", "Fail"]),
               buildSwitch("Safety Audit Done?", "safety_audit_done"),
               buildSwitch("Third Party Inspection Done?", "inspection_done"),
               buildTextField("Yearly Remark", "remark"),
             ],

             const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary, 
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
               onPressed: loading ? null : _submit,
               child: loading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text("SUBMIT LOG", style: TextStyle(color: Colors.white, fontSize: 16)),
             )
          ],
        ),
      ),
    );
  }
}
