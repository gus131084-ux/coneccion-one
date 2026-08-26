import 'dart:math' as math;
import 'package:flutter/material.dart';

class VoiceWaveIndicator extends StatefulWidget {
  final VoidCallback? onStop;
  final String label;

  const VoiceWaveIndicator({
    super.key,
    this.onStop,
    this.label = 'Escuchando... Hablá ahora',
  });

  @override
  State<VoiceWaveIndicator> createState() => _VoiceWaveIndicatorState();
}

class _VoiceWaveIndicatorState extends State<VoiceWaveIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E1428)
            : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFEF4444).withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEF4444).withValues(alpha: isDark ? 0.2 : 0.1),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          // Glowing Animated Mic Dot / Pulse
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final scale = 1.0 + 0.25 * math.sin(_controller.value * 2 * math.pi);
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFFEF4444),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 12),

          // Text message
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.label,
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF991B1B),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  'El asistente está reconociendo tu voz en tiempo real...',
                  style: TextStyle(
                    color: isDark ? Colors.white60 : const Color(0xFFB91C1C),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Animated Audio Wave Bars
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(7, (index) {
                  final phase = index * (math.pi / 3.5);
                  final barHeight = 8.0 +
                      18.0 *
                          (0.5 +
                              0.5 *
                                  math.sin(_controller.value * 2 * math.pi +
                                      phase));
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: 3.5,
                    height: barHeight,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Color(0xFFEF4444),
                          Color(0xFF06B6D4),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              );
            },
          ),

          if (widget.onStop != null) ...[
            const SizedBox(width: 12),
            IconButton(
              tooltip: 'Detener grabación',
              icon: const Icon(Icons.stop_circle, color: Color(0xFFEF4444), size: 24),
              onPressed: widget.onStop,
            ),
          ],
        ],
      ),
    );
  }
}

