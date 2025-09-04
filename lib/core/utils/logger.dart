import 'package:flutter/foundation.dart';

class Logger {
  static void debug(String message) {
    if (kDebugMode) {
      debugPrint('[DEBUG] $message');
    }
  }

  static void info(String message) {
    if (kDebugMode) {
      debugPrint('[INFO] $message');
    }
  }

  static void warning(String message) {
    if (kDebugMode) {
      debugPrint('[WARNING] $message');
    }
  }

  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('[ERROR] $message');
      if (error != null) {
        debugPrint('[ERROR Details] $error');
      }
      if (stackTrace != null && kDebugMode) {
        debugPrint('[Stack Trace] $stackTrace');
      }
    }
  }

  static void success(String message) {
    if (kDebugMode) {
      debugPrint('[SUCCESS] ✅ $message');
    }
  }
}
