// lib/services/gemini_service.dart

import 'dart:typed_data';

import 'package:flutter/foundation.dart'; // debugPrint
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class InvernaderoChatService {
  late final ChatSession _chat;

  // 🔹 Instrucción del sistema: identidad + límites + video sugerido
  static const String _systemInstructionText = '''
Eres HydroBot, un asistente de inteligencia artificial experto en invernaderos.

REGLAS DE IDENTIDAD:
- Siempre que el usuario pregunte quién eres, di que eres "HydroBot".
- No menciones nunca que eres Gemini, modelo de lenguaje, ni detalles técnicos del modelo.
- Habla siempre en primera persona como asistente especializado en invernaderos.

ÁMBITO DE CONOCIMIENTO:
Solo puedes responder sobre temas relacionados con:
- Plantas de invernadero.
- Plagas y enfermedades de cultivos.
- Riego (frecuencia, cantidad, tipos de riego).
- Abonos y fertilización.
- Identificación y cuidado de plantas.
- Condiciones de clima, humedad, luz y manejo dentro de un invernadero.
- Sistemas de cultivo (por ejemplo, hidroponía en invernadero).

Si el usuario pregunta algo fuera de eso:
- Responde exactamente: "Mi función es exclusivamente para invernaderos."
- No intentes responder temas fuera de tu alcance.

ESTILO:
- Siempre responde en español, formal y claro.
- Usa pasos o viñetas cuando des recomendaciones prácticas.

FORMATO DE VIDEO (OBLIGATORIO):
Al final de CADA respuesta agrega una sola línea con este formato EXACTO:
---VIDEO SUGERIDO---Texto corto para buscar en YouTube
''';

  InvernaderoChatService() {
    _initializeChat();
  }

  void _initializeChat() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];

    // 👇 MODELO: usamos el del .env o, si no, 'gemini-1.5-flash-001' (v1beta)
    final modelName = dotenv.env['GEMINI_MODEL'] ?? 'gemini-1.5-flash-001';

    if (apiKey == null || apiKey.isEmpty) {
      throw Exception(
        "Error: La clave API (GEMINI_API_KEY) no fue encontrada. Revisa tu archivo .env.",
      );
    }

    debugPrint('🔑 Iniciando Gemini con modelo: $modelName');

    final model = GenerativeModel(
      model: modelName,
      apiKey: apiKey,
      systemInstruction: Content.text(_systemInstructionText),
    );

    _chat = model.startChat();
  }

  // =============== TEXTO ===============
  Future<String> sendMessage(String message) async {
    try {
      final response = await _chat.sendMessage(Content.text(message));
      return response.text ?? 'Error: No se recibió respuesta válida.';
    } on GenerativeAIException catch (e) {
      // Para debug en consola
      debugPrint('❌ GenerativeAIException en sendMessage: $e');
      return "Lo siento, hubo un error al responder desde HydroBot. Por favor, inténtalo de nuevo en unos momentos.";
    } catch (e) {
      debugPrint('❌ Error inesperado en sendMessage: $e');
      return "Lo siento, hubo un error de conexión con HydroBot. Detalle: $e";
    }
  }

  // =============== MULTIMODAL (TEXTO + IMAGEN) ===============
  Future<String> sendMultimodalMessage(
    String textPrompt,
    Uint8List imageBytes,
    String mimeType,
  ) async {
    try {
      final response = await _chat.sendMessage(
        Content.multi([
          TextPart(
            'El usuario te envía una imagen relacionada con plantas o cultivos en invernadero. '
            'Analiza la imagen y responde siguiendo estrictamente tus reglas de HydroBot.\n\n'
            'Texto del usuario: $textPrompt',
          ),
          DataPart(mimeType, imageBytes),
        ]),
      );
      return response.text ?? 'Error al procesar la imagen.';
    } on GenerativeAIException catch (e) {
      debugPrint('❌ GenerativeAIException en sendMultimodalMessage: $e');
      return "Lo siento, hubo un error al analizar la imagen en HydroBot. Por favor, inténtalo de nuevo.";
    } catch (e) {
      debugPrint('❌ Error inesperado en sendMultimodalMessage: $e');
      return "Lo siento, hubo un error al analizar la imagen. Detalle: $e";
    }
  }
}
