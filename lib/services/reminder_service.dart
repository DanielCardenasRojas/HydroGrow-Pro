import 'package:dio/dio.dart';

class ReminderService {
  final Dio _dio = Dio();

  // 👇 Usa aquí TU Production URL de n8n
  static const String _webhookUrl =
      'https://danielarr08.app.n8n.cloud/webhook/nuevo-recordatorio';

  Future<void> crearRecordatorio({
    required String title,
    required String body,
    required DateTime dateTime,
    required String deviceToken,
  }) async {
    final payload = {
      'title': title,
      'body': body,
      'datetime': dateTime.toUtc().toIso8601String(),
      'deviceToken': deviceToken,
    };

    await _dio.post(_webhookUrl, data: payload);
  }
}
