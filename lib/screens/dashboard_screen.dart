import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:share_plus/share_plus.dart';
import '../services/ai_client.dart';
import '../services/ai_data_service.dart';
import '../services/neural_tts_service.dart';
import '../services/voice_assistant.dart';
import '../widgets/voice_wave_indicator.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() =>
      _DashboardScreenState();
}

class _DashboardScreenState
    extends State<DashboardScreen> {
  String _filtroFinanzas = "Este Mes";
  String _nombreAdmin = "Admin";
  // Phone security and photos
  bool _hasPattern = false;
  bool _hasPin = false;
  final ImagePicker _picker = ImagePicker();
  final List<Uint8List> _phonePhotos = [];
  String? _selectedClientId;
  Map<String, dynamic>? _selectedClientData;
  String? _hoveredClientId;
  final AiClient _aiClient = AiClient();
  final AiDataService _aiDataService = AiDataService();
  final NeuralTtsService _ttsService = NeuralTtsService();
  final VoiceAssistant _voiceAssistant = VoiceAssistant();
  final TextEditingController _aiQuestionController = TextEditingController();
  bool _showAiAssistant = false;
  bool _isListening = false;
  bool _isAskingAi = false;
  bool _isSpeaking = false;
  bool _isSynthesizingVoice = false;
  String _voiceQuestion = '';
  String _aiResponse = '';
  String? _aiError;

  @override
  void initState() {
    super.initState();
    _cargarNombreAdmin();
    _ttsService.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isSpeaking = state == PlayerState.playing;
        });
      }
    });
  }

  bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  Color _textColor(BuildContext context) =>
      _isDark(context) ? Colors.white : const Color(0xFF172033);

  Color _mutedTextColor(BuildContext context) =>
      _isDark(context) ? Colors.white54 : const Color(0xFF64748B);

  Color _cardBorderColor(BuildContext context) =>
      _isDark(context) ? Colors.white12 : const Color(0xFFD7E0EC);

  Widget _buildPhoneSecurityPanel() {
    return GlassmorphicContainer(
      width: double.infinity,
      height: 260,
      borderRadius: 20,
      blur: 15,
      alignment: Alignment.topLeft,
      border: 1,
      linearGradient: const LinearGradient(
        colors: [
          Color.fromRGBO(255, 255, 255, 0.05),
          Color.fromRGBO(255, 255, 255, 0.02),
        ],
      ),
      borderGradient: const LinearGradient(
        colors: [
          Color.fromRGBO(255, 255, 255, 0.1),
          Colors.transparent,
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Seguridad / Fotos', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            CheckboxListTile(
              value: _hasPattern,
              onChanged: (v) => setState(() => _hasPattern = v ?? false),
              title: const Text('Tiene patrón', style: TextStyle(color: Colors.white70)),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),

            CheckboxListTile(
              value: _hasPin,
              onChanged: (v) => setState(() => _hasPin = v ?? false),
              title: const Text('Tiene PIN', style: TextStyle(color: Colors.white70)),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),

            const SizedBox(height: 6),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () => _pickPhonePhoto(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt, size: 16),
                  label: const Text('Tomar foto'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800]),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _pickPhonePhoto(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library, size: 16),
                  label: const Text('Galería'),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6)),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Thumbnails
            Expanded(
              child: _phonePhotos.isEmpty
                  ? const Center(child: Text('No hay fotos', style: TextStyle(color: Colors.white54)))
                  : GridView.builder(
                      padding: EdgeInsets.zero,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 6, crossAxisSpacing: 6),
                      itemCount: _phonePhotos.length,
                      itemBuilder: (context, index) {
                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.memory(_phonePhotos[index], fit: BoxFit.cover)),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => setState(() => _phonePhotos.removeAt(index)),
                                child: Container(
                                  decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.all(4),
                                  child: const Icon(Icons.delete, color: Colors.white, size: 14),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickPhonePhoto(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(source: source, maxWidth: 2000, maxHeight: 2000, imageQuality: 85);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      setState(() {
        _phonePhotos.add(bytes);
      });
    } catch (e) {
      // ignore errors for now
    }
  }

  Future<void> _cargarNombreAdmin() async {
    final doc = await FirebaseFirestore.instance
        .collection('configuracion')
        .doc('general')
        .get();
    if (doc.exists && doc.data()?['nombreAdmin'] != null) {
      setState(() {
        _nombreAdmin = doc.data()!['nombreAdmin'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLargeScreen = constraints.maxWidth > 900;

        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isLargeScreen ? 30 : 15,
            vertical: isLargeScreen ? 25 : 15,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ===== CARDS SUPERIORES =====
                isLargeScreen
                    ? Row(
                        children: [
                          Expanded(
                            child: _buildMiniAcceso(
                              "Clientes",
                              Icons.people_outline,
                              Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: _buildMiniAcceso(
                              "Reparaciones",
                              Icons.build_circle_outlined,
                              Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: _buildMiniAcceso(
                              "Ventas",
                              Icons.shopping_cart_outlined,
                              Colors.green,
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: _buildMiniAcceso(
                              "Ranking",
                              Icons.leaderboard_outlined,
                              Colors.purple,
                              onTap: _showRepairRanking,
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: _buildMiniAcceso(
                              "Asistente IA",
                              Icons.smart_toy_outlined,
                              Colors.cyan,
                              onTap: () => setState(() => _showAiAssistant = true),
                              isAssistant: true,
                            ),
                          ),
                        ],
                      )
                    : GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.4,
                        children: [
                          _buildMiniAcceso("Clientes", Icons.people_outline, Colors.blue),
                          _buildMiniAcceso("Reparaciones", Icons.build_circle_outlined, Colors.orange),
                          _buildMiniAcceso("Ventas", Icons.shopping_cart_outlined, Colors.green),
                          _buildMiniAcceso("Ranking", Icons.leaderboard_outlined, Colors.purple, onTap: _showRepairRanking),
                          _buildMiniAcceso("Asistente IA", Icons.smart_toy_outlined, Colors.cyan, onTap: () => setState(() => _showAiAssistant = true), isAssistant: true),
                        ],
                      ),

                const SizedBox(height: 25),

                if (_showAiAssistant) ...[
                  _buildAiAssistantCard(),
                  const SizedBox(height: 25),
                ],

                // ===== FINANZAS =====
                _buildFinanzasInteligentes(),

                const SizedBox(height: 25),

                // ===== SECCIÓN: Mis Clientes =====
                _buildMisClientesSection(),

                const SizedBox(height: 25),

                // ===== STOCK BAJO / INVENTARIO CRITICO =====
                const GlassInventorySummary(),
              ],
            ),
          ),
        );
      },
    );
  }

  // ===== CARDS PEQUEÑAS =====

  Widget _buildMiniAcceso(
    String title,
    IconData icon,
    Color color,
    {VoidCallback? onTap, bool isAssistant = false,}
  ) {
    final collection = title == 'Clientes' ? 'clientes' : title == 'Reparaciones' || title == 'Ranking' ? 'reparaciones' : 'facturas';
    if (isAssistant) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: _buildMiniAccessCard(title, icon, color, '🤖'),
      );
    }
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(collection).snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final value = title == 'Ventas'
            ? docs.fold<double>(0, (sum, doc) => sum + _asDouble((doc.data() as Map<String, dynamic>)['total'])).toStringAsFixed(0)
            : docs.length.toString();
        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: _buildMiniAccessCard(title, icon, color, title == 'Ventas' ? '\$$value' : value),
        );
      },
    );
  }

  @override
  void dispose() {
    _ttsService.stop();
    _ttsService.dispose();
    _voiceAssistant.stop();
    _aiQuestionController.dispose();
    super.dispose();
  }

  Future<void> _speakResponse(String text) async {
    if (text.trim().isEmpty) return;
    if (_isSpeaking) {
      await _ttsService.stop();
      if (mounted) setState(() => _isSpeaking = false);
      return;
    }
    setState(() => _isSynthesizingVoice = true);
    try {
      await _ttsService.speak(text);
    } catch (e) {
      debugPrint('Error en reproducción TTS: $e');
    } finally {
      if (mounted) setState(() => _isSynthesizingVoice = false);
    }
  }

  Future<void> _askAi([String? question]) async {
    final message = (question ?? _aiQuestionController.text).trim();
    if (message.isEmpty || _isAskingAi) return;
    await _ttsService.stop();
    setState(() {
      _isAskingAi = true;
      _isSpeaking = false;
      _aiError = null;
      _aiResponse = '';
      _voiceQuestion = message;
      _aiQuestionController.text = message;
    });
    try {
      final dashboard = await _aiDataService.buildCompleteContext();
      final response = await _aiClient.ask(question: message, dashboard: dashboard);
      if (!mounted) return;
      setState(() => _aiResponse = response);
      // Reproducimos automáticamente con voz neuronal de alta calidad
      _speakResponse(response);
    } catch (error) {
      if (!mounted) return;
      setState(() => _aiError = error.toString().replaceFirst('Bad state: ', ''));
    } finally {
      if (mounted) setState(() => _isAskingAi = false);
    }
  }

  Future<void> _listenForAiQuestion() async {
    if (_isListening) {
      await _voiceAssistant.stop();
      if (mounted) setState(() => _isListening = false);
      final query = _aiQuestionController.text.trim();
      if (query.isNotEmpty) {
        _askAi(query);
      }
      return;
    }
    await _voiceAssistant.start(
      onListening: () {
        if (mounted) {
          setState(() {
            _isListening = true;
            _aiError = null;
          });
        }
      },
      onResult: (transcript) {
        if (!mounted) return;
        setState(() {
          _voiceQuestion = transcript;
          _aiQuestionController.text = transcript;
        });
      },
      onError: (message) {
        if (mounted) {
          setState(() {
            _isListening = false;
            _aiError = message;
          });
        }
      },
      onEnd: () {
        if (!mounted) return;
        if (_isListening) {
          setState(() => _isListening = false);
          final query = _aiQuestionController.text.trim();
          if (query.isNotEmpty && !_isAskingAi) {
            _askAi(query);
          }
        }
      },
    );
  }

  Widget _buildAiAssistantCard() {
    final isDark = _isDark(context);
    final textColor = _textColor(context);
    final mutedTextColor = _mutedTextColor(context);

    final suggestedQuestions = [
      '¿Existe algún cliente con el nombre Elena?',
      '¿Qué reparaciones están pendientes?',
      '¿Qué repuestos tienen poco stock?',
      '¿Cuáles son las ventas y ganancias del mes?',
      '¿Hay clientes con saldos o deudas pendientes?',
      '¿Cuáles son las fallas más frecuentes?',
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF10233A) : const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF22D3EE).withAlpha(150)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFF0891B2),
                child: Icon(Icons.smart_toy_outlined, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Asistente IA con Visibilidad Total', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('Conectado a la base de datos en tiempo real: Clientes, Reparaciones, Inventario, Facturación y Finanzas.', style: TextStyle(color: mutedTextColor, fontSize: 13)),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Cerrar asistente',
                onPressed: () => setState(() => _showAiAssistant = false),
                icon: Icon(Icons.close, color: mutedTextColor),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Suggested Question Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: suggestedQuestions.map((q) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8, bottom: 8),
                  child: ActionChip(
                    avatar: const Icon(Icons.help_outline, size: 14, color: Color(0xFF0891B2)),
                    label: Text(q, style: TextStyle(color: textColor, fontSize: 12)),
                    backgroundColor: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
                    side: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFBAE6FD)),
                    onPressed: _isAskingAi ? null : () => _askAi(q),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _aiQuestionController,
                  enabled: !_isAskingAi,
                  onSubmitted: (value) => _askAi(value),
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    hintText: 'Pregúntame cualquier cosa: clientes, reparaciones, stock, finanzas...',
                    hintStyle: TextStyle(color: mutedTextColor),
                    filled: true,
                    fillColor: isDark ? Colors.black26 : Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filled(
                tooltip: _isListening ? 'Detener escucha' : 'Hacer una pregunta por voz',
                onPressed: _isAskingAi ? null : _listenForAiQuestion,
                style: IconButton.styleFrom(backgroundColor: _isListening ? Colors.redAccent : const Color(0xFF0891B2)),
                icon: Icon(_isListening ? Icons.stop : Icons.mic_none),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _isAskingAi ? null : () => _askAi(),
                icon: _isAskingAi
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send),
                label: Text(_isAskingAi ? 'Consultando...' : 'Preguntar'),
              ),
            ],
          ),
          if (_isListening) ...[
            const SizedBox(height: 12),
            VoiceWaveIndicator(
              onStop: _listenForAiQuestion,
              label: 'Escuchando tu voz... Hablá ahora',
            ),
          ],
          if (_isAskingAi) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF0891B2).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF0891B2).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0891B2)),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Analizando la base de datos y generando respuesta con IA...',
                    style: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF0E7490), fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
          if (_voiceQuestion.isNotEmpty && !_isListening) ...[
            const SizedBox(height: 12),
            Text('Consulta: $_voiceQuestion', style: TextStyle(color: mutedTextColor, fontStyle: FontStyle.italic)),
          ],
          if (_aiError != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_aiError!, style: const TextStyle(color: Colors.redAccent))),
                ],
              ),
            ),
          ],
          if (_aiResponse.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.black38 : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.auto_awesome, color: Color(0xFF06B6D4), size: 18),
                          const SizedBox(width: 6),
                          Text('Respuesta de la IA', style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13)),
                          if (_isSynthesizingVoice) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF06B6D4).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('Generando voz...', style: TextStyle(color: Color(0xFF06B6D4), fontSize: 11)),
                            ),
                          ] else if (_isSpeaking) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF22C55E).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.graphic_eq, color: Color(0xFF00E5FF), size: 13),
                                  SizedBox(width: 4),
                                  Text('Voz JARVIS en vivo', style: TextStyle(color: Color(0xFF00E5FF), fontSize: 11, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            tooltip: _isSpeaking ? 'Detener voz JARVIS' : 'Escuchar con voz JARVIS',
                            iconSize: 18,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: Icon(
                              _isSpeaking ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                              color: _isSpeaking ? const Color(0xFFEF4444) : const Color(0xFF06B6D4),
                            ),
                            onPressed: () => _speakResponse(_aiResponse),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            tooltip: 'Copiar respuesta',
                            iconSize: 18,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: Icon(Icons.copy, color: mutedTextColor),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: _aiResponse));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Respuesta copiada al portapapeles'), duration: Duration(seconds: 2)),
                              );
                            },
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            tooltip: 'Limpiar respuesta',
                            iconSize: 18,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: Icon(Icons.clear, color: mutedTextColor),
                            onPressed: () {
                              _ttsService.stop();
                              setState(() {
                                _aiResponse = '';
                                _isSpeaking = false;
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  SelectableText(
                    _aiResponse,
                    style: TextStyle(color: textColor, height: 1.5, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMiniAccessCard(String title, IconData icon, Color color, String value) {
    final isDark = _isDark(context);
    final textColor = _textColor(context);
    return GlassmorphicContainer(
      width: double.infinity,
      height: 115,
      borderRadius: 20,
      blur: 20,
      alignment: Alignment.center,
      border: 1,
      linearGradient: LinearGradient(
        colors: isDark
            ? const [
                Color.fromRGBO(255, 255, 255, 0.08),
                Color.fromRGBO(255, 255, 255, 0.03),
              ]
            : const [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
      ),
      borderGradient: LinearGradient(
        colors: [
          color.withAlpha((0.5 * 255).round()),
          Colors.transparent,
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withAlpha((0.15 * 255).round()),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 22,
                ),
              ),
            ),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
              value,
                maxLines: 1,
                style: TextStyle(
                  fontFamily: 'WhiskeyGirlsCondensedItalic',
                  color: color,
                  fontSize: 22,
                  height: 0.9,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItem(String label) {
    return OutlinedButton(
      onPressed: () {},
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: Colors.white12),
        backgroundColor: const Color.fromRGBO(255, 255, 255, 0.03),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Text(
          label,
          style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildMisClientesSection() {
    final isDark = _isDark(context);
    final textColor = _textColor(context);
    final mutedTextColor = _mutedTextColor(context);

    return LayoutBuilder(builder: (context, constraints) {
      final isCompact = constraints.maxWidth < 400;

      return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('clientes').orderBy('nombre').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const SizedBox.shrink();
          }

          final docs = snapshot.data!.docs;

          return GlassmorphicContainer(
            width: double.infinity,
            borderRadius: 20,
            blur: 15,
            height: 552,
            border: 1,
            linearGradient: LinearGradient(
              colors: isDark
                  ? const [Color.fromRGBO(255, 255, 255, 0.04), Color.fromRGBO(255, 255, 255, 0.02)]
                  : const [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
            ),
            borderGradient:
                LinearGradient(colors: [_cardBorderColor(context), Colors.transparent]),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  isCompact
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Mis Clientes",
                                style: TextStyle(
                                    color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _crearCliente,
                                icon: const Icon(Icons.person_add_alt_1, size: 18),
                                label: const Text('Nuevo cliente'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF3B82F6),
                                  minimumSize: const Size(0, 34),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Mis Clientes",
                                style: TextStyle(
                                    color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
                            ElevatedButton.icon(
                              onPressed: _crearCliente,
                              icon: const Icon(Icons.person_add_alt_1, size: 18),
                              label: const Text('Nuevo cliente'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3B82F6),
                                minimumSize: const Size(0, 34),
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ],
                        ),
                  const SizedBox(height: 15),
                  Expanded(
                    child: ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (ctx, i) {
                        final data = docs[i].data() as Map<String, dynamic>;
                        final isSelected = _selectedClientId == docs[i].id;
                        final isHovered = _hoveredClientId == docs[i].id;
                        return MouseRegion(
                          onEnter: (_) => setState(() => _hoveredClientId = docs[i].id),
                          onExit: (_) => setState(() => _hoveredClientId = null),
                          child: GestureDetector(
                            onTap: () => _mostrarFichaCliente(data, docs[i].id),
                            child: AnimatedScale(
                              scale: isSelected || isHovered ? 1.015 : 1,
                              duration: const Duration(milliseconds: 160),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 160),
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF3B82F6).withOpacity(isDark ? 0.18 : 0.12)
                                      : (isDark
                                          ? Colors.white.withOpacity(0.04)
                                          : const Color(0xFFF8FAFC)),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFF3B82F6)
                                          : _cardBorderColor(context)),
                                ),
                                child: Row(
                                  children: [
                                    const CircleAvatar(
                                        radius: 18, child: Icon(Icons.person_outline, size: 20)),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(data['nombre'] ?? 'Sin nombre',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                  color: textColor, fontWeight: FontWeight.bold)),
                                          Text(data['telefono'] ?? 'Sin teléfono',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style:
                                                  TextStyle(color: mutedTextColor, fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                        tooltip: 'Nuevo ingreso',
                                        onPressed: () =>
                                            _abrirDialogoIngresoParaCliente(data, docs[i].id),
                                        icon: const Icon(Icons.add_circle_outline,
                                            color: Color(0xFF3B82F6))),
                                    IconButton(
                                        tooltip: 'Editar cliente',
                                        onPressed: () => _editarCliente(docs[i].id, data),
                                        icon: const Icon(Icons.edit_outlined,
                                            color: Colors.orangeAccent)),
                                    IconButton(
                                        tooltip: 'Eliminar cliente',
                                        onPressed: () => _confirmarEliminacionCliente(docs[i].id),
                                        icon: const Icon(Icons.delete_outline,
                                            color: Colors.redAccent)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    });
  }

  void _mostrarFichaCliente(Map<String, dynamic> client, String id) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
            child: _buildClientDetailsPanelPopup(client, id),
          ),
        );
      },
    );
  }

  Widget _buildClientDetailsPanelPopup(Map<String, dynamic> client, String selectedId) {
    final textColor = _textColor(context);
    final mutedTextColor = _mutedTextColor(context);
    final clientName = client['nombre']?.toString() ?? '';

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reparaciones')
          .where('cliente', isEqualTo: clientName)
          .snapshots(),
      builder: (context, repairSnapshot) {
        final repairs = repairSnapshot.data?.docs ?? [];
        final repairDoc = repairs.isEmpty ? null : repairs.last;
        final repair =
            repairDoc == null ? <String, dynamic>{} : repairDoc.data() as Map<String, dynamic>;
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('facturas').snapshots(),
          builder: (context, invoiceSnapshot) {
            final invoices = (invoiceSnapshot.data?.docs ?? []).where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return (data['nombreCliente'] ?? data['cliente'])?.toString() == clientName;
            }).toList();
            final total = invoices.fold<double>(
                0, (sum, doc) => sum + _asDouble((doc.data() as Map<String, dynamic>)['total']));
            final balance = invoices.fold<double>(0,
                (sum, doc) => sum + _asDouble((doc.data() as Map<String, dynamic>)['saldoRestante']));
            final paid = invoices.isNotEmpty && balance <= 0;
            final photos = List<String>.from(repair['phone_photos'] ?? const []);

            return _buildClientDetailsCard(
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(client['nombre'] ?? 'Sin nombre',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white54),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    _detailRow('Teléfono', _clientPhones(client)),
                    Divider(height: 18, color: _cardBorderColor(context)),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withOpacity(0.16),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.5))),
                      child: Text(
                          '${repair['marca']?.toString() ?? '-'} · ${repair['modelo']?.toString() ?? repair['equipo']?.toString() ?? '-'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.lightBlueAccent, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 8),
                    _detailRow('Falla', repair['falla'] ?? '-'),
                    if (repairDoc != null)
                      Row(children: [
                        SizedBox(
                            width: 64,
                            child: Text('Estado:', style: TextStyle(color: mutedTextColor, fontSize: 12))),
                        SizedBox(
                          width: 132,
                          child: DropdownButton<String>(
                            value: _repairStatus(repair['estado']),
                            isExpanded: true,
                            isDense: true,
                            itemHeight: 48,
                            menuMaxHeight: 170,
                            borderRadius: BorderRadius.circular(12),
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                            dropdownColor: Theme.of(context).colorScheme.surface,
                            style: TextStyle(color: textColor, fontSize: 12),
                            underline: const SizedBox(),
                            items: const ['Pendiente', 'En proceso', 'Terminado', 'Entregado']
                                .map((status) => DropdownMenuItem(value: status, child: Text(status)))
                                .toList(),
                            onChanged: (status) {
                              if (status != null) repairDoc.reference.update({'estado': status});
                            },
                          ),
                        ),
                      ])
                    else
                      _detailRow('Estado', '-'),
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.13), borderRadius: BorderRadius.circular(10)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('TOTAL REPARACIÓN', style: TextStyle(color: mutedTextColor, fontSize: 11)),
                        Text(
                          '\$${total.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontFamily: 'WhiskeyGirlsCondensedItalic',
                            color: Colors.greenAccent,
                            fontSize: 32,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ]),
                    ),
                    _detailRow('Entrega', '\$${_asDouble(repair['entrega']).toStringAsFixed(0)}'),
                    _detailRow('Saldo', '\$${balance.toStringAsFixed(0)}',
                        color: balance > 0 ? Colors.orangeAccent : Colors.greenAccent),
                    _detailRow('Pago',
                        paid ? 'Pagado' : invoices.isEmpty ? 'Sin factura' : 'Pendiente',
                        color: paid ? Colors.greenAccent : Colors.orangeAccent),
                    Divider(height: 20, color: _cardBorderColor(context)),
                    _buildSecurityControls(repairDoc, repair, photos),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildClientDetailsCard(Widget child) {
    final isDark = _isDark(context);
    return GlassmorphicContainer(
      width: double.infinity,
      height: 552,
      borderRadius: 20,
      blur: 15,
      alignment: Alignment.topLeft,
      border: 1,
      linearGradient: LinearGradient(colors: isDark ? const [Color.fromRGBO(255, 255, 255, 0.06), Color.fromRGBO(255, 255, 255, 0.02)] : const [Color(0xFFFFFFFF), Color(0xFFF8FAFC)]),
      borderGradient: LinearGradient(colors: [isDark ? const Color(0x663B82F6) : const Color(0xFF93C5FD), Colors.transparent]),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }

  String _repairStatus(dynamic value) {
    const statuses = ['Pendiente', 'En proceso', 'Terminado', 'Entregado'];
    return statuses.contains(value) ? value as String : 'Pendiente';
  }

  Widget _buildSecurityControls(
    QueryDocumentSnapshot? repairDoc,
    Map<String, dynamic> repair,
    List<String> photos,
  ) {
    if (repairDoc == null) {
      return const Text('No hay una reparación asociada para configurar seguridad o fotos.', style: TextStyle(color: Colors.white54, fontSize: 12));
    }
    return _SecurityControls(
      reference: repairDoc.reference,
      repair: repair,
      photos: photos,
      addPhoto: _addRepairPhoto,
    );

    /*
    final reference = repairDoc.reference;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Seguridad y fotos', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        CheckboxListTile(
          value: repair['tiene_patron'] == true,
          onChanged: (value) => reference.update({'tiene_patron': value ?? false}),
          title: const Text('Tiene patrón', style: TextStyle(color: Colors.white70, fontSize: 13)),
          contentPadding: EdgeInsets.zero,
          dense: true,
          controlAffinity: ListTileControlAffinity.leading,
        ),
        Row(children: [
          Checkbox(value: repair['tiene_pin'] == true, onChanged: (value) => reference.update({'tiene_pin': value ?? false}), materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
          const Text('Tiene PIN', style: TextStyle(color: Colors.white70, fontSize: 13)),
          if (repair['tiene_pin'] == true) ...[
            const SizedBox(width: 8),
            Expanded(child: TextFormField(initialValue: repair['pin']?.toString() ?? '', onFieldSubmitted: (pin) => reference.update({'pin': pin}), style: const TextStyle(color: Colors.white, fontSize: 13), decoration: const InputDecoration(isDense: true, hintText: 'PIN'))),
          ],
        ]),
        const SizedBox(height: 6),
        Row(children: [
          OutlinedButton.icon(onPressed: () => _addRepairPhoto(reference, photos, ImageSource.camera), icon: const Icon(Icons.camera_alt, size: 16), label: const Text('Foto'), style: OutlinedButton.styleFrom(minimumSize: const Size(0, 34), tapTargetSize: MaterialTapTargetSize.shrinkWrap)),
          const SizedBox(width: 8),
          OutlinedButton.icon(onPressed: () => _addRepairPhoto(reference, photos, ImageSource.gallery), icon: const Icon(Icons.photo_library, size: 16), label: const Text('Galería'), style: OutlinedButton.styleFrom(minimumSize: const Size(0, 34), tapTargetSize: MaterialTapTargetSize.shrinkWrap)),
        ]),
        if (photos.isNotEmpty) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 58,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: photos.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (_, index) => ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  photos[index],
                  width: 58,
                  height: 58,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox(
                    width: 58,
                    child: Icon(Icons.broken_image, color: Colors.white54),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

    */
  }

  Future<void> _addRepairPhoto(DocumentReference reference, List<String> photos, ImageSource source) async {
    final file = await _picker.pickImage(source: source, maxWidth: 2000, maxHeight: 2000, imageQuality: 85);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final storageRef = FirebaseStorage.instance.ref('reparaciones/${reference.id}/photos/${DateTime.now().millisecondsSinceEpoch}.jpg');
    final uploaded = await storageRef.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    final url = await uploaded.ref.getDownloadURL();
    await reference.update({'phone_photos': [...photos, url]});
  }

  Widget _detailRow(String label, String value, {Color? color}) {
    final textColor = _textColor(context);
    final mutedTextColor = _mutedTextColor(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(width: 64, child: Text('$label:', style: TextStyle(color: mutedTextColor, fontSize: 12))),
          Expanded(child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: color ?? textColor, fontSize: 12, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  String _clientPhones(Map<String, dynamic> client) {
    final phones = client['telefonos'];
    if (phones is Iterable && phones.isNotEmpty) {
      return phones.map((phone) => phone.toString()).join(' · ');
    }
    final phone = client['telefono']?.toString().trim();
    return phone == null || phone.isEmpty ? 'Sin teléfono' : phone;
  }

  Future<void> _crearCliente() async {
    final nombreCtrl = TextEditingController();
    final telefonoCtrl = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nuevo cliente'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nombreCtrl, autofocus: true, decoration: const InputDecoration(labelText: 'Nombre')),
            const SizedBox(height: 12),
            TextField(controller: telefonoCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Teléfono')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (nombreCtrl.text.trim().isEmpty) return;
              await FirebaseFirestore.instance.collection('clientes').add({
                'nombre': nombreCtrl.text.trim(),
                'telefono': telefonoCtrl.text.trim(),
                'fecha_registro': DateTime.now(),
              });
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showRepairRanking() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ranking de reparaciones'),
        content: SizedBox(
          width: 360,
          height: 360,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('reparaciones').snapshots(),
            builder: (context, snapshot) {
              final ranking = <String, int>{};
              for (final doc in snapshot.data?.docs ?? []) {
                final data = doc.data() as Map<String, dynamic>;
                final key = (data['falla'] ?? data['modelo'] ?? 'Sin detalle').toString();
                ranking[key] = (ranking[key] ?? 0) + 1;
              }
              final entries = ranking.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
              return ListView.builder(itemCount: entries.length, itemBuilder: (_, index) => ListTile(leading: CircleAvatar(child: Text('${index + 1}')), title: Text(entries[index].key), trailing: Text('${entries[index].value}')));
            },
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar'))],
      ),
    );
  }

  Future<void> _editarCliente(String id, Map<String, dynamic> data) async {
    final nombreCtrl = TextEditingController(text: data['nombre']?.toString() ?? '');
    final telefonoCtrl = TextEditingController(text: data['telefono']?.toString() ?? '');
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Editar cliente'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre')),
            const SizedBox(height: 12),
            TextField(controller: telefonoCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Teléfono')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (nombreCtrl.text.trim().isEmpty) return;
              await FirebaseFirestore.instance.collection('clientes').doc(id).update({
                'nombre': nombreCtrl.text.trim(),
                'telefono': telefonoCtrl.text.trim(),
              });
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmarEliminacionCliente(String id) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar cliente'),
        content: const Text('¿Querés eliminar este cliente?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('clientes').doc(id).delete();
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Future<int> _siguienteNumeroFactura() async {
    try {
      final q = await FirebaseFirestore.instance.collection('facturas').orderBy('numeroFactura', descending: true).limit(1).get();
      if (q.docs.isNotEmpty) {
        final d = q.docs.first.data();
        if (d['numeroFactura'] != null) return (d['numeroFactura'] as num).toInt() + 1;
      }
    } catch (e) {
      // ignore
    }
    return 1;
  }

  Future<void> _abrirDialogoIngresoParaCliente(Map<String, dynamic>? clienteData, String? clienteId) async {
    final marcaCtrl = TextEditingController(text: 'Samsung');
    final modeloCtrl = TextEditingController(text: 'Galaxy S23');
    final fallaCtrl = TextEditingController(text: 'Cambio de módulo');
    final presupuestoCtrl = TextEditingController(text: '0');
    final entregaCtrl = TextEditingController(text: '0');
    final imeiCtrl = TextEditingController();
    final obsCtrl = TextEditingController();
    final pinCtrl = TextEditingController();

    bool tienePatron = false;
    bool tienePin = false;
    final PatternPadController patternCtrl = PatternPadController();
    final List<Uint8List> fotos = [];
    final ImagePicker pickerLocal = ImagePicker();

    Future<void> pickLocal(ImageSource source) async {
      final XFile? f = await pickerLocal.pickImage(source: source, maxWidth: 2000, maxHeight: 2000, imageQuality: 85);
      if (f == null) return;
      final b = await f.readAsBytes();
      fotos.add(b);
    }

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text('Nuevo ingreso para ${clienteData?['nombre'] ?? 'Nuevo cliente'}'),
            content: SingleChildScrollView(
              child: SizedBox(
                width: 500,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (clienteId == null) ...[
                      TextField(decoration: const InputDecoration(labelText: 'Nombre completo'), controller: TextEditingController(text: clienteData?['nombre'] ?? '')),
                      const SizedBox(height: 8),
                    ],
                    TextField(controller: marcaCtrl, decoration: const InputDecoration(labelText: 'Marca')),
                    const SizedBox(height: 8),
                    TextField(controller: modeloCtrl, decoration: const InputDecoration(labelText: 'Modelo')),
                    const SizedBox(height: 8),
                    TextField(controller: fallaCtrl, decoration: const InputDecoration(labelText: 'Falla')),
                    const SizedBox(height: 8),
                    Row(children: [Expanded(child: TextField(controller: presupuestoCtrl, decoration: const InputDecoration(labelText: 'Presupuesto'), keyboardType: TextInputType.number)), const SizedBox(width: 8), Expanded(child: TextField(controller: entregaCtrl, decoration: const InputDecoration(labelText: 'Entrega'), keyboardType: TextInputType.number))]),
                    const SizedBox(height: 8),
                    TextField(controller: imeiCtrl, decoration: const InputDecoration(labelText: 'IMEI')),
                    const SizedBox(height: 8),
                    TextField(controller: obsCtrl, decoration: const InputDecoration(labelText: 'Observaciones')),
                    const SizedBox(height: 12),

                    Row(children: [
                      Checkbox(value: tienePatron, onChanged: (v) => setStateDialog(() => tienePatron = v ?? false)),
                      const SizedBox(width: 6),
                      const Text('Tiene patrón'),
                      const SizedBox(width: 20),
                      Checkbox(value: tienePin, onChanged: (v) => setStateDialog(() => tienePin = v ?? false)),
                      const SizedBox(width: 6),
                      const Text('Tiene PIN'),
                    ]),

                    if (tienePin) TextField(controller: pinCtrl, decoration: const InputDecoration(labelText: 'PIN'), keyboardType: TextInputType.number),

                    if (tienePatron) ...[
                      const SizedBox(height: 8),
                      SizedBox(height: 120, child: _PatternPad(controller: patternCtrl)),
                    ],

                    const SizedBox(height: 8),
                    Row(children: [ElevatedButton.icon(onPressed: () async { await pickLocal(ImageSource.camera); setStateDialog(() {}); }, icon: const Icon(Icons.camera_alt), label: const Text('Tomar foto')), const SizedBox(width: 8), ElevatedButton.icon(onPressed: () async { await pickLocal(ImageSource.gallery); setStateDialog(() {}); }, icon: const Icon(Icons.photo), label: const Text('Galería'))]),
                    const SizedBox(height: 8),
                    fotos.isEmpty ? const Text('No hay fotos') : SizedBox(height: 80, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: fotos.length, itemBuilder: (c, i) => Padding(padding: const EdgeInsets.only(right:8.0), child: Image.memory(fotos[i], width: 80, height: 80, fit: BoxFit.cover)))),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
              ElevatedButton(
                onPressed: () async {
                  // Create client if needed
                  String clienteDocId = clienteId ?? '';
                  if (clienteDocId.isEmpty) {
                    final nombre = (clienteData != null && clienteData['nombre'] != null) ? clienteData['nombre'] : 'Sin nombre';
                    final doc = await FirebaseFirestore.instance.collection('clientes').add({'nombre': nombre, 'telefono': '', 'fecha_registro': DateTime.now()});
                    clienteDocId = doc.id;
                  }

                  // create reparacion
                  final rep = await FirebaseFirestore.instance.collection('reparaciones').add({
                    'equipo': '${marcaCtrl.text} ${modeloCtrl.text}',
                    'marca': marcaCtrl.text,
                    'modelo': modeloCtrl.text,
                    'cliente': clienteData?['nombre'] ?? '',
                    'clienteId': clienteDocId,
                    'falla': fallaCtrl.text,
                    'estado': 'Pendiente',
                    'imei': imeiCtrl.text,
                    'observaciones': obsCtrl.text,
                    'presupuesto': double.tryParse(presupuestoCtrl.text) ?? 0.0,
                    'entrega': double.tryParse(entregaCtrl.text) ?? 0.0,
                    'fecha_ingreso': DateTime.now(),
                    'tiene_patron': tienePatron,
                    'tiene_pin': tienePin,
                    'pin': tienePin ? pinCtrl.text : null,
                    'pattern_base64': null,
                    'phone_photos': [],
                  });

                  // save pattern if drawn
                  if (tienePatron) {
                    final Uint8List? png = await patternCtrl.exportPng();
                    if (png != null) {
                      final b64 = base64Encode(png);
                      await rep.update({'pattern_base64': b64});
                    }
                  }

                  // upload fotos
                  if (fotos.isNotEmpty) {
                    final List<String> urls = [];
                    for (var i = 0; i < fotos.length; i++) {
                      final bytes = fotos[i];
                      final ref = FirebaseStorage.instance.ref().child('reparaciones/${rep.id}/photos/photo_${i}_${DateTime.now().millisecondsSinceEpoch}.jpg');
                      final upload = await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
                      final url = await upload.ref.getDownloadURL();
                      urls.add(url);
                    }
                    if (urls.isNotEmpty) await rep.update({'phone_photos': urls});
                  }

                  // create factura minimal
                  final numero = await _siguienteNumeroFactura();
                  await FirebaseFirestore.instance.collection('facturas').add({
                    'nombreCliente': clienteData?['nombre'] ?? '',
                    'clienteId': clienteDocId,
                    'equipo': '${marcaCtrl.text} ${modeloCtrl.text}',
                    'falla': fallaCtrl.text,
                    'reparacion': 'Service',
                    'numeroFactura': numero,
                    'estadoPago': 'Pagado',
                    'metodoPago': 'Efectivo',
                    'montoEntrega': double.tryParse(entregaCtrl.text) ?? 0.0,
                    'saldoRestante': 0,
                    'total': double.tryParse(presupuestoCtrl.text) ?? 0.0,
                    'fechaFactura': DateTime.now(),
                    'manoObra': presupuestoCtrl.text,
                    'repuesto': '0',
                    'envio': '0',
                    'fecha': DateTime.now(),
                  });

                  if (mounted) Navigator.pop(context);
                },
                child: const Text('Guardar'),
              ),
            ],
          );
        });
      },
    );
  }

  // Pattern pad widget and controller

  // ===== TARJETA FINANZAS =====

  Widget _buildFinanzasInteligentes() {
    final isDark = _isDark(context);
    final textColor = _textColor(context);
    final mutedTextColor = _mutedTextColor(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isLargeScreen = constraints.maxWidth > 900;

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('facturas').snapshots(),
          builder: (context, snapshot) {
            double ingresos = 0;
            double gastos = 0;

            if (snapshot.hasData) {
              final ahora = DateTime.now();
              for (var doc in snapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                final fecha = _invoiceDate(data);
                if (fecha == null) continue;
                bool incluir = false;
                if (_filtroFinanzas == "Esta Semana") {
                  incluir = fecha.isAfter(ahora.subtract(const Duration(days: 7)));
                } else if (_filtroFinanzas == "Este Mes") {
                  incluir = fecha.month == ahora.month && fecha.year == ahora.year;
                } else {
                  incluir = fecha.year == ahora.year;
                }
                if (incluir) {
                  ingresos += _asDouble(data['total']);
                  gastos += _expenseForInvoice(data);
                }
              }
            }

            double ganancia = ingresos - gastos;

            return GlassmorphicContainer(
              width: double.infinity,
              height: isLargeScreen ? 215 : 430,
              borderRadius: 25,
              blur: 20,
              alignment: Alignment.topLeft,
              border: 1,
              linearGradient: LinearGradient(
                colors: isDark
                    ? [Colors.white.withOpacity(0.08), Colors.white.withOpacity(0.03)]
                    : const [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
              ),
              borderGradient: LinearGradient(
                colors: [Colors.greenAccent.withOpacity(0.4), Colors.transparent],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Resumen Financiero",
                                  style: TextStyle(
                                      color: textColor,
                                      fontSize: isLargeScreen ? 22 : 18,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text("Ingresos, gastos y ganancias",
                                  style: TextStyle(color: mutedTextColor, fontSize: 13)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: DropdownButton<String>(
                            value: _filtroFinanzas,
                            dropdownColor: Theme.of(context).colorScheme.surface,
                            underline: const SizedBox(),
                            icon: const Icon(Icons.keyboard_arrow_down,
                                color: Colors.greenAccent, size: 18),
                            style: const TextStyle(
                                color: Colors.greenAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 12),
                            onChanged: (val) => setState(() => _filtroFinanzas = val!),
                            items: ["Esta Semana", "Este Mes", "Este Año"]
                                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: isLargeScreen
                          ? Row(
                              children: [
                                Expanded(
                                    child: _buildFinanceCard(
                                        "Ingresos",
                                        "\$${ingresos.toStringAsFixed(0)}",
                                        Icons.trending_up,
                                        isDark ? Colors.white : const Color(0xFF2563EB),
                                        onTap: () => _showFinancialBreakdown(
                                            context, 'Ingresos', 'ingresos', snapshot.data!.docs))),
                                const SizedBox(width: 12),
                                Expanded(
                                    child: _buildFinanceCard(
                                        "Gastos",
                                        "\$${gastos.toStringAsFixed(0)}",
                                        Icons.trending_down,
                                        Colors.red,
                                        onTap: () => _showFinancialBreakdown(
                                            context, 'Gastos', 'gastos', snapshot.data!.docs))),
                                const SizedBox(width: 12),
                                Expanded(
                                    child: _buildFinanceCard(
                                        "Ganancia",
                                        "\$${ganancia.toStringAsFixed(0)}",
                                        Icons.payments_outlined,
                                        Colors.green,
                                        onTap: () => _showFinancialBreakdown(
                                            context, 'Ganancia', 'ganancia', snapshot.data!.docs))),
                              ],
                            )
                          : Column(
                              children: [
                                Expanded(
                                    child: _buildFinanceCard(
                                        "Ingresos",
                                        "\$${ingresos.toStringAsFixed(0)}",
                                        Icons.trending_up,
                                        isDark ? Colors.white : const Color(0xFF2563EB),
                                        onTap: () => _showFinancialBreakdown(
                                            context, 'Ingresos', 'ingresos', snapshot.data!.docs))),
                                const SizedBox(height: 10),
                                Expanded(
                                    child: _buildFinanceCard(
                                        "Gastos",
                                        "\$${gastos.toStringAsFixed(0)}",
                                        Icons.trending_down,
                                        Colors.red,
                                        onTap: () => _showFinancialBreakdown(
                                            context, 'Gastos', 'gastos', snapshot.data!.docs))),
                                const SizedBox(height: 10),
                                Expanded(
                                    child: _buildFinanceCard(
                                        "Ganancia",
                                        "\$${ganancia.toStringAsFixed(0)}",
                                        Icons.payments_outlined,
                                        Colors.green,
                                        onTap: () => _showFinancialBreakdown(
                                            context, 'Ganancia', 'ganancia', snapshot.data!.docs))),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFinanceCard(
    String titulo,
    String valor,
    IconData icon,
    Color color,
    {required VoidCallback onTap,}
  ) {
    final isDark = _isDark(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _cardBorderColor(context),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: color,
              size: 24,
            ),

            const SizedBox(width: 10),

            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: _mutedTextColor(context), fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    valor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'WhiskeyGirlsCondensedItalic',
                      color: color,
                      fontSize: 22,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _asDouble(dynamic value) =>
      value is num ? value.toDouble() : double.tryParse(value?.toString() ?? '') ?? 0;

  double _expenseForInvoice(Map<String, dynamic> data) {
    if (data.containsKey('gastos')) return _asDouble(data['gastos']);
    return _asDouble(data['repuesto']) + _asDouble(data['envio']);
  }

  DateTime? _invoiceDate(Map<String, dynamic> data) {
    final value = data['fecha'];
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.tryParse(value?.toString() ?? '');
  }

  void _showFinancialBreakdown(
    BuildContext context,
    String title,
    String metric,
    Iterable<QueryDocumentSnapshot> invoices,
  ) {
    final now = DateTime.now();
    final monthly = <int, double>{for (var month = 1; month <= 12; month++) month: 0};

    for (final invoice in invoices) {
      final data = invoice.data() as Map<String, dynamic>;
      final date = _invoiceDate(data);
      if (date == null || date.year != now.year) continue;

      final income = _asDouble(data['total']);
      final expense = _expenseForInvoice(data);
      monthly[date.month] = monthly[date.month]! +
          (metric == 'ingresos' ? income : metric == 'gastos' ? expense : income - expense);
    }

    final total = monthly.values.fold<double>(0, (sum, value) => sum + value);
    final theme = Theme.of(context);
    final valueColor = metric == 'gastos' ? Colors.red : metric == 'ganancia' ? Colors.green : Colors.blueAccent;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: theme.dialogBackgroundColor,
        title: Text('$title por mes - ${now.year}', style: TextStyle(color: theme.colorScheme.onSurface)),
        content: SizedBox(
          width: 420,
          height: 420,
          child: ListView.separated(
            itemCount: 12,
            separatorBuilder: (_, __) => Divider(color: theme.dividerColor.withOpacity(0.3)),
            itemBuilder: (_, index) {
              final month = index + 1;
              final amount = monthly[month]!;
              return ListTile(
                dense: true,
                title: Text(_monthName(month), style: TextStyle(color: theme.colorScheme.onSurface)),
                trailing: Text(
                  '\$${amount.toStringAsFixed(0)}',
                  style: TextStyle(color: valueColor, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              );
            },
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Text('Total: \$${total.toStringAsFixed(0)}', style: TextStyle(color: valueColor, fontWeight: FontWeight.bold)),
          ),
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cerrar')),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const months = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];
    return months[month - 1];
  }
}

class _SecurityControls extends StatefulWidget {
  const _SecurityControls({
    required this.reference,
    required this.repair,
    required this.photos,
    required this.addPhoto,
  });

  final DocumentReference reference;
  final Map<String, dynamic> repair;
  final List<String> photos;
  final Future<void> Function(DocumentReference, List<String>, ImageSource)
      addPhoto;

  @override
  State<_SecurityControls> createState() => _SecurityControlsState();
}

class _SecurityControlsState extends State<_SecurityControls> {
  late bool _hasPattern;
  late bool _hasPin;
  late List<int> _pattern;
  late TextEditingController _pinController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _hasPattern = widget.repair['tiene_patron'] == true;
    _hasPin = widget.repair['tiene_pin'] == true;
    _pattern = _readPattern(widget.repair['patron']);
    _pinController = TextEditingController(text: widget.repair['pin']?.toString() ?? '');
  }

  List<int> _readPattern(dynamic value) {
    if (value is! Iterable) return [];
    return value
        .map((dot) => dot is num ? dot.toInt() : int.tryParse(dot.toString()))
        .whereType<int>()
        .where((dot) => dot >= 1 && dot <= 9)
        .toList();
  }

  Future<void> _save() async {
    if (_hasPattern && _pattern.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dibujá un patrón antes de guardar.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.reference.update({
        'tiene_patron': _hasPattern,
        'patron': _hasPattern ? _pattern : [],
        'patron_inicio': _hasPattern ? _pattern.first : null,
        'patron_fin': _hasPattern ? _pattern.last : null,
        'tiene_pin': _hasPin,
        'pin': _hasPin ? _pinController.text.trim() : null,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seguridad guardada.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _share() async {
    final lines = <String>[
      'Datos de seguridad del equipo',
      'Equipo: ${widget.repair['marca'] ?? ''} ${widget.repair['modelo'] ?? widget.repair['equipo'] ?? ''}'.trim(),
      if (_hasPattern && _pattern.isNotEmpty) 'Patrón: ${_pattern.join(' → ')} (inicio ${_pattern.first}, fin ${_pattern.last})',
      if (_hasPin) 'PIN: ${_pinController.text.trim().isEmpty ? 'Sin definir' : _pinController.text.trim()}',
    ];
    await SharePlus.instance.share(ShareParams(text: lines.join('\n')));
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF172033);
    final mutedTextColor = isDark ? Colors.white70 : const Color(0xFF64748B);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Seguridad y fotos', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        CheckboxListTile(
          value: _hasPattern,
          onChanged: (value) => setState(() => _hasPattern = value ?? false),
          title: Text('Tiene patrón', style: TextStyle(color: mutedTextColor, fontSize: 13)),
          contentPadding: EdgeInsets.zero,
          dense: true,
          controlAffinity: ListTileControlAffinity.leading,
        ),
        if (_hasPattern) ...[
          PatternDotsInput(
            initialPattern: _pattern,
            onChanged: (pattern) => setState(() => _pattern = pattern),
          ),
          const SizedBox(height: 4),
          Text(
            _pattern.isEmpty
                ? 'Deslizá por los puntos para dibujar el patrón.'
                : 'Inicio: ${_pattern.first}   ·   Final: ${_pattern.last}',
            style: TextStyle(color: mutedTextColor, fontSize: 12),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => setState(() => _pattern = []),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Rehacer'),
            ),
          ),
        ],
        Row(children: [
          Checkbox(value: _hasPin, onChanged: (value) => setState(() => _hasPin = value ?? false), materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
          Text('Tiene PIN', style: TextStyle(color: mutedTextColor, fontSize: 13)),
          if (_hasPin) ...[
            const SizedBox(width: 8),
            Expanded(child: TextField(controller: _pinController, keyboardType: TextInputType.number, style: TextStyle(color: textColor, fontSize: 13), decoration: const InputDecoration(isDense: true, hintText: 'Ingresá el PIN'))),
          ],
        ]),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFD7E0EC)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Fotos y acciones', style: TextStyle(color: isDark ? Colors.white54 : const Color(0xFF64748B), fontSize: 11)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(child: OutlinedButton.icon(onPressed: () => widget.addPhoto(widget.reference, widget.photos, ImageSource.camera), icon: const Icon(Icons.camera_alt, size: 16), label: const Text('Foto'), style: OutlinedButton.styleFrom(minimumSize: const Size(0, 34), tapTargetSize: MaterialTapTargetSize.shrinkWrap))),
                  const SizedBox(width: 8),
                  Expanded(child: OutlinedButton.icon(onPressed: () => widget.addPhoto(widget.reference, widget.photos, ImageSource.gallery), icon: const Icon(Icons.photo_library, size: 16), label: const Text('Galería'), style: OutlinedButton.styleFrom(minimumSize: const Size(0, 34), tapTargetSize: MaterialTapTargetSize.shrinkWrap))),
                ],
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(onPressed: _saving ? null : _save, icon: _saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_outlined, size: 16), label: const Text('Guardar'), style: ElevatedButton.styleFrom(minimumSize: const Size(0, 34), tapTargetSize: MaterialTapTargetSize.shrinkWrap)),
              const SizedBox(height: 6),
              OutlinedButton.icon(onPressed: _share, icon: const Icon(Icons.share_outlined, size: 16), label: const Text('Compartir'), style: OutlinedButton.styleFrom(minimumSize: const Size(0, 34), tapTargetSize: MaterialTapTargetSize.shrinkWrap)),
            ],
          ),
        ),
        if (widget.photos.isNotEmpty) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 58,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.photos.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (_, index) => ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(widget.photos[index], width: 58, height: 58, fit: BoxFit.cover),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class PatternDotsInput extends StatefulWidget {
  const PatternDotsInput({super.key, required this.initialPattern, required this.onChanged});

  final List<int> initialPattern;
  final ValueChanged<List<int>> onChanged;

  @override
  State<PatternDotsInput> createState() => _PatternDotsInputState();
}

class _PatternDotsInputState extends State<PatternDotsInput> {
  late List<int> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List.of(widget.initialPattern);
  }

  @override
  void didUpdateWidget(covariant PatternDotsInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialPattern != widget.initialPattern) {
      _selected = List.of(widget.initialPattern);
    }
  }

  void _selectAt(Offset position, Size size) {
    final horizontalSpace = size.width / 3;
    final verticalSpace = size.height / 3;
    final dotRadius = (horizontalSpace < verticalSpace ? horizontalSpace : verticalSpace) * .42;
    int? dot;
    var closestDistance = double.infinity;

    for (var candidate = 1; candidate <= 9; candidate++) {
      final index = candidate - 1;
      final point = Offset(
        (index % 3 + .5) * horizontalSpace,
        (index ~/ 3 + .5) * verticalSpace,
      );
      final distance = (position - point).distance;
      if (distance <= dotRadius && distance < closestDistance) {
        dot = candidate;
        closestDistance = distance;
      }
    }
    if (dot == null) return;
    if (_selected.contains(dot)) return;
    setState(() => _selected.add(dot!));
    widget.onChanged(List.of(_selected));
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: FractionallySizedBox(
        widthFactor: .72,
        child: SizedBox(
          height: 108,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = Size(constraints.maxWidth, constraints.maxHeight);
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (details) => _selectAt(details.localPosition, size),
                onPanStart: (details) => _selectAt(details.localPosition, size),
                onPanUpdate: (details) => _selectAt(details.localPosition, size),
                child: CustomPaint(
                  painter: _PatternDotsPainter(_selected),
                  child: const SizedBox.expand(),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PatternDotsPainter extends CustomPainter {
  _PatternDotsPainter(this.selected);
  final List<int> selected;

  Offset _point(int dot, Size size) {
    final index = dot - 1;
    return Offset((index % 3 + .5) * size.width / 3, (index ~/ 3 + .5) * size.height / 3);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()..color = const Color(0xFF60A5FA)..strokeWidth = 3..strokeCap = StrokeCap.round;
    for (var index = 1; index < selected.length; index++) {
      canvas.drawLine(_point(selected[index - 1], size), _point(selected[index], size), linePaint);
    }
    final textPainter = TextPainter(textDirection: TextDirection.ltr, textAlign: TextAlign.center);
    for (var dot = 1; dot <= 9; dot++) {
      final point = _point(dot, size);
      final isStart = selected.isNotEmpty && dot == selected.first;
      final isEnd = selected.length > 1 && dot == selected.last;
      final isSelected = selected.contains(dot);
      final patternOrder = selected.indexOf(dot) + 1;
      final color = isEnd ? Colors.redAccent : isStart ? Colors.greenAccent : isSelected ? const Color(0xFF60A5FA) : Colors.white54;
      canvas.drawCircle(point, 15, Paint()..color = color.withOpacity(isSelected ? .9 : .35));
      canvas.drawCircle(point, 15, Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 2);
      textPainter.text = TextSpan(
        text: isSelected ? '$patternOrder' : '',
        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
      );
      textPainter.layout();
      textPainter.paint(canvas, point - Offset(textPainter.width / 2, textPainter.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _PatternDotsPainter oldDelegate) => oldDelegate.selected != selected;
}

// ===== SIDEBAR =====

class SidebarWidget extends StatelessWidget {
  const SidebarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(20),
      child: const Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.flash_on,
                color: Color(0xFF3B82F6),
                size: 30,
              ),

              SizedBox(width: 10),

              Text(
                "Conección One",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],
          ),

          SizedBox(height: 40),

          SidebarItem(
            label: "Dashboard",
            icon:
                Icons.grid_view_rounded,
            isActive: true,
          ),

          SidebarItem(
            label: "Clientes",
            icon: Icons.people_outline,
          ),

          SidebarItem(
            label: "Reparaciones",
            icon:
                Icons.build_circle_outlined,
          ),

          SidebarItem(
            label: "Inventario",
            icon:
                Icons.inventory_2_outlined,
          ),

          SidebarItem(
            label: "Facturación",
            icon:
                Icons.receipt_long_outlined,
          ),

          SidebarItem(
            label: "Reportes",
            icon:
                Icons.bar_chart_outlined,
          ),

          Spacer(),

          SidebarItem(
            label: "Configuración",
            icon:
                Icons.settings_outlined,
          ),
        ],
      ),
    );
  }
}

class SidebarItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;

  const SidebarItem({
    super.key,
    required this.label,
    required this.icon,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
      padding:
          const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFF3B82F6)
            : Colors.transparent,
        borderRadius:
            BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: isActive
                ? Colors.white
                : Colors.white54,
            size: 22,
          ),

          const SizedBox(width: 15),

          Text(
            label,
            style: TextStyle(
              color: isActive
                  ? Colors.white
                  : Colors.white70,
              fontWeight: isActive
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

// ===== HEADER =====

class HeaderWidget extends StatelessWidget {
  final String nombreAdmin;
  const HeaderWidget({super.key, required this.nombreAdmin});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              "¡Bienvenido, $nombreAdmin!",
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            SizedBox(height: 6),

            Text(
              "Panel principal de Conección One",
              style: TextStyle(
                color: Colors.white54,
                fontSize: 14,
              ),
            ),
          ],
        ),

        Row(
          children: [
            Icon(
              Icons.notifications_none,
              color: Colors.white70,
            ),

            SizedBox(width: 20),

            CircleAvatar(
              backgroundColor:
                  Color(0xFF3B82F6),
              child: Icon(
                Icons.person,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ===== REPARACIONES =====

class GlassRecentOrders
    extends StatelessWidget {
  const GlassRecentOrders({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GlassmorphicContainer(
      width: double.infinity,
      height: 280,
      borderRadius: 25,
      blur: 15,
      alignment: Alignment.topLeft,
      border: 1,
      linearGradient: LinearGradient(
        colors: [
          Colors.white.withOpacity(0.05),
          Colors.white.withOpacity(0.02),
        ],
      ),
      borderGradient: LinearGradient(
        colors: [
          Colors.white.withOpacity(0.1),
          Colors.transparent,
        ],
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              "Reparaciones Recientes",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 25),

            _rowItem(
              "Samsung S22 Ultra",
              "Juan Pérez",
              "Pendiente",
              Colors.orange,
            ),

            _rowItem(
              "iPhone 13 Pro",
              "Marina Silva",
              "Terminado",
              Colors.green,
            ),

            _rowItem(
              "Motorola G200",
              "Carlos Ramos",
              "Diagnóstico",
              Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _rowItem(
    String equipo,
    String cliente,
    String estado,
    Color color,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 18,
      ),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment
                .spaceBetween,
        children: [
          Column(
            crossAxisAlignment:
                CrossAxisAlignment
                    .start,
            children: [
              Text(
                equipo,
                style:
                    const TextStyle(
                  color: Colors.white,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                cliente,
                style:
                    const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
            ],
          ),

          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color:
                  color.withOpacity(0.15),
              borderRadius:
                  BorderRadius.circular(
                      10),
            ),
            child: Text(
              estado,
              style: TextStyle(
                color: color,
                fontWeight:
                    FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===== STOCK =====

class GlassInventorySummary
    extends StatelessWidget {
  const GlassInventorySummary({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GlassmorphicContainer(
      width: double.infinity,
      height: 280,
      borderRadius: 25,
      blur: 15,
      alignment: Alignment.topLeft,
      border: 1,
      linearGradient: LinearGradient(
        colors: [
          Colors.white.withOpacity(0.05),
          Colors.white.withOpacity(0.02),
        ],
      ),
      borderGradient: LinearGradient(
        colors: [
          Colors.redAccent
              .withOpacity(0.3),
          Colors.transparent,
        ],
      ),
      child: const Padding(
        padding: EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              "Stock Crítico",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            SizedBox(height: 25),

            Text(
              "• Módulo Samsung A10 (2u)",
              style: TextStyle(
                color: Colors.white70,
              ),
            ),

            SizedBox(height: 14),

            Text(
              "• Batería iPhone 11 (1u)",
              style: TextStyle(
                color: Colors.white70,
              ),
            ),

            SizedBox(height: 14),

            Text(
              "• Pin Moto G9 (0u)",
              style: TextStyle(
                color: Colors.redAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Pattern pad widget and controller (top-level)

class PatternPadController {
  dynamic _state;
  Future<Uint8List?> exportPng() async {
    return await _state?._export();
  }
}

class _PatternPad extends StatefulWidget {
  final PatternPadController controller;
  const _PatternPad({required this.controller});
  @override
  _PatternPadState createState() => _PatternPadState();
}

class _PatternPadState extends State<_PatternPad> {
  final GlobalKey _key = GlobalKey();
  final List<List<Offset>> _strokes = [];

  @override
  void initState() {
    super.initState();
    widget.controller._state = this;
  }

  // ignore: unused_element
  Future<Uint8List?> _export() async {
    try {
      final boundary = _key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: _key,
      child: GestureDetector(
        onPanStart: (details) {
          setState(() {
            _strokes.add([details.localPosition]);
          });
        },
        onPanUpdate: (details) {
          setState(() {
            _strokes.last.add(details.localPosition);
          });
        },
        onPanEnd: (details) {},
        child: Container(
          color: Colors.white12,
          child: CustomPaint(
            painter: _PatternPainter(_strokes),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
}

class _PatternPainter extends CustomPainter {
  final List<List<Offset>> strokes;
  _PatternPainter(this.strokes);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (var s in strokes) {
      if (s.length < 2) continue;
      final path = Path()..moveTo(s.first.dx, s.first.dy);
      for (var i = 1; i < s.length; i++) {
        path.lineTo(s[i].dx, s[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
