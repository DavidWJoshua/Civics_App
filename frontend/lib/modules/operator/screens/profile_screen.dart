import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/profile_model.dart';
import '../services/profile_service.dart';
import '../services/operator_service.dart';
import '../models/operator_models.dart';
import '../../../core/theme/app_colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  OperatorProfile? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final profile = await ProfileService.getProfile();
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading profile: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_profile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Complete Your Profile')),
        body: _ProfileForm(onSubmit: _loadProfile),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Operator Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => Scaffold(
                    appBar: AppBar(title: const Text('Edit Profile')),
                    body: _ProfileForm(
                      initialProfile: _profile,
                      onSubmit: _loadProfile,
                    ),
                  ),
                ),
              );
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 32),
            const Text('Performance Statistics', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildComplianceChart(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.primary,
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_profile!.name.isEmpty ? 'Operator' : _profile!.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(_profile!.phoneNumber, style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Chip(
                        label: Text(_profile!.stationName ?? 'No Station'),
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        side: BorderSide.none,
                      ),
                      Chip(
                        label: Text('Shift: ${_profile!.shift}'),
                        backgroundColor: AppColors.success.withOpacity(0.1),
                        side: BorderSide.none,
                      ),
                      Chip(
                        label: Text('Ward: ${_profile!.wardNumber ?? "N/A"}'),
                        backgroundColor: AppColors.warning.withOpacity(0.1),
                        side: BorderSide.none,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      children: [
        _StatCard(title: 'Logs Submitted', value: _profile!.logsSubmitted.toString(), icon: Icons.description, color: Colors.blue),
        _StatCard(title: 'Pending Tickets', value: _profile!.pendingTickets.toString(), icon: Icons.pending_actions, color: Colors.orange),
        _StatCard(title: 'Faults Reported', value: _profile!.totalFaultsReported.toString(), icon: Icons.report_problem, color: Colors.red),
        _StatCard(title: 'Score', value: '${_profile!.performanceScore.toStringAsFixed(1)} / 10', icon: Icons.star, color: Colors.amber),
      ],
    );
  }

  Widget _buildComplianceChart() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text('Compliance Percentage', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      color: AppColors.success,
                      value: _profile!.compliancePercentage,
                      title: '${_profile!.compliancePercentage.toStringAsFixed(1)}%',
                      radius: 60,
                      titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    PieChartSectionData(
                      color: AppColors.error.withOpacity(0.3),
                      value: 100 - _profile!.compliancePercentage,
                      title: '',
                      radius: 50,
                    ),
                  ],
                  sectionsSpace: 4,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// Form to Create/Edit Profile
class _ProfileForm extends StatefulWidget {
  final OperatorProfile? initialProfile;
  final VoidCallback onSubmit;

  const _ProfileForm({this.initialProfile, required this.onSubmit});

  @override
  State<_ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<_ProfileForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  String _shift = 'Morning';
  Station? _selectedStation;
  List<Station> _stations = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialProfile != null) {
      _nameController.text = widget.initialProfile!.name;
      _phoneController.text = widget.initialProfile!.phoneNumber;
      _shift = widget.initialProfile!.shift.isNotEmpty ? widget.initialProfile!.shift : 'Morning';
    }
    _loadStations();
  }

  Future<void> _loadStations() async {
    try {
      final stations = await OperatorService.getStations();
      setState(() {
        _stations = stations;
        if (widget.initialProfile != null && widget.initialProfile!.stationId != null) {
          try {
            _selectedStation = stations.firstWhere((s) => s.id == widget.initialProfile!.stationId);
          } catch (_) {}
        }
      });
    } catch (e) {
      print('Error loading stations: $e');
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedStation == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a station')));
      return;
    }

    setState(() => _isLoading = true);
    
    final payload = {
      'name': _nameController.text.trim(),
      'phone_number': _phoneController.text.trim(),
      'shift': _shift,
      'station_id': _selectedStation!.id,
      'is_active': true,
      // Default ward range based on station can be handled by backend
      'ward_from': widget.initialProfile?.wardFrom ?? 1,
      'ward_to': widget.initialProfile?.wardTo ?? 42,
    };

    try {
      if (widget.initialProfile == null) {
        await ProfileService.createProfile(payload);
      } else {
        await ProfileService.updateProfile(payload);
      }
      widget.onSubmit();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving profile: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            const Text('Please complete your profile details.', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
              validator: (v) => v!.isEmpty ? 'Name required' : null,
            ),
            const SizedBox(height: 16),
            // Phone could be disabled if derived from auth
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _shift,
              decoration: const InputDecoration(labelText: 'Shift', border: OutlineInputBorder()),
              items: ['Morning', 'Evening', 'Night'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (v) {
                if (v != null) setState(() => _shift = v);
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Station>(
              value: _selectedStation,
              decoration: const InputDecoration(labelText: 'Assigned Station', border: OutlineInputBorder()),
              items: _stations.map((s) => DropdownMenuItem(value: s, child: Text('${s.name} (${s.type})'))).toList(),
              onChanged: (v) {
                if (v != null) setState(() => _selectedStation = v);
              },
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(widget.initialProfile == null ? 'Save Profile' : 'Update Profile'),
            )
          ],
        ),
      ),
    );
  }
}
