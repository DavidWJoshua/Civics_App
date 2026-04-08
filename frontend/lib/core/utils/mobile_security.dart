import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import 'package:trust_fall/trust_fall.dart';

class MobileSecurity {
  /// Checks if the device is rooted, jailbroken, or an emulator.
  /// If [abortOnFail] is true, it can be used to stop app execution.
  static Future<bool> isDeviceCompromised() async {
    if (kIsWeb) return false;

    bool isJailBroken = await TrustFall.isJailBroken;
    bool isTrustFallSucceeded = await TrustFall.canMockLocation; // If can mock, usually means dev/rooted
    bool isRealDevice = await TrustFall.isRealDevice;

    // We flag as compromised if it's jailbroken OR if it's an emulator trying to bypass checks.
    if (isJailBroken || !isRealDevice) {
      return true;
    }
    return false;
  }

  /// Prevents screenshots and screen recordings on Android.
  static Future<void> secureScreen() async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
      } catch (e) {
        debugPrint("Screen security error: $e");
      }
    }
  }

  /// Removes screenshot prevention (e.g. for less sensitive screens).
  static Future<void> unsecureScreen() async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        await FlutterWindowManager.clearFlags(FlutterWindowManager.FLAG_SECURE);
      } catch (e) {
        debugPrint("Screen unsecurity error: $e");
      }
    }
  }
}
