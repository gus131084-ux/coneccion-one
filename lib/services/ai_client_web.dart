import 'dart:async';
import 'dart:convert';
import 'dart:html';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coneccionone/services/tts/tts_engine.dart';

class AiClient {
  static const _models = [
    'gemini-3.5-flash-lite',
    'gemini-3.6-flash',
    'gemini-3.5-flash',
  ];
  
  static const _key = String.fromEnvironment(
    'AI_API_KEY', 
    defaultValue: '',
  );

  /// Carga la configuración guardada en Firestore
  Future<Map<String, dynamic>?> _loadConfig() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('configuracion')
          .doc('voz_ia')
          .get();
      return doc.data();
    } catch (_) {
      return null;
    }
  }

  String _localDataAnalysis(String question, Map<String, dynamic> data) {
    final q = question.toLowerCase();
    
    if (q.contains('cliente') || q.contains('persona') || q.contains('nombre')) {
      final clientes = data['clientes'] as List? ?? [];
      if (clientes.isEmpty) return "No tengo clientes registrados en la base de datos local todavía.";
      
      // Búsqueda simple por nombre
      for (var c in clientes) {
        final nombre = (c['nombre'] ?? '').toString().toLowerCase();
        if (q.contains(nombre)) {
          return "He encontrado al cliente ${c['nombre']}. Su teléfono es ${c['telefono'] ?? 'no registrado'}.";
        }
      }
      return "He analizado mis datos y encontré ${clientes.length} clientes, pero ninguno coincide exactamente con su consulta. Por favor, configure su llave de Gemini para un análisis más profundo.";
    }

    if (q.contains('reparaci') || q.contains('equipo') || q.contains('celular')) {
      final reps = data['reparaciones'] as List? ?? [];
      final pendientes = reps.where((r) => r['estado'] != 'Entregado').length;
      return "Actualmente hay ${reps.length} reparaciones en total, de las cuales $pendientes están pendientes. Configure su API Key para ver detalles específicos de cada equipo.";
    }

    if (q.contains('ventas') || q.contains('ganancia') || q.contains('dinero') || q.contains('finanzas')) {
      final ventas = (data['estadisticas']?['ventas_mes'] ?? 0).toString();
      return "El resumen financiero muestra ventas por $ventas pesos este mes. Para un desglose detallado, por favor ingrese su API Key en Configuración.";
    }

    return "Lo siento, para responder consultas complejas necesito que configure su API Key de Gemini en la sección de Configuración. Sin embargo, puedo confirmarle que tengo acceso a sus datos locales.";
  }

  Future<String> ask({
    required String question,
    required Map<String, dynamic> dashboard,
  }) async {
    // Cargar configuración
    final config = await _loadConfig();
    final customGeminiKey = config?['gemini_key'] as String?;
    final activeKey = (customGeminiKey != null && customGeminiKey.trim().isNotEmpty) 
        ? customGeminiKey.trim() 
        : _key;

    if (activeKey.isEmpty) {
      // MODO FALLBACK LOCAL: Si no hay llave, intentamos responder con datos básicos
      return _localDataAnalysis(question, dashboard);
    }
    
    final negocio = dashboard['negocio'] as Map<String, dynamic>? ?? {};
    final nombreNegocio = negocio['nombre_negocio'] ?? 'Conección One';
    final nombreAdmin = negocio['administrador'] ?? 'Admin';

    final personalityId = config?['personality_id'] as String?;
    final personality = AiVoiceCatalog.getPersonalityById(personalityId ?? 'jarvis_clasico');

    final prompt = '''
Eres el Asistente de Inteligencia Artificial integrado del sistema de gestión para el taller de servicio técnico "$nombreNegocio" (administrado por "$nombreAdmin").

Tienes acceso COMPLETO, TOTAL y EN TIEMPO REAL a toda la base de datos del negocio:
- Lista completa de Clientes (nombres, teléfonos, correos, direcciones, DNI, notas, fechas de registro)
- Lista completa de Reparaciones (equipos, marcas, modelos, fallas reportadas, estados [Pendiente, En proceso, Terminado, Entregado], presupuestos, señas/entregas, saldos pendientes, IMEI, observaciones, seguridad patrón/PIN, fechas de ingreso)
- Lista completa de Inventario y Repuestos (productos, stock disponible, precios, alertas de bajo stock)
- Lista completa de Facturas y Ventas (números de factura, clientes, equipos, fallas, reparaciones, totales, deudas/saldos restantes, métodos de pago, estados de pago, fechas)
- Resumen estadístico y financiero actualizado (ventas del mes, gastos, ganancias netas, fallas más frecuentes, clientes con saldo pendiente)

BASE DE DATOS COMPLETA DEL SISTEMA:
${jsonEncode(dashboard)}

INSTRUCCIONES CLAVE DE RESPUESTA:
1. Visibilidad y Búsqueda Total:
   - Si el usuario te pregunta por un cliente (por ejemplo "¿Existe algún cliente con el nombre Elena?", "Busca a Juan", "¿Qué teléfono tiene Pedro?"), busca de forma inteligente en la lista de clientes, reparaciones y facturas (insensible a mayúsculas/minúsculas y coincidencia parcial).
   - Si existe, responde afirmativamente y entrega de forma clara y ordenada sus datos (nombre completo, teléfono, si tiene equipos en reparación, sus estados, y si tiene facturas o deudas pendientes).
   - Si NO existe ningún cliente con ese nombre o coincidencia, responde con amabilidad y precisión indicando que no se encontró ningún cliente con ese nombre registrado en la base de datos.

2. Consultas sobre Reparaciones y Equipos:
   - Responde con exactitud sobre equipos pendientes, en proceso, terminados o entregados, marcas, modelos, fallas, fechas o presupuestos.

3. Consultas sobre Inventario y Repuestos:
   - Responde sobre la disponibilidad, stock y precio de cualquier repuesto o producto, o qué productos tienen poco stock.

4. Consultas sobre Finanzas, Facturación y Deudas:
   - Responde sobre ventas del mes, gastos, ganancias, historial de facturación o qué clientes tienen saldo adeudado.

5. Tono y Formato:
   - ${personality.systemPromptModifier}
   - Utiliza viñetas o formato estructurado cuando listes elementos para que sea fácil de leer en la pantalla.
   - Sé conciso y directo a lo que el usuario preguntó, sin rodeos innecesarios.

PREGUNTA DEL DUEÑO O USUARIO:
"$question"
''';

    final bodyData = jsonEncode({
      "contents": [
        {
          "role": "user",
          "parts": [
            {"text": prompt}
          ]
        }
      ],
      "generationConfig": {
        "temperature": 0.2,
        "maxOutputTokens": 1024,
      }
    });

    Object? lastError;

    for (final model in _models) {
      try {
        final request = await HttpRequest.request(
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$activeKey',
          method: 'POST',
          requestHeaders: {'Content-Type': 'application/json'},
          sendData: bodyData,
        ).timeout(const Duration(seconds: 20));

        final status = request.status ?? 0;
        if (status >= 200 && status < 300) {
          final body = jsonDecode(request.responseText ?? '{}');
          final candidates = body is Map ? body['candidates'] as List? : null;
          if (candidates != null && candidates.isNotEmpty) {
            final textResponse = candidates[0]['content']?['parts']?[0]?['text'];
            if (textResponse != null && textResponse.toString().trim().isNotEmpty) {
              return textResponse.toString().trim();
            }
          }
        } else {
          lastError = 'Error de Gemini ($model: $status)';
        }
      } on TimeoutException {
        lastError = 'Tiempo de espera agotado al conectar con la IA.';
      } catch (e) {
        lastError = e;
      }
    }

    throw StateError(lastError?.toString() ?? 'No se pudo obtener respuesta del servidor de IA.');
  }
}
