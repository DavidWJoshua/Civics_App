import 'package:flutter/material.dart';
import '../models/operator_models.dart';
import '../services/operator_service.dart';

class LiftingDailyForm extends StatefulWidget {
  final Station station;

  const LiftingDailyForm({super.key, required this.station});

  @override
  State<LiftingDailyForm> createState() => _LiftingDailyFormState();
}

class _LiftingDailyFormState extends State<LiftingDailyForm> {
  final _formKey = GlobalKey<FormState>();
  bool loading = false;

  // Controllers / State
  final _dateCtrl = TextEditingController(text: DateTime.now().toString().split(' ')[0]);
  String _shift = "day";
  final _pumpStatusCtrl = TextEditingController(text: "Working");
  final _hoursCtrl = TextEditingController();
  final _voltageCtrl = TextEditingController();
  final _currentCtrl = TextEditingController(); // Amps
  
  bool _vibration = false;
  bool _noise = false;
  bool _leakage = false;
  
  String _sumpLevel = "Normal"; // Normal, High, Low
  String _panelStatus = "OK";
  bool _cleaning = false;
  final _remarkCtrl = TextEditingController();

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => loading = true);
    
    try {
      final log = LiftingDailyLog(
        stationId: widget.station.id,
        logDate: _dateCtrl.text,
        shiftType: _shift,
        pumpStatus: _pumpStatusCtrl.text,
        hoursReading: double.tryParse(_hoursCtrl.text) ?? 0,
        voltage: double.tryParse(_voltageCtrl.text) ?? 0,
        currentReading: double.tryParse(_currentCtrl.text) ?? 0,
        vibrationIssue: _vibration,
        noiseIssue: _noise,
        leakageIssue: _leakage,
        sumpLevelStatus: _sumpLevel,
        panelStatus: _panelStatus,
        cleaningDone: _cleaning,
        remark: _remarkCtrl.text,
      );

      await OperatorService.submitLiftingDailyLog(log.toJson());
      
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
      appBar: AppBar(title: Text("Daily Log - ${widget.station.name}")),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _dateCtrl,
              decoration: const InputDecoration(labelText: "Date (YYYY-MM-DD)"),
              readOnly: true,
              onTap: () async {
                 DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                 );
                 if(picked != null) {
                   setState(() => _dateCtrl.text = picked.toString().split(' ')[0]);
                 }
              },
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _shift,
              decoration: const InputDecoration(labelText: "Shift"),
              items: ["day", "night"].map((e) => DropdownMenuItem(value: e, child: Text(e.toUpperCase()))).toList(),
              onChanged: (v) => setState(() => _shift = v!),
            ),
            const Divider(),
            const Text("Pump Readings", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            TextFormField(
              controller: _hoursCtrl,
              decoration: const InputDecoration(labelText: "Running Hours"),
              keyboardType: TextInputType.number,
            ),
            Row(children: [
              Expanded(child: TextFormField(controller: _voltageCtrl, decoration: const InputDecoration(labelText: "Voltage (V)"), keyboardType: TextInputType.number)),
              const SizedBox(width: 10),
              Expanded(child: TextFormField(controller: _currentCtrl, decoration: const InputDecoration(labelText: "Current (A)"), keyboardType: TextInputType.number)),
            ]),
            const SizedBox(height: 10),
            SwitchListTile(title: const Text("Vibration Issue?"), value: _vibration, onChanged: (v) => setState(() => _vibration = v)),
            SwitchListTile(title: const Text("Noise Issue?"), value: _noise, onChanged: (v) => setState(() => _noise = v)),
            SwitchListTile(title: const Text("Leakage Issue?"), value: _leakage, onChanged: (v) => setState(() => _leakage = v)),
            
            const Divider(),
            const Text("Station Status", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
             DropdownButtonFormField<String>(
              value: _sumpLevel,
              decoration: const InputDecoration(labelText: "Sump Level"),
              items: ["Normal", "High", "Low", "Critical"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => _sumpLevel = v!),
            ),
             DropdownButtonFormField<String>(
              value: _panelStatus,
              decoration: const InputDecoration(labelText: "Panel Status"),
              items: ["OK", "Fault", "Trip"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => _panelStatus = v!),
            ),
            SwitchListTile(title: const Text("Cleaning Done?"), value: _cleaning, onChanged: (v) => setState(() => _cleaning = v)),
            
            const SizedBox(height: 10),
            TextFormField(
              controller: _remarkCtrl,
              decoration: const InputDecoration(labelText: "Remarks"),
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: loading ? null : _submit,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: loading ? const CircularProgressIndicator() : const Text("SUBMIT LOG"),
            )
          ],
        ),
      ),
    );
  }
}
