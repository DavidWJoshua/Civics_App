import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'modules/citizen/screens/citizen_login_phone.dart';
import 'modules/citizen/screens/citizen_home.dart';
import 'modules/field_officer/screens/officer_dashboard.dart';
import 'core/utils/secure_token_storage.dart';
import 'core/services/api_client.dart';
import 'core/utils/mobile_security.dart';

import 'core/theme/app_colors.dart';

void main() {
  runApp(const CivicApp());
}

class CivicApp extends StatefulWidget {
  const CivicApp({super.key});

  @override
  State<CivicApp> createState() => _CivicAppState();
}

class _CivicAppState extends State<CivicApp> {
  bool _isLoading = true;
  String? _token;
  String? _role;

  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    // Listen for session expiry (token refresh failed) → redirect to login
    SessionEvents.addListener(_onSessionExpired);
  }

  @override
  void dispose() {
    SessionEvents.removeListener(_onSessionExpired);
    super.dispose();
  }

  void _onSessionExpired() {
    // Navigate to login and show message
    _navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const CitizenLoginPhone()),
      (_) => false,
    );
    SchedulerBinding.instance.addPostFrameCallback((_) {
      final ctx = _navigatorKey.currentContext;
      if (ctx != null) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(
            content: Text('Your session has expired. Please log in again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  Future<void> _checkLoginStatus() async {
    // 1. SECURE SCREEN (Android prevent screenshots/recording)
    await MobileSecurity.secureScreen();

    // 2. CHECK DEVICE INTEGRITY
    final isCompromised = await MobileSecurity.isDeviceCompromised();
    if (isCompromised) {
      debugPrint("🚨 Warning: Device may be rooted/jailbroken.");
      // You could stop the app here:
      // return;
    }

    final token = await SecureTokenStorage.getAccessToken();
    final role = await SecureTokenStorage.getRole();
    setState(() {
      _token = token;
      _role = role;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const MaterialApp(
        home: Scaffold(
          backgroundColor: AppColors.background,
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MaterialApp(
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Civic Complaint System',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.surface,
          error: AppColors.error,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            minimumSize: const Size(double.infinity, 54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 3,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade100, width: 1),
          ),
          shadowColor: Colors.black.withOpacity(0.05),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
      ),
      home: _token != null
          ? (_role == 'FIELD_OFFICER'
              ? const OfficerDashboard()
              : const CitizenHome())
          : const CitizenLoginPhone(),
    );
  }
}
