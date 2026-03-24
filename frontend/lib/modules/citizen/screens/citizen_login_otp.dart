import 'package:flutter/material.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/utils/token_storage.dart';

import '../../field_officer/screens/officer_dashboard.dart';
import '../../junior_engineer/screens/je_dashboard.dart';
import '../../commissioner/screens/commissioner_dashboard.dart';
import '../../operator/screens/operator_dashboard.dart';
import 'citizen_home.dart';
import 'role_selection_screen.dart';

class CitizenLoginOtp extends StatefulWidget {
  final String phone;
  final bool isOfficer;

  const CitizenLoginOtp({
    super.key,
    required this.phone,
    required this.isOfficer,
  });

  @override
  State<CitizenLoginOtp> createState() => _CitizenLoginOtpState();
}

class _CitizenLoginOtpState extends State<CitizenLoginOtp> {
  final TextEditingController otpCtrl = TextEditingController();
  bool loading = false;

  void verifyOtp() {
    if (otpCtrl.text.trim().length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter valid 6-digit OTP")),
      );
      return;
    }

    setState(() => loading = true);
    _verifyAndLoginCitizen();
  }

  Future<void> _verifyAndLoginCitizen() async {
    try {
      String? roleToSend = "CITIZEN";
      
      if (widget.isOfficer) {
         final selected = await showDialog<String>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text("Select Login Type"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text("Citizen"),
                  leading: const Icon(Icons.person, color: Color(0xFF0D47A1)),
                  onTap: () => Navigator.pop(ctx, "CITIZEN"),
                ),
                const Divider(),
                ListTile(
                  title: const Text("Staff"),
                  leading: const Icon(Icons.badge, color: Color(0xFF0D47A1)),
                  onTap: () => Navigator.pop(ctx, "STAFF"),
                ),
              ],
            ),
          ),
        );
        if (selected == null) {
           setState(() => loading = false);
           return;
        }
        roleToSend = selected == "STAFF" ? "" : selected;
      }

      final res = await AuthService.verifyOtp(
        widget.phone,
        otpCtrl.text.trim(),
        role: roleToSend!,
      );

      final String token = res["token"];
      final String role = res["role"];
      
      await TokenStorage.saveToken(token);
      await TokenStorage.saveRole(role);

      if (mounted) {
        if (role == "FIELD_OFFICER") {
             Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const OfficerDashboard()),
            (route) => false,
          );
        } else if (role == "JUNIOR_ENGINEER") {
             Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const JEDashboard()),
            (route) => false,
          );
        } else if (role == "COMMISSIONER") {
             Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const CommissionerDashboard()),
            (route) => false,
          );
        } else if (role.contains("OPERATOR")) {
             Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const OperatorDashboard()),
            (route) => false,
          );
        } else {
             Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const CitizenHome()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid OTP ")),
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
        title: const Text("Verify Account",
            style: TextStyle(
                color: Color(0xFF1A1A1A), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Color(0xFF1A1A1A)),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF0D47A1).withOpacity(0.05),
              Colors.white,
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF43A047).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mark_email_read_outlined,
                    color: Color(0xFF43A047),
                    size: 60,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  "Verification Code",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Enter the 6-digit code sent to\n${widget.phone}",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 48),

                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: otpCtrl,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 8,
                        ),
                        maxLength: 6,
                        decoration: InputDecoration(
                          hintText: "000000",
                          hintStyle: TextStyle(
                              color: Colors.grey[300], letterSpacing: 8),
                          counterText: "",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: loading ? null : verifyOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D47A1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                "Verify Code",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "Didn't receive code? Resend",
                    style: TextStyle(
                      color: Color(0xFF0D47A1),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
