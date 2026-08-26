class VoiceAssistant {
  bool get isListening => false;

  Future<void> start({
    required void Function() onListening,
    required void Function(String transcript) onResult,
    required void Function(String message) onError,
    void Function()? onEnd,
  }) async {
    onError('El reconocimiento de voz no está soportado en esta plataforma.');
    if (onEnd != null) onEnd();
  }

  Future<void> stop() async {}
}
