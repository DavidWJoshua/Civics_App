import 'package:flutter/material.dart';
import '../models/operator_models.dart';

class STPDailyForm extends StatelessWidget {
  final Station station;

  const STPDailyForm({super.key, required this.station});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("STP Daily Log - ${station.name}")),
      body: const Center(child: Text("STP Form Coming Soon")),
    );
  }
}
