import 'package:http/http.dart' as http;
import 'dart:convert';

class TwilioService {
  final String apiUrl = 'https://fd0a1828-05dd-45a5-b1bc-0a3e9a423ee1-00-2w3wskwi4je44.spock.replit.dev:3000/sendFallAlert';

  Future<void> sendFallAlert({required String toPhoneNumber, required String message}) async {
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'to': toPhoneNumber,
          'message': message,
        }),
      );

      if (response.statusCode == 200) {
        print('✅ SMS enviado correctamente');
      } else {
        print('❌ Error al enviar SMS: ${response.body}');
      }
    } catch (e) {
      print('❗ Excepción al enviar SMS: $e');
    }
  }
}
