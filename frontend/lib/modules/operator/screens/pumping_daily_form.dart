import 'package:flutter/material.dart';
import '../models/operator_models.dart';

class PumpingDailyForm extends StatelessWidget {
  final Station station;

  const PumpingDailyForm({super.key, required this.station});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Pumping Daily Log - ${station.name}")),
      body: const Center(child: Text("Pumping Form Coming Soon")),
    );
  }
}
