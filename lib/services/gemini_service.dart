// lib/services/gemini_service.dart
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:typed_data';

class InvernaderoChatService {
  late final ChatSession _chat;

  // Instrucción del sistema
  static const String _systemInstructionText =
      "Eres HydroGrowBot, un experto en invernaderos. Tu conocimiento está LIMITADO a: plagas, enfermedades, riego, abono, e identificación de plantas. Siempre incluye al final de tu respuesta una sugerencia de video de YouTube con el formato exacto: '---VIDEO SUGERIDO---Título del video o búsqueda clave'. Si la pregunta no es de invernadero, responde: 'Mi función es exclusivamente para invernaderos.' Utiliza lenguaje formal y en español.";

  InvernaderoChatService() {
    _initializeChat();
  }

  void _initializeChat() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    final modelName = dotenv.env['GEMINI_MODEL'] ?? 'gemini-1.5-flash';

    if (apiKey == null || apiKey.isEmpty) {
      throw Exception(
        "Error: La clave API (GEMINI_API_KEY) no fue encontrada. Revisa tu archivo .env.",
      );
    }

    // PASO CLAVE: la instrucción del sistema va aquí
    final model = GenerativeModel(
      model: modelName,
      apiKey: apiKey,
      systemInstruction: Content.text(_systemInstructionText),
      // opcional: generationConfig: GenerationConfig(temperature: 0.7),
    );

    // startChat ya no acepta 'config'; devuelve un ChatSession
    _chat = model.startChat(
      // opcional: history: [Content.text("contexto previo...")],
    );
  }

  Future<String> sendMessage(String message) async {
    try {
      final response = await _chat.sendMessage(Content.text(message));
      return response.text ?? 'Error: No se recibió respuesta válida.';
    } catch (e) {
      return "Lo siento, hubo un error de conexión con HydroGrowBot. Por favor, inténtalo de nuevo.";
    }
  }

  Future<String> sendMultimodalMessage(
    String textPrompt,
    Uint8List imageBytes,
    String mimeType,
  ) async {
    try {
      final response = await _chat.sendMessage(
        Content.multi([TextPart(textPrompt), DataPart(mimeType, imageBytes)]),
      );
      return response.text ?? 'Error al procesar la imagen.';
    } catch (e) {
      return "Lo siento, hubo un error al analizar la imagen. ¿Podrías describirme el problema?";
    }
  }
}
