import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:coneccionone/widgets/voice_wave_indicator.dart';

void main() {
  testWidgets('VoiceWaveIndicator renders animated voice bars and message', (WidgetTester tester) async {
    bool stopped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VoiceWaveIndicator(
            onStop: () => stopped = true,
            label: 'Escuchando tu voz...',
          ),
        ),
      ),
    );

    expect(find.text('Escuchando tu voz...'), findsOneWidget);
    expect(find.byType(IconButton), findsOneWidget);

    await tester.tap(find.byType(IconButton));
    expect(stopped, isTrue);
  });
}
