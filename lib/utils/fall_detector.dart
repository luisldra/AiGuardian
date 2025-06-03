import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:vibration/vibration.dart';
import 'package:http/http.dart' as http;
import 'package:object_detection_app/services/twilio_service.dart';

class FallDetector {
  final FlutterTts flutterTts = FlutterTts();
  StreamSubscription<AccelerometerEvent>? _subscription;
  final Function(String message)? onFallDetected;
  final TwilioService _twilioService = TwilioService();

  FallDetector({this.onFallDetected});

  void startMonitoring() {
    _subscription = accelerometerEvents.listen((AccelerometerEvent event) async {
      double acceleration = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);

      if (acceleration > 20) {
        if (await Vibration.hasVibrator() ?? false) {
          Vibration.vibrate(duration: 1000);
        }

        flutterTts.setLanguage("es-ES");
        await flutterTts.speak("¡Alerta! Se ha detectado una caída.");

        final message = "Se ha detectado una caída en el usuario. Verifique la pagina web para ver la ubicación.";
        if (onFallDetected != null) {
          onFallDetected!(message);
        }

        await sendFallSmsAlert(message);
      }
    });
  }

  void stopMonitoring() {
    _subscription?.cancel();
  }

  // 🔔 Enviar mensaje SMS al detectar caída
  Future<void> sendFallSmsAlert(String message) async {
  final response = await http.post(
    Uri.parse("https://fd0a1828-05dd-45a5-b1bc-0a3e9a423ee1-00-2w3wskwi4je44.spock.replit.dev:3000/sendFallAlert"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({
      "to": "+573226245548", // Número de destino
      "message": message,
    }),
  );

  if (response.statusCode == 200) {
    print("✅ SMS enviado exitosamente");
  } else {
    print("❌ Error al enviar SMS: ${response.body}");
  }
}

}

