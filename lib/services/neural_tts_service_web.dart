import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coneccionone/services/tts/tts_engine.dart';
import 'package:flutter/foundation.dart';

class NeuralTtsService {
  static const _defaultGeminiKey = String.fromEnvironment(
    'AI_API_KEY',
    defaultValue: 'AQ.Ab8RN6KOFMSpOT54iAqBTKmKECokexVl2EBNU37x76kchyfkyA',
  );

  final StreamController<PlayerState> _stateController = StreamController<PlayerState>.broadcast();
  html.AudioElement? _currentAudio;
  bool _isPlaying = false;
  String _activeEngineName = 'JARVIS Latino (Web)';

  bool get isPlaying => _isPlaying;
  String get activeEngineName => _activeEngineName;
  Stream<PlayerState> get onPlayerStateChanged => _stateController.stream;

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

  Future<Map<String, dynamic>?> _loadStoredVoiceConfig() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('configuracion').doc('voz_ia').get();
      if (doc.exists) {
        return doc.data();
      }
    } catch (_) {}
    return null;
  }

  Future<List<html.SpeechSynthesisVoice>> _getBrowserVoices() async {
    final synth = html.window.speechSynthesis;
    if (synth == null) return [];
    final initial = synth.getVoices();
    if (initial.isNotEmpty) {
      return List<html.SpeechSynthesisVoice>.from(initial);
    }

    final completer = Completer<List<html.SpeechSynthesisVoice>>();
    html.EventListener? listener;
    listener = (_) {
      final v = synth.getVoices();
      if (v.isNotEmpty && !completer.isCompleted) {
        completer.complete(List<html.SpeechSynthesisVoice>.from(v));
      }
    };
    synth.addEventListener('voiceschanged', listener);

    Future.delayed(const Duration(milliseconds: 500), () {
      if (!completer.isCompleted) {
        completer.complete(List<html.SpeechSynthesisVoice>.from(synth.getVoices()));
      }
    });

    final result = await completer.future;
    try {
      synth.removeEventListener('voiceschanged', listener);
    } catch (_) {}
    return result;
  }

  ({html.SpeechSynthesisVoice? voice, bool isConfirmedMale}) _selectBestVoice(
    List<html.SpeechSynthesisVoice> voices, {
    required bool wantMale,
  }) {
    final maleKeywords = [
      'raul', 'raúl', 'jorge', 'diego', 'alonso', 'carlos', 'miguel', 'sabino',
      'gonzalo', 'gerardo', 'esteban', 'mateo', 'julio', 'andres', 'andrés',
      'enrique', 'pablo', 'alvaro', 'álvaro', 'david', 'male', 'hombre', 'masculino', 'jarvis',
    ];

    final femaleKeywords = [
      'google español', 'google spanish', 'sabina', 'helena', 'elena', 'laura',
      'monica', 'mónica', 'lucia', 'lucía', 'hilda', 'paulina', 'rosa', 'lourdes',
      'dalia', 'soledad', 'francisca', 'camila', 'sofia', 'sofía', 'victoria',
      'mia', 'mía', 'lupe', 'juana', 'maria', 'maría', 'carmen', 'esperanza',
      'paloma', 'penelope', 'penélope', 'marta', 'conchita', 'concha', 'alva',
      'zira', 'hazel', 'susan', 'cortana', 'siri', 'female', 'mujer', 'femenina',
    ];

    if (wantMale) {
      for (final v in voices) {
        final lang = (v.lang ?? '').toLowerCase();
        final name = (v.name ?? '').toLowerCase();
        if (femaleKeywords.any((k) => name.contains(k))) continue;

        if (lang.contains('mx') || lang.contains('us') || lang.contains('ar') ||
            lang.contains('co') || lang.contains('cl') || lang.contains('419') ||
            name.contains('mexico') || name.contains('latin') || name.contains('argentina')) {
          if (maleKeywords.any((k) => name.contains(k))) {
            return (voice: v, isConfirmedMale: true);
          }
        }
      }

      for (final v in voices) {
        final lang = (v.lang ?? '').toLowerCase();
        final name = (v.name ?? '').toLowerCase();
        if (femaleKeywords.any((k) => name.contains(k))) continue;

        if (lang.startsWith('es') && maleKeywords.any((k) => name.contains(k))) {
          return (voice: v, isConfirmedMale: true);
        }
      }

      for (final v in voices) {
        final lang = (v.lang ?? '').toLowerCase();
        final name = (v.name ?? '').toLowerCase();
        if (name.contains('google')) continue;

        if (lang.startsWith('es') && (v.localService == true || name.contains('desktop') || name.contains('microsoft'))) {
          return (voice: v, isConfirmedMale: false);
        }
      }

      for (final v in voices) {
        final lang = (v.lang ?? '').toLowerCase();
        final name = (v.name ?? '').toLowerCase();
        if (lang.startsWith('es') && !lang.contains('es-es') && !name.contains('spain')) {
          return (voice: v, isConfirmedMale: false);
        }
      }

      for (final v in voices) {
        if ((v.lang ?? '').toLowerCase().startsWith('es')) {
          return (voice: v, isConfirmedMale: false);
        }
      }

      return (voice: null, isConfirmedMale: false);
    } else {
      for (final v in voices) {
        final lang = (v.lang ?? '').toLowerCase();
        final name = (v.name ?? '').toLowerCase();
        if (lang.startsWith('es') && femaleKeywords.any((k) => name.contains(k))) {
          return (voice: v, isConfirmedMale: false);
        }
      }
      for (final v in voices) {
        if ((v.lang ?? '').toLowerCase().startsWith('es')) {
          return (voice: v, isConfirmedMale: false);
        }
      }
      return (voice: null, isConfirmedMale: false);
    }
  }

  Future<TtsSynthesisResult> synthesize({
    required String text,
    TtsOptions? options,
  }) async {
    final cleanText = JarvisTextPreprocessor.preprocess(text);
    if (cleanText.isEmpty) {
      throw ArgumentError('El texto para reproducir no puede estar vacío.');
    }

    final config = await _loadStoredVoiceConfig();
    final customGeminiKey = options?.apiKey ?? config?['gemini_key'] as String?;
    final rawVoiceId = options?.voiceId ?? config?['voice_id'] as String? ?? 'Fenrir';
    final voiceProfile = AiVoiceCatalog.getVoiceById(rawVoiceId);
    final voiceId = voiceProfile.id;

    final contextPrompt = JarvisTextPreprocessor.getContextPrompt(cleanText, personalityId: options?.personalityId);
    final body = jsonEncode({
      "contents": [
        {
          "parts": [
            {"text": "$contextPrompt: $cleanText"}
          ]
        }
      ],
      "generationConfig": {
        "responseModalities": ["AUDIO"],
        "speechConfig": {
          "voiceConfig": {
            "prebuiltVoiceConfig": {
              "voiceName": voiceId,
            }
          }
        }
      }
    });

    final activeKey = (customGeminiKey != null && customGeminiKey.trim().isNotEmpty)
        ? customGeminiKey.trim()
        : _defaultGeminiKey;

    final ttsModels = [
      'gemini-2.5-flash-preview-tts',
      'gemini-3.1-flash-tts-preview',
      'gemini-2.5-pro-preview-tts',
    ];

    for (final model in ttsModels) {
      try {
        final completer = Completer<TtsSynthesisResult?>();
        final xhr = html.HttpRequest();
        xhr.open('POST', 'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$activeKey');
        xhr.setRequestHeader('Content-Type', 'application/json');
        
        xhr.onLoad.listen((_) {
          if (xhr.status == 200) {
            try {
              final json = jsonDecode(xhr.responseText ?? '{}');
              final candidates = json is Map ? json['candidates'] as List? : null;
              final parts = candidates?[0]?['content']?['parts'] as List?;
              for (final p in parts ?? []) {
                if (p['inlineData'] != null) {
                  final pcmBytes = base64Decode(p['inlineData']['data'] as String);
                  final wavBytes = _pcmToWav(pcmBytes, sampleRate: 24000);
                  _activeEngineName = 'Gemini DeepMind JARVIS Latino ($voiceId)';
                  if (!completer.isCompleted) {
                    completer.complete(TtsSynthesisResult(
                      audioBytes: wavBytes,
                      format: TtsAudioFormat.wav,
                      engineName: _activeEngineName,
                    ));
                  }
                  return;
                }
              }
            } catch (_) {}
          }
          if (!completer.isCompleted) completer.complete(null);
        });

        xhr.onError.listen((_) {
          if (!completer.isCompleted) completer.complete(null);
        });

        xhr.send(body);

        final result = await completer.future.timeout(const Duration(seconds: 6), onTimeout: () => null);
        if (result != null) return result;
      } catch (e) {
        debugPrint('Modelo TTS $model omitido por bloqueo de red/CORS.');
      }
    }

    throw StateError('Error al sintetizar voz JARVIS en web (CORS o modelos no alcanzables)');
  }

  Future<void> speak(
    String text, {
    TtsOptions? options,
  }) async {
    final cleanText = JarvisTextPreprocessor.preprocess(text);
    if (cleanText.isEmpty) return;

    await stop();
    _isPlaying = true;
    _stateController.add(PlayerState.playing);

    try {
      final res = await synthesize(text: cleanText, options: options);
      final mimeType = res.format == TtsAudioFormat.wav ? 'audio/wav' : 'audio/mpeg';
      final blob = html.Blob([res.audioBytes], mimeType);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final audio = html.AudioElement(url);
      _currentAudio = audio;

      audio.onEnded.listen((_) {
        _isPlaying = false;
        _stateController.add(PlayerState.completed);
        html.Url.revokeObjectUrl(url);
      });

      audio.onError.listen((_) {
        _isPlaying = false;
        _stateController.add(PlayerState.stopped);
        html.Url.revokeObjectUrl(url);
      });

      await audio.play();
    } catch (e) {
      debugPrint('Modo alternativo web activado debido a restricciones de red.');
      final synth = html.window.speechSynthesis;
      if (synth != null) {
        final config = await _loadStoredVoiceConfig();
        final voiceId = options?.voiceId ?? config?['voice_id'] as String? ?? 'Fenrir';
        final profile = AiVoiceCatalog.getVoiceById(voiceId);
        final wantMale = profile.gender == 'Masculina';

        final voices = await _getBrowserVoices();
        final voiceResult = _selectBestVoice(voices, wantMale: wantMale);

        final sentences = cleanText.split(RegExp(r'(?<=[.?!])\s+'));
        var index = 0;

        void speakNext() {
          if (!_isPlaying || index >= sentences.length) {
            _isPlaying = false;
            _stateController.add(PlayerState.completed);
            return;
          }

          final s = sentences[index++].trim();
          if (s.isEmpty) {
            speakNext();
            return;
          }

          final utterance = html.SpeechSynthesisUtterance(s);
          utterance.lang = 'es-419';

          if (wantMale) {
            if (voiceResult.isConfirmedMale) {
              utterance.pitch = 0.74;
              utterance.rate = options?.speed ?? 0.94;
            } else {
              utterance.pitch = 0.48;
              utterance.rate = (options?.speed ?? 0.94) * 0.92;
            }
          } else {
            utterance.pitch = 1.05;
            utterance.rate = options?.speed ?? 1.0;
          }

          if (voiceResult.voice != null) {
            utterance.voice = voiceResult.voice;
          }

          utterance.onEnd.listen((_) => speakNext());
          utterance.onError.listen((_) => speakNext());

          synth.speak(utterance);
        }

        speakNext();
      } else {
        _isPlaying = false;
        _stateController.add(PlayerState.stopped);
      }
    }
  }

  Future<void> stop() async {
    _isPlaying = false;
    _stateController.add(PlayerState.stopped);
    try {
      _currentAudio?.pause();
      _currentAudio = null;
      html.window.speechSynthesis?.cancel();
    } catch (_) {}
  }

  Future<void> pause() async {
    try {
      _currentAudio?.pause();
      _isPlaying = false;
      _stateController.add(PlayerState.paused);
    } catch (_) {}
  }

  Future<void> resume() async {
    try {
      _currentAudio?.play();
      _isPlaying = true;
      _stateController.add(PlayerState.playing);
    } catch (_) {}
  }

  void dispose() {
    stop();
    _stateController.close();
  }
}