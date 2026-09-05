import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:coneccionone/services/neural_tts_service.dart';
import 'package:coneccionone/services/tts/tts_engine.dart';

class ConfiguracionScreen extends StatefulWidget {
  const ConfiguracionScreen({super.key});

  @override
  State<ConfiguracionScreen> createState() => _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends State<ConfiguracionScreen> {
  final nombreCtrl = TextEditingController();
  final direccionCtrl = TextEditingController();
  final telefonoCtrl = TextEditingController();
  final adminNombreCtrl = TextEditingController();

  // Configuración de Voz IA
  String _selectedVoiceId = 'Fenrir';
  String _selectedPersonalityId = 'jarvis_clasico';
  final geminiKeyCtrl = TextEditingController();
  final elevenLabsKeyCtrl = TextEditingController();
  final openAiKeyCtrl = TextEditingController();
  double _voiceSpeed = 0.96;
  bool _testingVoice = false;
  final NeuralTtsService _ttsService = NeuralTtsService();

  bool temaOscuro = true;
  Uint8List? logoBytes;
  bool cargando = false;

  @override
  void initState() {
    super.initState();
    cargarConfiguracion();
  }

  @override
  void dispose() {
    _ttsService.stop();
    _ttsService.dispose();
    geminiKeyCtrl.dispose();
    elevenLabsKeyCtrl.dispose();
    openAiKeyCtrl.dispose();
    super.dispose();
  }

  Future<void> cargarConfiguracion() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('configuracion')
          .doc('general')
          .get();

      if (doc.exists) {
        final data = doc.data()!;

        setState(() {
          nombreCtrl.text = data['nombreNegocio'] ?? '';
          direccionCtrl.text = data['direccion'] ?? '';
          telefonoCtrl.text = data['telefono'] ?? '';
          adminNombreCtrl.text = data['nombreAdmin'] ?? '';
          temaOscuro = data['temaOscuro'] ?? true;

          if (data['logoBase64'] != null && data['logoBase64'].toString().isNotEmpty) {
            logoBytes = base64Decode(data['logoBase64']);
          }
        });
      }

      final voiceDoc = await FirebaseFirestore.instance
          .collection('configuracion')
          .doc('voz_ia')
          .get();
      if (voiceDoc.exists) {
        final vData = voiceDoc.data()!;
        setState(() {
          _selectedVoiceId = vData['voice_id'] ?? 'Fenrir';
          _selectedPersonalityId = vData['personality_id'] ?? 'jarvis_clasico';
          geminiKeyCtrl.text = vData['gemini_key'] ?? '';
          elevenLabsKeyCtrl.text = vData['elevenlabs_key'] ?? '';
          openAiKeyCtrl.text = vData['openai_key'] ?? '';
          _voiceSpeed = (vData['velocidad'] as num?)?.toDouble() ?? 0.96;
        });
      }
    } catch (e) {
      debugPrint("Error cargando configuración: $e");
    }
  }

  Future<void> seleccionarLogo() async {
    final picker = ImagePicker();
    final XFile? imagen = await picker.pickImage(source: ImageSource.gallery);

    if (imagen != null) {
      final bytes = await imagen.readAsBytes();

      setState(() {
        logoBytes = bytes;
      });
    }
  }

  String? _toBase64() {
    if (logoBytes == null) return null;
    return base64Encode(logoBytes!);
  }

  Future<void> _testJarvisVoice() async {
    if (_testingVoice) {
      await _ttsService.stop();
      setState(() => _testingVoice = false);
      return;
    }
    setState(() => _testingVoice = true);
    try {
      final selectedVoice = AiVoiceCatalog.getVoiceById(_selectedVoiceId);
      await _ttsService.speak(
        selectedVoice.samplePhrase,
        options: TtsOptions(
          voiceId: _selectedVoiceId,
          personalityId: _selectedPersonalityId,
          speed: _voiceSpeed,
          apiKey: selectedVoice.provider == 'elevenlabs'
              ? elevenLabsKeyCtrl.text.trim()
              : selectedVoice.provider == 'openai'
                  ? openAiKeyCtrl.text.trim()
                  : geminiKeyCtrl.text.trim().isNotEmpty
                      ? geminiKeyCtrl.text.trim()
                      : null,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al probar voz: $e')));
      }
    } finally {
      if (mounted) setState(() => _testingVoice = false);
    }
  }

  Future<void> guardarConfiguracion() async {
    setState(() => cargando = true);

    try {
      await FirebaseFirestore.instance
          .collection('configuracion')
          .doc('general')
          .set({
        'nombreNegocio': nombreCtrl.text.trim(),
        'nombreAdmin': adminNombreCtrl.text.trim(),
        'direccion': direccionCtrl.text.trim(),
        'telefono': telefonoCtrl.text.trim(),
        'temaOscuro': temaOscuro,
        'logoBase64': _toBase64(),
      });

      // Determinar el proveedor en función de la voz seleccionada
      final selectedVoice = AiVoiceCatalog.getVoiceById(_selectedVoiceId);
      final proveedor = selectedVoice.provider;

      await FirebaseFirestore.instance.collection('configuracion').doc('voz_ia').set({
        'proveedor': proveedor,
        'voice_id': _selectedVoiceId,
        'personality_id': _selectedPersonalityId,
        'gemini_key': geminiKeyCtrl.text.trim(),
        'elevenlabs_key': elevenLabsKeyCtrl.text.trim(),
        'openai_key': openAiKeyCtrl.text.trim(),
        'velocidad': _voiceSpeed,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Configuración guardada correctamente")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }

    if (mounted) setState(() => cargando = false);
  }

  Widget _previewLogo() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (logoBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.memory(
          logoBytes!,
          width: 120,
          height: 120,
          fit: BoxFit.cover,
        ),
      );
    }

    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(
        Icons.image_outlined,
        color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
        size: 50,
      ),
    );
  }

  Widget campoTexto(String label, TextEditingController controller, {bool obscure = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: TextStyle(color: textColor),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: isDark ? Colors.white54 : const Color(0xFF64748B)),
          filled: true,
          fillColor: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF8FAFC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }

  Widget _buildJarvisVoiceConfigCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final primaryColor = const Color(0xFF00E5FF);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10, bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.cyan.withOpacity(0.05) : Colors.cyan.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.cyan.withOpacity(0.3) : Colors.cyan.withOpacity(0.4),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.record_voice_over, color: primaryColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Voz de Inteligencia Artificial (Estilo JARVIS)",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    Text(
                      "Personalizá el tono masculino, la cadencia y el motor neuronal",
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── SELECTOR DE VOZ ──────────────────────────────────────────
          Text("🎙️ Seleccionar Voz:", style: TextStyle(fontWeight: FontWeight.w700, color: textColor, fontSize: 15)),
          const SizedBox(height: 10),
          ...AiVoiceCatalog.voices.map((voice) {
            final isSelected = _selectedVoiceId == voice.id;
            return GestureDetector(
              onTap: () => setState(() => _selectedVoiceId = voice.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? primaryColor.withOpacity(0.15)
                      : (isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF8FAFC)),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? primaryColor : (isDark ? Colors.white24 : Colors.black12),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      voice.gender == 'Masculina' ? Icons.person : Icons.person_2_outlined,
                      color: isSelected ? primaryColor : (isDark ? Colors.white54 : Colors.black45),
                      size: 26,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            voice.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: isSelected ? primaryColor : textColor,
                            ),
                          ),
                          Text(
                            voice.description,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white54 : Colors.black45,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check_circle_rounded, color: primaryColor, size: 22),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 20),

          // ── SELECTOR DE PERSONALIDAD ──────────────────────────────────
          Text("🎭 Estilo y Personalidad (en Español Latino):", style: TextStyle(fontWeight: FontWeight.w700, color: textColor, fontSize: 15)),
          const SizedBox(height: 10),
          ...AiVoiceCatalog.personalities.map((personality) {
            final isSelected = _selectedPersonalityId == personality.id;
            return GestureDetector(
              onTap: () => setState(() => _selectedPersonalityId = personality.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.deepPurpleAccent.withOpacity(0.15)
                      : (isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF8FAFC)),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? Colors.deepPurpleAccent : (isDark ? Colors.white24 : Colors.black12),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Text(personality.icon, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            personality.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: isSelected ? Colors.deepPurpleAccent : textColor,
                            ),
                          ),
                          Text(
                            personality.description,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white54 : Colors.black45,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      const Icon(Icons.check_circle_rounded, color: Colors.deepPurpleAccent, size: 22),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 16),

          // ── CLAVES API ──────────────────────────────────────────────
          Text("🔑 Claves de API:", style: TextStyle(fontWeight: FontWeight.w700, color: textColor, fontSize: 15)),
          const SizedBox(height: 10),
          
          campoTexto("Gemini API Key (Para I.A. Dashboard y Voz Gemini)", geminiKeyCtrl, obscure: true),
          campoTexto("ElevenLabs API Key (Para Voces Premium)", elevenLabsKeyCtrl, obscure: true),

          if (AiVoiceCatalog.getVoiceById(_selectedVoiceId).provider == 'openai') ...[
            campoTexto("OpenAI API Key (Opcional)", openAiKeyCtrl, obscure: true),
          ],

          // ── VELOCIDAD DE HABLA ────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Velocidad de habla: ${_voiceSpeed.toStringAsFixed(2)}x", style: TextStyle(color: textColor)),
              Text(_voiceSpeed < 0.95 ? "Calmada" : _voiceSpeed > 1.05 ? "Rápida" : "Óptima", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
            ],
          ),
          Slider(
            value: _voiceSpeed,
            min: 0.8,
            max: 1.2,
            divisions: 8,
            activeColor: primaryColor,
            onChanged: (v) => setState(() => _voiceSpeed = v),
          ),

          const SizedBox(height: 10),

          // ── FRASE DE MUESTRA DE LA VOZ ────────────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
            ),
            child: Row(
              children: [
                Icon(Icons.format_quote_rounded, color: primaryColor, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '"${AiVoiceCatalog.getVoiceById(_selectedVoiceId).samplePhrase}"',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── BOTÓN PROBAR VOZ ──────────────────────────────────────────
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryColor,
                side: BorderSide(color: primaryColor),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onPressed: _testJarvisVoice,
              icon: Icon(_testingVoice ? Icons.stop : Icons.play_arrow),
              label: Text(_testingVoice ? "Detener prueba" : "Probar voz seleccionada"),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Configuración",
            style: GoogleFonts.poppins(
              color: textColor,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 30),

          Expanded(
            child: GlassmorphicContainer(
              width: double.infinity,
              height: double.infinity,
              borderRadius: 25,
              blur: 20,
              alignment: Alignment.topLeft,
              border: 1,
              linearGradient: LinearGradient(
                colors: [
                  isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFFFFFFF),
                  isDark ? Colors.white.withOpacity(0.03) : const Color(0xFFF8FAFC),
                ],
              ),
              borderGradient: LinearGradient(
                colors: [
                  isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFD7E0EC),
                  Colors.transparent,
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Center(child: _previewLogo()),

                      const SizedBox(height: 15),

                      ElevatedButton.icon(
                        onPressed: seleccionarLogo,
                        icon: const Icon(Icons.upload),
                        label: const Text("Subir Logo"),
                      ),

                      const SizedBox(height: 30),

                      campoTexto("Nombre del negocio", nombreCtrl),
                      campoTexto("Nombre del Administrador", adminNombreCtrl),
                      campoTexto("Dirección", direccionCtrl),
                      campoTexto("Teléfono", telefonoCtrl),

                      const SizedBox(height: 20),

                      // Card de configuración de voz JARVIS
                      _buildJarvisVoiceConfigCard(),

                      const SizedBox(height: 10),

                      SwitchListTile(
                        value: temaOscuro,
                        title: Text(
                          "Tema oscuro",
                          style: TextStyle(color: textColor),
                        ),
                        onChanged: (v) {
                          setState(() => temaOscuro = v);
                        },
                      ),

                      const SizedBox(height: 30),

                      ElevatedButton.icon(
                        onPressed: cargando ? null : guardarConfiguracion,
                        icon: const Icon(Icons.save),
                        label: Text(cargando ? "Guardando..." : "Guardar"),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
