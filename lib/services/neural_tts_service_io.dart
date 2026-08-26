import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coneccionone/services/tts/elevenlabs_engine.dart';
import 'package:coneccionone/services/tts/gemini_jarvis_engine.dart';
import 'package:coneccionone/services/tts/openai_engine.dart';
import 'package:coneccionone/services/tts/tts_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class NeuralTtsService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final List<TtsEngine> _engines = [
    ElevenLabsEngine(),
    OpenAiEngine(),
    GeminiJarvisEngine(),
  ];

  bool _isPlaying = false;
  String _activeEngineName = 'Gemini DeepMind JARVIS';

  bool get isPlaying => _isPlaying;
  String get activeEngineName => _activeEngineName;
  Stream<PlayerState> get onPlayerStateChanged => _audioPlayer.onPlayerStateChanged;

  NeuralTtsService() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      _isPlaying = state == PlayerState.playing;
    });
  }

  /// Carga la configuración personalizada de voz desde Firestore si existe
  Future<Map<String, dynamic>?> _loadStoredVoiceConfig() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('configuracion').doc('voz_ia').get();
      if (doc.exists) {
        return doc.data();
      }
    } catch (_) {}
    return null;
  }

  /// Sintetiza el audio utilizando el mejor motor disponible con fallback automático ordenado
  Future<TtsSynthesisResult> synthesize({
    required String text,
    TtsOptions? options,
  }) async {
    final cleanText = JarvisTextPreprocessor.preprocess(text);
    if (cleanText.isEmpty) {
      throw ArgumentError('El texto para reproducir no puede estar vacío.');
    }

    final config = await _loadStoredVoiceConfig();
    final preferredEngine = config?['proveedor'] as String? ?? 'elevenlabs';
    
    final customElevenKey = options?.apiKey ?? config?['elevenlabs_key'] as String?;
    final customOpenAiKey = options?.apiKey ?? config?['openai_key'] as String?;
    final customGeminiKey = options?.apiKey ?? config?['gemini_key'] as String?;
    
    final customVoiceId = options?.voiceId ?? config?['voice_id'] as String?;
    final personalityId = options?.personalityId ?? config?['personality_id'] as String?;
    final speed = options?.speed ?? (config?['velocidad'] as num?)?.toDouble() ?? 0.96;

    // Ordenamos la lista de motores según la preferencia real configurada
    List<TtsEngine> enginesToTry = [];
    if (preferredEngine == 'openai') {
      enginesToTry = [OpenAiEngine(), ElevenLabsEngine(), GeminiJarvisEngine()];
    } else if (preferredEngine == 'gemini') {
      enginesToTry = [GeminiJarvisEngine(), ElevenLabsEngine(), OpenAiEngine()];
    } else {
      // Por defecto Jarvis / ElevenLabs al tope
      enginesToTry = [ElevenLabsEngine(), OpenAiEngine(), GeminiJarvisEngine()];
    }

    // Recorremos los motores en orden estricto de prioridad
    for (final engine in enginesToTry) {
      String? key;
      if (engine is ElevenLabsEngine) key = customElevenKey;
      if (engine is OpenAiEngine) key = customOpenAiKey;
      if (engine is GeminiJarvisEngine) key = customGeminiKey;

      if (!engine.isAvailable(apiKey: key)) {
        debugPrint('Motor ${engine.name} omitido: No hay API Key válida disponible.');
        continue;
      }

      try {
        debugPrint('Intentando sintetizar voz con el motor prioritario: ${engine.name}');
        final res = await engine.synthesize(
          text: cleanText,
          options: TtsOptions(
            speed: speed,
            apiKey: key,
            voiceId: customVoiceId ?? (engine is ElevenLabsEngine ? ElevenLabsEngine.defaultVoiceId : null),
            personalityId: personalityId,
          ),
        );
        _activeEngineName = res.engineName;
        debugPrint('¡Éxito absoluto con la voz neural: ${_activeEngineName}!');
        return res;
      } catch (e) {
        debugPrint('FALLÓ el motor ${engine.name}: $e. Probando siguiente alternativa...');
      }
    }

    throw StateError('No se pudo generar voz en ninguno de los motores configurados. Revisa tu conexión a internet o tus API Keys.');
  }

  /// Sintetiza y reproduce con AudioPlayer, deteniendo automáticamente cualquier audio previo
  Future<void> speak(
    String text, {
    TtsOptions? options,
  }) async {
    try {
      await stop();
      final result = await synthesize(
        text: text,
        options: options,
      );

      final tempDir = await getTemporaryDirectory();
      final ext = result.format == TtsAudioFormat.wav ? 'wav' : 'mp3';
      final file = File('${tempDir.path}/jarvis_voice_${DateTime.now().millisecondsSinceEpoch}.$ext');
      await file.writeAsBytes(result.audioBytes, flush: true);

      try {
        await _audioPlayer.play(DeviceFileSource(file.path));
      } catch (e) {
        debugPrint('Fallback de audio en Windows: $e');
        if (Platform.isWindows && result.format == TtsAudioFormat.wav) {
          final escapedPath = file.path.replaceAll("'", "''");
          Process.run('powershell', ['-NoProfile', '-Command', "(New-Object System.Media.SoundPlayer '$escapedPath').Play()"]);
        }
      }
    } catch (e) {
      debugPrint('Error en NeuralTtsService.speak: $e');
      rethrow;
    }
  }

  /// Detiene la reproducción actual inmediatamente
  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
      _isPlaying = false;
      if (Platform.isWindows) {
        Process.run('powershell', ['-NoProfile', '-Command', "(New-Object System.Media.SoundPlayer).Stop()"]);
      }
    } catch (_) {}
  }

  /// Pausa la reproducción
  Future<void> pause() async {
    try {
      await _audioPlayer.pause();
    } catch (_) {}
  }

  /// Reanuda la reproducción
  Future<void> resume() async {
    try {
      await _audioPlayer.resume();
    } catch (_) {}
  }

  /// Libera recursos
  void dispose() {
    _audioPlayer.dispose();
  }
}