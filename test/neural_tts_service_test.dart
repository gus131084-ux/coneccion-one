import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:coneccionone/services/neural_tts_service.dart';
import 'package:coneccionone/services/tts/tts_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global'),
      (MethodCall methodCall) async => 1,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      (MethodCall methodCall) async => 1,
    );
  });

  group('JarvisTextPreprocessor tests', () {
    test('Preprocesses markdown, currency, and abbreviations', () {
      final input = '**Alerta:** El Sr. Lopez debe \$15000 por la reparación del [iPhone 13](http://link.com).\n\nRevisar urgente.';
      final output = JarvisTextPreprocessor.preprocess(input);

      expect(output.contains('**'), isFalse);
      expect(output.contains('Señor'), isTrue);
      expect(output.contains('15000 pesos'), isTrue);
      expect(output.contains('iPhone 13'), isTrue);
      expect(output.contains('http'), isFalse);
    });

    test('Detects alert vs financial vs general context prompt', () {
      final alertPrompt = JarvisTextPreprocessor.getContextPrompt('Atención: hay una alerta de seguridad.');
      expect(alertPrompt.toLowerCase().contains('advertencia'), isTrue);

      final reportPrompt = JarvisTextPreprocessor.getContextPrompt('El balance total y las ganancias del mes.');
      expect(reportPrompt.toLowerCase().contains('financiero'), isTrue);

      final generalPrompt = JarvisTextPreprocessor.getContextPrompt('Hola, hay 3 reparaciones listas para entrega.');
      expect(generalPrompt.toLowerCase().contains('jarvis'), isTrue);
    });
  });

  group('NeuralTtsService unit tests', () {
    test('Synthesizing empty text throws ArgumentError', () async {
      final tts = NeuralTtsService();
      expect(() => tts.synthesize(text: '   '), throwsArgumentError);
      tts.dispose();
    });
  });
}
