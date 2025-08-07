import 'package:flutter/services.dart';

class AppHapticHelper {
  /// Light impact feedback (e.g., light tap)
  static Future<void> lightImpact() async {
    await HapticFeedback.lightImpact();
  }

  /// Medium impact feedback (e.g., toggle switch)
  static Future<void> mediumImpact() async {
    await HapticFeedback.mediumImpact();
  }

  /// Heavy impact feedback (e.g., drag finish)
  static Future<void> heavyImpact() async {
    await HapticFeedback.heavyImpact();
  }

  /// Selection click (e.g., picker scroll)
  static Future<void> selectionClick() async {
    await HapticFeedback.selectionClick();
  }

  /// Vibrate with a standard vibration pattern
  static Future<void> vibrate() async {
    await HapticFeedback.vibrate();
  }
}
