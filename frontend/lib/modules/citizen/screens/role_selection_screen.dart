import 'package:flutter/material.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/utils/token_storage.dart';
import '../../field_officer/screens/officer_dashboard.dart';
import 'citizen_home.dart';
import '../../junior_engineer/screens/je_dashboard.dart';
import '../../commissioner/screens/commissioner_dashboard.dart';

class RoleSelectionScreen extends StatefulWidget {
  final String phone;
  final String otp;

  const RoleSelectionScreen({
    super.key,
    required this.phone,
    required this.otp,
  });

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  bool loading = false;

  Future<void> loginAs(String selectedRole) async {
  setState(() => loading = true);

  try {
    final res = await AuthService.verifyOtp(
      widget.phone,
      widget.otp,
      role: selectedRole,
    );

    final String token = res["token"];

    // 🔥 IMPORTANT: Decode role from backend if returned
    final String actualRole = res["role"] ?? selectedRole;

    await TokenStorage.saveToken(token);
    await TokenStorage.saveRole(actualRole);

    Widget nextScreen;

    switch (actualRole) {
      case "FIELD_OFFICER":
        nextScreen = const OfficerDashboard();
        break;

      case "JUNIOR_ENGINEER":
        nextScreen = JEDashboard();
        break;

      case "COMMISSIONER":
        nextScreen = CommissionerDashboard();
        break;

      default:
        nextScreen = const CitizenHome();
    }

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => nextScreen),
        (route) => false,
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Login failed. Invalid OTP or role."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  if (mounted) setState(() => loading = false);
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Select Role"),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Who are you?",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Select your account type to continue",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 48),

            // Citizen Button
            _RoleButton(
              title: "Citizen",
              icon: Icons.person_outline,
              color: const Color(0xFF0D47A1),
              isLoading: loading,
              onTap: () => loginAs("CITIZEN"),
            ),

            const SizedBox(height: 24),

            // Staff Button
            _RoleButton(
              title: "Staff",
              icon: Icons.badge_outlined,
              color: const Color(0xFF43A047),
              isLoading: loading,
              onTap: () => loginAs(""),
            ),

            const SizedBox(height: 24),

            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Go Back"),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final bool isLoading;
  final VoidCallback onTap;

  const _RoleButton({
    required this.title,
    required this.icon,
    required this.color,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 20),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const Spacer(),
            if (isLoading)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(Icons.arrow_forward_ios, color: color, size: 20),
          ],
        ),
      ),
    );
  }
}
