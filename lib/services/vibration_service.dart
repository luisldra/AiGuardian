// lib/services/vibration_service.dart
import 'package:vibration/vibration.dart';

class VibrationService {
  /// Verifica y ejecuta un patrón de vibración si el dispositivo lo permite
  static Future<void> vibrateIfPossible({List<int>? pattern, int? duration}) async {
    try {
      final canVibrate = await Vibration.hasVibrator();
      if (canVibrate == true) {
        final hasAmplitudeControl = await Vibration.hasAmplitudeControl();
        if (pattern != null) {
          await Vibration.vibrate(pattern: pattern);
        } else {
          await Vibration.vibrate(duration: duration ?? 500);
        }
        print("✅ Dispositivo vibró");
      } else {
        print("❌ Dispositivo no tiene vibración");
      }
    } catch (e) {
      print("⚠️ Error al intentar vibrar: $e");
    }
  }
}
