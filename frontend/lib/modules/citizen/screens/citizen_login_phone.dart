import 'package:flutter/material.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/utils/api_constants.dart';
import '../../../core/theme/app_colors.dart';
import 'citizen_login_otp.dart';

class CitizenLoginPhone extends StatefulWidget {
  const CitizenLoginPhone({super.key});

  @override
  State<CitizenLoginPhone> createState() => _CitizenLoginPhoneState();
}

class _CitizenLoginPhoneState extends State<CitizenLoginPhone> {
  final phoneCtrl = TextEditingController();
  final captchaCtrl = TextEditingController();

  String captchaId = "";
  bool loading = false;
  bool captchaLoading = false;
  String? captchaError;

  @override
  void initState() {
    super.initState();
    refreshCaptcha();
  }

  Future<void> refreshCaptcha() async {
    setState(() {
      captchaLoading = true;
      captchaError = null;
    });
    try {
      final res = await AuthService.getCaptcha();
      if (!mounted) return;
      setState(() {
        captchaId = res["captchaID"]!;
        captchaLoading = false;
        captchaError = null;
        captchaCtrl.clear();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        captchaLoading = false;
        captchaError = "Failed to load captcha. Tap refresh to retry.";
      });
    }
  }

  Future<void> sendOtp() async {
    final entered = phoneCtrl.text.trim();

    if (entered.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter valid 10-digit number")),
      );
      return;
    }

    if (captchaCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter captcha")),
      );
      return;
    }

    final phone = "+91$entered";
    setState(() => loading = true);

    try {
      final isOfficer = await AuthService.sendOtp(
        phone,
        captchaId,
        captchaCtrl.text.trim(),
      );

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CitizenLoginOtp(
            phone: phone,
            isOfficer: isOfficer,
          ),
        ),
      );
    } catch (_) {
      refreshCaptcha();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to send OTP. Check captcha.")),
      );
    }

    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary.withOpacity(0.05),
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
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.account_balance,
                    color: AppColors.primary,
                    size: 64,
                  ),
                ),
                const SizedBox(height: 24),

                const Text(
                  "Civic Connect",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 8),

                Text(
                  "Your voice for a better city",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
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
                        controller: phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: "Phone Number",
                          prefixText: "+91 ",
                          prefixStyle: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // --- CAPTCHA SECTION ---
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 60,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.grey[50],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: captchaLoading
                                    ? const Center(
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : captchaError != null
                                        ? Center(
                                            child: Text(
                                              "Tap ↻ to load captcha",
                                              style: TextStyle(
                                                color: Colors.red[400],
                                                fontSize: 13,
                                              ),
                                            ),
                                          )
                                        : captchaId.isEmpty
                                            ? const Center(
                                                child: CircularProgressIndicator(strokeWidth: 2),
                                              )
                                            : Image.network(
                                                "${ApiConstants.baseUrl}/api/auth/citizen/captcha/$captchaId",
                                                fit: BoxFit.contain,
                                                key: ValueKey(captchaId),
                                                loadingBuilder: (context, child, progress) {
                                                  if (progress == null) return child;
                                                  return const Center(
                                                    child: CircularProgressIndicator(strokeWidth: 2),
                                                  );
                                                },
                                                errorBuilder: (context, error, stack) {
                                                  return Center(
                                                    child: Text(
                                                      "Image failed — tap ↻",
                                                      style: TextStyle(
                                                        color: Colors.red[400],
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: captchaLoading ? null : refreshCaptcha,
                            icon: Icon(
                              Icons.refresh,
                              color: captchaLoading
                                  ? Colors.grey
                                  : AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: captchaCtrl,
                        decoration: InputDecoration(
                          labelText: "Enter Captcha",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      ElevatedButton(
                        onPressed: loading ? null : sendOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D47A1),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                "Send OTP",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                Text(
                  "By continuing, you agree to our Terms & Conditions",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
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
