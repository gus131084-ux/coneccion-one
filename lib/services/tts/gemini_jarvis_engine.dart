import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:coneccionone/services/tts/tts_engine.dart';

/// Motor de síntesis neuronal Google DeepMind con voces masculinas tecnológicas (Fenrir / Charon)
class GeminiJarvisEngine implements TtsEngine {
  static const String _defaultApiKey = String.fromEnvironment(
    'AI_API_KEY',
    defaultValue: 'AQ.Ab8RN6KOFMSpOT54iAqBTKmKECokexVl2EBNU37x76kchyfkyA',
  );

  @override
  String get name => 'Gemini DeepMind JARVIS (Fenrir)';

  @override
  bool isAvailable({String? apiKey}) {
    final key = apiKey?.trim().isNotEmpty == true ? apiKey! : _defaultApiKey;
    return key.isNotEmpty;
  }

  Uint8List _pcmToWav(Uint8List pcmData, {int sampleRate = 24000, int channels = 1, int bitsPerSample = 16}) {
    final byteRate = sampleRate * channels * (bitsPerSample ~/ 8);
    final blockAlign = channels * (bitsPerSample ~/ 8);
    final totalDataLen = pcmData.length;
    final totalAudioLen = totalDataLen + 36;

    final header = ByteData(44);
    header.setUint8(0, 0x52); // R
    header.setUint8(1, 0x49); // I
    header.setUint8(2, 0x46); // F
    header.setUint8(3, 0x46); // F
    header.setUint32(4, totalAudioLen, Endian.little);
    header.setUint8(8, 0x57);  // W
    header.setUint8(9, 0x41);  // A
    header.setUint8(10, 0x56); // V
    header.setUint8(11, 0x45); // E

    header.setUint8(12, 0x66); // f
    header.setUint8(13, 0x6D); // m
    header.setUint8(14, 0x74); // t
    header.setUint8(15, 0x20); // ' '
    header.setUint32(16, 16, Endian.little);
    header.setUint16(20, 1, Endian.little); // PCM
    header.setUint16(22, channels, Endian.little);
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, byteRate, Endian.little);
    header.setUint16(32, blockAlign, Endian.little);
    header.setUint16(34, bitsPerSample, Endian.little);

    header.setUint8(36, 0x64); // d
    header.setUint8(37, 0x61); // a
    header.setUint8(38, 0x74); // t
    header.setUint8(39, 0x61); // a
    header.setUint32(40, totalDataLen, Endian.little);

    final builder = BytesBuilder();
    builder.add(header.buffer.asUint8List());
    builder.add(pcmData);
    return builder.toBytes();
  }

  @override
  Future<TtsSynthesisResult> synthesize({
    required String text,
    TtsOptions options = const TtsOptions(),
  }) async {
    final key = options.apiKey?.trim().isNotEmpty == true ? options.apiKey! : _defaultApiKey;
    final processedText = JarvisTextPreprocessor.preprocess(text);
    if (processedText.isEmpty) {
      throw ArgumentError('El texto para reproducir no puede estar vacío.');
    }

    final contextPrompt = JarvisTextPreprocessor.getContextPrompt(processedText, personalityId: options.personalityId);
    final rawVoice = options.voiceId ?? 'Fenrir';
    final voiceProfile = AiVoiceCatalog.getVoiceById(rawVoice);
    final voice = voiceProfile.id;

    final ttsModels = [
      'gemini-2.5-flash-preview-tts',
      'gemini-3.1-flash-tts-preview',
      'gemini-2.5-pro-preview-tts',
    ];

    final client = HttpClient();
    try {
      final body = jsonEncode({
        "contents": [
          {
            "parts": [
              {"text": "$contextPrompt: $processedText"}
            ]
          }
        ],
        "generationConfig": {
          "responseModalities": ["AUDIO"],
          "speechConfig": {
            "voiceConfig": {
              "prebuiltVoiceConfig": {
                "voiceName": voice,
              }
            }
          }
        }
      });
      final utf8Bytes = utf8.encode(body);

      Object? lastError;
      for (final model in ttsModels) {
        try {
          final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$key');
          final request = await client.postUrl(url).timeout(const Duration(seconds: 20));
          request.headers.contentType = ContentType.json;
          request.contentLength = utf8Bytes.length;
          request.add(utf8Bytes);

          final response = await request.close().timeout(const Duration(seconds: 20));
          final responseText = await utf8.decoder.bind(response).join();

          if (response.statusCode >= 200 && response.statusCode < 300) {
            final json = jsonDecode(responseText);
            final candidates = json['candidates'] as List?;
            final parts = candidates?[0]?['content']?['parts'] as List?;
            for (final p in parts ?? []) {
              if (p['inlineData'] != null) {
                final pcmBytes = base64Decode(p['inlineData']['data'] as String);
                final wavBytes = _pcmToWav(pcmBytes, sampleRate: 24000);
                return TtsSynthesisResult(
                  audioBytes: wavBytes,
                  format: TtsAudioFormat.wav,
                  engineName: name,
                );
              }
            }
          } else {
            lastError = 'Status ${response.statusCode}: $responseText';
          }
        } catch (e) {
          lastError = e;
        }
      }

      throw StateError('Error en Gemini TTS ($name): $lastError');
    } finally {
      client.close(force: true);
    }
  }
}
