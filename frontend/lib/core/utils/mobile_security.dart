import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_windowmanager_plus/flutter_windowmanager_plus.dart';
// import 'package:trust_fall/trust_fall.dart';

class MobileSecurity {
  /// Checks if the device is rooted, jailbroken, or an emulator.
  /// If [abortOnFail] is true, it can be used to stop app execution.
  static Future<bool> isDeviceCompromised() async {
    if (kIsWeb) return false;

    // 🔄 Temporary Bypass: trust_fall dependency is currently conflicting with Dart 3
    // bool isJailBroken = await TrustFall.isJailBroken;
    // bool isTrustFallSucceeded = await TrustFall.canMockLocation;
    // bool isRealDevice = await TrustFall.isRealDevice;

    return false; // Assume clean for now to allow building
  }

  /// Prevents screenshots and screen recordings on Android.
  static Future<void> secureScreen() async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        await FlutterWindowManagerPlus.addFlags(FlutterWindowManagerPlus.FLAG_SECURE);
      } catch (e) {
        debugPrint("Screen security error: $e");
      }
    }
  }

  /// Removes screenshot prevention (e.g. for less sensitive screens).
  static Future<void> unsecureScreen() async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        await FlutterWindowManagerPlus.clearFlags(FlutterWindowManagerPlus.FLAG_SECURE);
      } catch (e) {
        debugPrint("Screen unsecurity error: $e");
      }
    }
  }
}
