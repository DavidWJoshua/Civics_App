import 'package:flutter/material.dart';
import '../../../core/utils/token_storage.dart';
import '../../citizen/screens/citizen_login_phone.dart';
import '../models/operator_models.dart';
import '../services/operator_service.dart';
import 'form_helpers.dart';
import '../../../core/theme/app_colors.dart';

class StpLogForm extends StatefulWidget {
  final Station station;
  final String frequency;

  const StpLogForm({super.key, required this.station, required this.frequency});

  @override
  State<StpLogForm> createState() => _StpLogFormState();
}

class _StpLogFormState extends State<StpLogForm> with FormHelpers {
  final _formKey = GlobalKey<FormState>();
  bool loading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => loading = true);
    
    try {
      formData['station_id'] = widget.station.id;
      formData['log_date'] = DateTime.now().toString().split(' ')[0];
      
      await OperatorService.submitStpLog(formData, widget.frequency);
      
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
        title: Text("STP ${widget.frequency} Log"),
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
             if (widget.frequency == 'Daily') ...[
               buildSectionHeader("Inlet (Raw Sewage) Check"),
               buildTextField("Inlet Flow Rate (MLD)", "inlet_flow_rate", isNumber: true),
               buildTextField("Inlet pH", "inlet_ph", isNumber: true),
               buildTextField("Inlet BOD (mg/L)", "inlet_bod", isNumber: true),
               buildTextField("Inlet COD (mg/L)", "inlet_cod", isNumber: true),
               buildTextField("Inlet TSS (mg/L)", "inlet_tss", isNumber: true),
               buildTextField("Inlet Oil/Grease (mg/L)", "inlet_oil_grease", isNumber: true),
               buildTextField("Inlet Temperature (°C)", "inlet_temperature", isNumber: true),
               buildDropdown("Inlet Color/Odour", "inlet_color_odour", ["Normal", "Abnormal"]),

               buildSectionHeader("Process Control"),
               buildTextField("Dissolved Oxygen (mg/L)", "dissolved_oxygen", isNumber: true),
               buildTextField("MLSS (mg/L)", "mlss", isNumber: true),
               buildTextField("MCRT Sludge Age (Days)", "mcrt_sludge_age", isNumber: true),
               buildTextField("SV30 (mL/L)", "sv30", isNumber: true),
               buildTextField("F/M Ratio", "fm_ratio", isNumber: true),
               buildTextField("Blower Running Hours", "blower_running_hours", isNumber: true),
               buildTextField("Sludge Blanket Depth (m)", "sludge_blanket_depth", isNumber: true),
               buildTextField("RAS Flow Rate (m³/hr)", "ras_flow_rate", isNumber: true),
               buildTextField("WAS Flow Rate (m³/hr)", "was_flow_rate", isNumber: true),
               buildSwitch("Scum Presence?", "scum_presence_flag"),

               buildSectionHeader("Output (Treated Effluent)"),
               buildTextField("Outlet Flow Rate (MLD)", "outlet_flow_rate", isNumber: true),
               buildTextField("Outlet pH", "outlet_ph", isNumber: true),
               buildTextField("Outlet BOD (mg/L)", "outlet_bod", isNumber: true),
               buildTextField("Outlet COD (mg/L)", "outlet_cod", isNumber: true),
               buildTextField("Outlet TSS (mg/L)", "outlet_tss", isNumber: true),
               buildTextField("Outlet Oil/Grease (mg/L)", "outlet_oil_grease", isNumber: true),
               buildTextField("Outlet Fecal Coliform (MPN)", "outlet_fecal_coliform", isNumber: true),
               buildTextField("Residual Chlorine (mg/L)", "residual_chlorine", isNumber: true),

               buildSectionHeader("Sludge & Energy"),
               buildTextField("Sludge Generated (m³/day)", "sludge_generated", isNumber: true),
               buildTextField("Sludge Dried (MT)", "sludge_dried_quantity", isNumber: true),
               buildTextField("Moisture Content (%)", "moisture_content", isNumber: true),
               buildTextField("Disposal Method", "disposal_method"),
               buildDropdown("Drying Bed Condition", "drying_bed_condition", ["OK", "Not OK"]),
               
               buildTextField("Power Consumption (kWh)", "power_consumption_kwh", isNumber: true),
               buildTextField("Energy per MLD (kWh/MLD)", "energy_per_mld", isNumber: true),
               buildTextField("Chlorine Consumption (kg)", "chlorine_consumption", isNumber: true),
               buildTextField("Polymer Usage (kg)", "polymer_usage", isNumber: true),
               buildDropdown("Chemical Stock Status", "chemical_stock_status", ["Adequate", "Low"]),
             ],

             if (widget.frequency == 'Weekly') ...[
               buildSectionHeader("Maintenance & Calibration"),
               buildSwitch("Blower Maintenance Done?", "blower_maintenance_done"),
               buildSwitch("Diffuser Cleaning Done?", "diffuser_cleaning_done"),
               buildDropdown("Clarifier Mechanism Check", "clarifier_mechanism_check", ["OK", "Issue"]),
               buildSwitch("Lab Equipment Calibrated?", "lab_equipment_calibrated"),
               buildDropdown("Online Analyzer Status", "online_analyzer_status", ["Working", "Faulty"]),
               buildTextField("Remark", "remark"),
             ],
             
             // Add Monthly/Yearly placeholders if needed but not explicitly detailed yet for STP beyond general structure
             if (widget.frequency == 'Monthly' || widget.frequency == 'Yearly') ...[
                 buildTextField("Remark", "remark"),
                 buildImagePicker("Report/Evidence", "photo_url"),
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
