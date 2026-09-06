import 'dart:io';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';

class NativeTtsHandler {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;

  static final NativeTtsHandler _instance = NativeTtsHandler._internal();
  factory NativeTtsHandler() => _instance;
  NativeTtsHandler._internal();

  Future<void> _init() async {
    if (_isInitialized) return;

    try {
      // Configuración inicial base
      await _flutterTts.setSharedInstance(true);
      
      if (Platform.isIOS || Platform.isAndroid) {
        await _flutterTts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.playback,
          [
            IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
            IosTextToSpeechAudioCategoryOptions.allowBluetooth,
            IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
          ],
        );
      }

      await _configureStrictLatinVoice();
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error inicializando NativeTtsHandler: $e');
    }
  }

  /// Configura forzosamente una voz en español latino de alta calidad
  Future<void> _configureStrictLatinVoice() async {
    try {
      // 1. Obtener todas las voces disponibles
      List<dynamic>? voices = await _flutterTts.getVoices;
      if (voices == null || voices.isEmpty) {
        await _flutterTts.setLanguage("es-MX");
        return;
      }

      // Excluyendo terminantemente es-ES (España) y variantes europeas
      var latinVoices = voices.where((voice) {
        final String name = (voice['name'] ?? '').toString().toLowerCase();
        final String locale = (voice['locale'] ?? '').toString().toLowerCase();
        
        // Bloqueo total de España y variantes de Castilla
        if (locale.contains('es-es') || 
            name.contains('spain') || 
            name.contains('españa') ||
            name.contains('castellano')) {
          return false;
        }

        // Solo permitir español
        return locale.startsWith('es');
      }).toList();

      if (latinVoices.isEmpty) {
        debugPrint('Advertencia: No se encontraron voces latinas específicas. Usando es-MX.');
        await _flutterTts.setLanguage("es-MX");
        return;
      }

      // 3. Filtrar por calidad: Priorizar "neural", "natural", "premium", "enhanced"
      var qualityVoices = latinVoices.where((voice) {
        final String name = voice['name']?.toString().toLowerCase() ?? '';
        return name.contains('neural') || 
               name.contains('natural') || 
               name.contains('premium') || 
               name.contains('enhanced') ||
               name.contains('high_quality');
      }).toList();

      var candidates = qualityVoices.isNotEmpty ? qualityVoices : latinVoices;

      // 4. Intentar seleccionar una voz masculina para JARVIS
      var maleVoices = candidates.where((voice) {
        final String name = voice['name']?.toString().toLowerCase() ?? '';
        return name.contains('male') || name.contains('hombre') || 
               name.contains('jorge') || name.contains('raul') || 
               name.contains('pablo') || name.contains('diego');
      }).toList();

      var voiceToSet = maleVoices.isNotEmpty ? maleVoices.first : candidates.first;

      await _flutterTts.setVoice({
        "name": voiceToSet["name"],
        "locale": voiceToSet["locale"]
      });

      // Asegurar el lenguaje por si acaso
      await _flutterTts.setLanguage(voiceToSet["locale"]);

      debugPrint('Voz LATINA NATIVA configurada: ${voiceToSet["name"]} (${voiceToSet["locale"]})');

    } catch (e) {
      debugPrint('Error configurando voz latina: $e');
      await _flutterTts.setLanguage("es-MX");
    }
  }

  Future<void> speak(String text, {double speed = 0.5}) async {
    await _init();
    try {
      // Ajuste de velocidad (flutter_tts usa de 0.0 a 1.0)
      // El 0.5 suele ser el estándar normal
      await _flutterTts.setSpeechRate(speed);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('Error en speak nativo: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      debugPrint('Error deteniendo voz nativa: $e');
    }
  }
}
