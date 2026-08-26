import 'package:audioplayers/audioplayers.dart';
import 'package:coneccionone/services/tts/tts_engine.dart';

class NeuralTtsService {
  bool get isPlaying => false;
  String get activeEngineName => 'Stub';
  Stream<PlayerState> get onPlayerStateChanged => const Stream.empty();

  Future<TtsSynthesisResult> synthesize({
    required String text,
    TtsOptions? options,
  }) async {
    throw UnsupportedError('Plataforma no soportada para síntesis de voz.');
  }

  Future<void> speak(
    String text, {
    TtsOptions? options,
  }) async {}

  Future<void> stop() async {}
  Future<void> pause() async {}
  Future<void> resume() async {}

  void dispose() {}
}
