import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:coneccionone/services/tts/tts_engine.dart';

/// Motor ElevenLabs especializado en voces británicas cinematográficas (George / Brian / Daniel)
class ElevenLabsEngine implements TtsEngine {
  static const String _defaultApiKey = String.fromEnvironment('ELEVENLABS_API_KEY', defaultValue: '');

  // ID de voz: 'JBFqnCBsd6RMkjVDRZzb' (George: British, raspy, sophisticated)
  // 'nPczCjzI2devNBz1zQrb' (Brian: Deep, calm, British narrator)
  static const String defaultVoiceId = 'JBFqnCBsd6RMkjVDRZzb';

  @override
  String get name => 'ElevenLabs JARVIS (George - British Tech)';

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
      throw StateError('ElevenLabs API Key no configurada.');
    }

    final processedText = JarvisTextPreprocessor.preprocess(text);
    if (processedText.isEmpty) {
      throw ArgumentError('El texto para reproducir no puede estar vacío.');
    }

    final voiceId = options.voiceId ?? defaultVoiceId;
    final client = HttpClient();

    try {
      final url = Uri.parse('https://api.elevenlabs.io/v1/text-to-speech/$voiceId');
      final request = await client.postUrl(url).timeout(const Duration(seconds: 20));
      request.headers.contentType = ContentType.json;
      request.headers.set('xi-api-key', key);
      request.headers.set('Accept', 'audio/mpeg');

      final body = jsonEncode({
        "text": processedText,
        "model_id": "eleven_multilingual_v2",
        "voice_settings": {
          "stability": 0.65,
          "similarity_boost": 0.85,
          "style": 0.15,
          "use_speaker_boost": true
        }
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
      throw StateError('Error en ElevenLabs ($name): $errorText');
    } finally {
      client.close(force: true);
    }
  }
}
