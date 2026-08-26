import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:coneccionone/services/tts/tts_engine.dart';

/// Motor OpenAI especializado en voz tecnológica masculina Onyx
class OpenAiEngine implements TtsEngine {
  static const String _defaultApiKey = String.fromEnvironment('OPENAI_API_KEY', defaultValue: '');

  @override
  String get name => 'OpenAI Onyx (Deep Tech)';

  @override
  bool isAvailable({String? apiKey}) {
    final key = apiKey?.trim().isNotEmpty == true ? apiKey! : _defaultApiKey;
    return key.isNotEmpty;
  }

  @override
  Future<TtsSynthesisResult> synthesize({
    required String text,
    TtsOptions options = const TtsOptions(),
  }) async {
    final key = options.apiKey?.trim().isNotEmpty == true ? options.apiKey! : _defaultApiKey;
    if (key.isEmpty) {
      throw StateError('OpenAI API Key no configurada.');
    }

    final processedText = JarvisTextPreprocessor.preprocess(text);
    if (processedText.isEmpty) {
      throw ArgumentError('El texto para reproducir no puede estar vacío.');
    }

    final voice = options.voiceId ?? 'onyx';
    final client = HttpClient();

    try {
      final url = Uri.parse('https://api.openai.com/v1/audio/speech');
      final request = await client.postUrl(url).timeout(const Duration(seconds: 20));
      request.headers.contentType = ContentType.json;
      request.headers.set('Authorization', 'Bearer $key');

      final body = jsonEncode({
        "model": "tts-1",
        "input": processedText,
        "voice": voice,
        "speed": options.speed,
        "response_format": "mp3"
      });

      final utf8Bytes = utf8.encode(body);
      request.contentLength = utf8Bytes.length;
      request.add(utf8Bytes);

      final response = await request.close().timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final audioBytes = await response.fold<List<int>>([], (prev, element) => prev..addAll(element));
        return TtsSynthesisResult(
          audioBytes: Uint8List.fromList(audioBytes),
          format: TtsAudioFormat.mp3,
          engineName: name,
        );
      }

      final errorText = await utf8.decoder.bind(response).join();
      throw StateError('Error en OpenAI TTS ($name): $errorText');
    } finally {
      client.close(force: true);
    }
  }
}
