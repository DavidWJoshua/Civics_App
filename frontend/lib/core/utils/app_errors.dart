import 'package:flutter/foundation.dart';

/// AppErrors maps raw exceptions to safe, user-friendly messages.
///
/// Raw exception detail is always written to [debugPrint] so developers can
/// still diagnose issues in the console, but it is never shown in the UI.
class AppErrors {
  AppErrors._();

  /// Returns a generic, safe message suitable for display in the UI.
  ///
  /// [fallback] is used when no matching pattern is found.
  static String friendly(
    Object e, {
    String fallback = 'Something went wrong. Please try again.',
  }) {
    // Always log the real error for developer visibility.
    debugPrint('[AppError] ${e.toString()}');

    final raw = e.toString().toLowerCase();

    // Network / connectivity
    if (raw.contains('socketexception') ||
        raw.contains('connection refused') ||
        raw.contains('failed host lookup') ||
        raw.contains('network')) {
      return 'Network error. Please check your connection.';
    }

    // Authentication
    if (raw.contains('401') ||
        raw.contains('unauthorized') ||
        raw.contains('token') ||
        raw.contains('not logged in')) {
      return 'Session expired. Please log in again.';
    }

    // Authorisation
    if (raw.contains('403') ||
        raw.contains('forbidden') ||
        raw.contains('access denied')) {
      return 'You don\'t have permission to do that.';
    }

    // Not found
    if (raw.contains('404')) {
      return 'The requested item was not found.';
    }

    // Rate limited
    if (raw.contains('429') || raw.contains('too many')) {
      return 'Too many attempts. Please wait a moment and try again.';
    }

    // Server errors
    if (raw.contains('500') ||
        raw.contains('server error') ||
        raw.contains('internal')) {
      return 'Server error. Please try again later.';
    }

    // Timeout
    if (raw.contains('timeout') || raw.contains('timed out')) {
      return 'Request timed out. Please try again.';
    }

    return fallback;
  }
}
