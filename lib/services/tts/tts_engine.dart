import 'dart:typed_data';

/// Perfil de voz disponible en la aplicación (Siempre en Español Latino)
class AiVoiceProfile {
  final String id;
  final String name;
  final String gender; // 'Masculina' | 'Femenina'
  final String description;
  final String samplePhrase;
  final String provider; // 'gemini' | 'elevenlabs' | 'openai'

  const AiVoiceProfile({
    required this.id,
    required this.name,
    required this.gender,
    required this.description,
    required this.samplePhrase,
    this.provider = 'gemini',
  });
}

/// Personalidad y comportamiento de la IA (Siempre en Español Latino)
class AiPersonality {
  final String id;
  final String name;
  final String icon;
  final String description;
  final String systemPromptModifier;
  final String actingCue;

  const AiPersonality({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
    required this.systemPromptModifier,
    required this.actingCue,
  });
}

/// Catálogo centralizado de voces y personalidades de la IA
class AiVoiceCatalog {
  /// Lista de voces disponibles (100% compatibles con Español Latino)
  static const List<AiVoiceProfile> voices = [
    AiVoiceProfile(
      id: 'Fenrir',
      name: 'Fenrir (JARVIS Clásico)',
      gender: 'Masculina',
      description: 'Voz masculina profunda, tecnológica, sobria y calmada.',
      samplePhrase: 'Sistemas en línea. A su disposición para gestionar el taller con máxima precisión.',
      provider: 'gemini',
    ),
    AiVoiceProfile(
      id: 'Charon',
      name: 'Charon (JARVIS Ejecutivo)',
      gender: 'Masculina',
      description: 'Voz masculina grave, autoritaria, formal y pausada.',
      samplePhrase: 'Informe financiero y estado de reparaciones listos para su revisión.',
      provider: 'gemini',
    ),
    AiVoiceProfile(
      id: 'Puck',
      name: 'Puck (Asistente Dinámico)',
      gender: 'Masculina',
      description: 'Voz masculina joven, ágil, entusiasta y enérgica.',
      samplePhrase: '¡Todo listo! Revisemos los equipos pendientes y el inventario del día.',
      provider: 'gemini',
    ),
    AiVoiceProfile(
      id: 'Aoede',
      name: 'Aoede (FRIDAY Tecnológica)',
      gender: 'Femenina',
      description: 'Voz femenina sofisticada, clara, calmada y futurista.',
      samplePhrase: 'Base de datos sincronizada. Diagnóstico y métricas actualizadas en tiempo real.',
      provider: 'gemini',
    ),
    AiVoiceProfile(
      id: 'Kore',
      name: 'Kore (Asistente Ejecutiva)',
      gender: 'Femenina',
      description: 'Voz femenina cálida, cordial, profesional y fluida.',
      samplePhrase: 'Bienvenido. Con gusto le ayudo con los clientes y las órdenes de trabajo.',
      provider: 'gemini',
    ),
  ];

  /// Lista de personalidades configurables
  static const List<AiPersonality> personalities = [
    AiPersonality(
      id: 'jarvis_clasico',
      name: 'JARVIS Clásico',
      icon: '🤖',
      description: 'Tecnológico, sumamente formal, respetuoso, calmado y elegante.',
      systemPromptModifier: 'Actúa con la personalidad de JARVIS: un asistente de inteligencia artificial de alta tecnología, extremadamente educado, formal, calmado y distinguido. Trata al usuario con máximo respeto en español latino.',
      actingCue: 'Habla en español latinoamericano neutro con tono profundo, tecnológico, sumamente calmado, educado y elegante, estilo JARVIS. Sin acento de España.',
    ),
    AiPersonality(
      id: 'ejecutivo_conciso',
      name: 'Ejecutivo Conciso',
      icon: '⚡',
      description: 'Ultra rápido, va directo al grano con números, finanzas y resultados sin rodeos.',
      systemPromptModifier: 'Actúa como un Asistente Ejecutivo de alto rendimiento: sé sumamente conciso, directo al grano y enfocado en datos, números, dinero y estados de equipos. Cero rodeos, respuestas breves y directas.',
      actingCue: 'Habla en español latino neutro con ritmo ágil, firme, directo, conciso y ejecutivo. Sin modismos de España.',
    ),
    AiPersonality(
      id: 'amable_cercano',
      name: 'Amable y Cercano',
      icon: '🤝',
      description: 'Cálido, simpático, motivador, empático y servicial con el taller.',
      systemPromptModifier: 'Actúa como un Asistente Cálido y Cordial: sé muy amable, entusiasta, cercano y colaborativo en español latino amigable, motivando al equipo del taller.',
      actingCue: 'Habla en español latino neutro con tono cálido, amable, sonriente, empático y servicial. Sin modismos de España.',
    ),
    AiPersonality(
      id: 'supervisor_tecnico',
      name: 'Supervisor Técnico',
      icon: '🛡️',
      description: 'Analítico, riguroso, minucioso y enfocado en fallas, repuestos y alertas.',
      systemPromptModifier: 'Actúa como un Supervisor Técnico Experto: analiza meticulosamente cada falla técnica, repuesto, presupuesto y retraso de equipo. Sé riguroso y analítico en tus explicaciones.',
      actingCue: 'Habla en español latino neutro con tono serio, analítico, profesional y técnico, enfocado en el diagnóstico y la precisión. Sin acento de España.',
    ),
    AiPersonality(
      id: 'tecno_futurista',
      name: 'Tecno-Futurista',
      icon: '🚀',
      description: 'Estilo centro de comando IA de última generación, eficiente y analítico.',
      systemPromptModifier: 'Actúa como una Inteligencia Artificial Futurista de Centro de Operaciones: responde con estilo de interfaz cibernética de alta tecnología, precisión de telemetría y datos en tiempo real.',
      actingCue: 'Habla en español latinoamericano neutro con tono futurista, analítico, seguro y tecnológico de centro de control. Sin acento de España.',
    ),
  ];

  static AiVoiceProfile getVoiceById(String? id) {
    return voices.firstWhere(
      (v) => v.id.toLowerCase() == (id ?? '').toLowerCase(),
      orElse: () => voices.first,
    );
  }

  static AiPersonality getPersonalityById(String? id) {
    return personalities.firstWhere(
      (p) => p.id.toLowerCase() == (id ?? '').toLowerCase(),
      orElse: () => personalities.first,
    );
  }
}

/// Opciones de configuración de síntesis de voz
class TtsOptions {
  final double speed; // 0.5 a 2.0 (por defecto 0.95 para cadencia JARVIS)
  final double pitch; // -20.0 a 20.0 (por defecto 0.0)
  final double volume; // 0.0 a 1.0 (por defecto 1.0)
  final String? voiceId; // ID de voz específico del proveedor
  final String? personalityId; // ID de personalidad
  final String? apiKey; // Clave API personalizada opcional

  const TtsOptions({
    this.speed = 0.95,
    this.pitch = 0.0,
    this.volume = 1.0,
    this.voiceId,
    this.personalityId,
    this.apiKey,
  });
}

/// Formato del audio retornado por el motor
enum TtsAudioFormat {
  mp3,
  wav,
}

/// Resultado de la síntesis
class TtsSynthesisResult {
  final Uint8List audioBytes;
  final TtsAudioFormat format;
  final String engineName;

  const TtsSynthesisResult({
    required this.audioBytes,
    required this.format,
    required this.engineName,
  });
}

/// Contrato abstracto para cualquier motor de Text-to-Speech
abstract class TtsEngine {
  String get name;
  bool isAvailable({String? apiKey});
  Future<TtsSynthesisResult> synthesize({
    required String text,
    TtsOptions options = const TtsOptions(),
  });
}

/// Procesador de texto para dar entonación y pausas naturales estilo JARVIS en Español Latino
class JarvisTextPreprocessor {
  /// Limpia y formatea el texto para que la voz fluya con pronunciación latina y pausas naturales
  static String preprocess(String text) {
    var cleaned = text
        // Eliminar formato Markdown
        .replaceAll(RegExp(r'[*_#`~]'), '')
        .replaceAllMapped(RegExp(r'\[(.*?)\]\(.*?\)'), (m) => m[1] ?? '')
        // Normalizar saltos de línea a pausas naturales
        .replaceAll(RegExp(r'\n+'), '. ')
        // Expandir abreviaturas comunes para mejor pronunciación
        .replaceAll(RegExp(r'\bDr\b\.?', caseSensitive: false), 'Doctor')
        .replaceAll(RegExp(r'\bSr\b\.?', caseSensitive: false), 'Señor')
        .replaceAll(RegExp(r'\bSra\b\.?', caseSensitive: false), 'Señora')
        .replaceAll(RegExp(r'\bTel\b\.?', caseSensitive: false), 'Teléfono')
        .replaceAll(RegExp(r'\bNo\b\.?', caseSensitive: false), 'Número')
        .replaceAll(RegExp(r'\bvs\b\.?', caseSensitive: false), 'contra')
        .replaceAllMapped(RegExp(r'\$([0-9]+)'), (m) => '${m[1]} pesos')
        // Eliminar modismos de España y sustituir por español latino
        .replaceAll(RegExp(r'\bvosotros\b', caseSensitive: false), 'ustedes')
        .replaceAll(RegExp(r'\bos\b', caseSensitive: false), 'les')
        // Eliminar espacios dobles o puntos consecutivos
        .replaceAll(RegExp(r'\.{2,}'), '.')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    return cleaned;
  }

  /// Detecta si el texto es una advertencia, reporte financiero o respuesta según la personalidad elegida
  static String getContextPrompt(String text, {String? personalityId}) {
    final personality = AiVoiceCatalog.getPersonalityById(personalityId);
    final lower = text.toLowerCase();

    if (lower.contains('advertencia') ||
        lower.contains('alerta') ||
        lower.contains('urgente') ||
        lower.contains('atención') ||
        lower.contains('peligro') ||
        lower.contains('deuda') ||
        lower.contains('pendiente hace')) {
      return '${personality.actingCue} Con énfasis de advertencia profesional.';
    } else if (lower.contains('ganancia') ||
        lower.contains('total') ||
        lower.contains('recaudación') ||
        lower.contains('balance') ||
        lower.contains('reporte')) {
      return '${personality.actingCue} Presentando un informe comercial y financiero.';
    } else {
      return personality.actingCue;
    }
  }
}
