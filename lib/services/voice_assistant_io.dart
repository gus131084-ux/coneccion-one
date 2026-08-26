import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';

class VoiceAssistant {
  final SpeechToText _speechToText = SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;
  Process? _windowsProcess;

  bool get isListening => _isListening;

  Future<void> start({
    required void Function() onListening,
    required void Function(String transcript) onResult,
    required void Function(String message) onError,
    void Function()? onEnd,
  }) async {
    if (Platform.isWindows) {
      await _startWindows(
        onListening: onListening,
        onResult: onResult,
        onError: onError,
        onEnd: onEnd,
      );
      return;
    }

    try {
      if (!_isInitialized) {
        _isInitialized = await _speechToText.initialize(
          onError: (errorNotification) {
            debugPrint('SpeechToText error: ${errorNotification.errorMsg}');
            if (errorNotification.errorMsg != 'error_no_match') {
              onError(errorNotification.errorMsg);
            }
            if (onEnd != null) onEnd();
          },
          onStatus: (status) {
            debugPrint('SpeechToText status: $status');
            if (status == 'listening') {
              _isListening = true;
              onListening();
            } else if (status == 'notListening' || status == 'done') {
              _isListening = false;
              if (onEnd != null) onEnd();
            }
          },
        );
      }

      if (!_isInitialized) {
        onError('No se pudo inicializar el micrófono. Comprobá los permisos en tu dispositivo.');
        if (onEnd != null) onEnd();
        return;
      }

      _isListening = true;
      onListening();

      final locales = await _speechToText.locales();
      String? selectedLocale;
      for (final l in locales) {
        if (l.localeId.startsWith('es')) {
          selectedLocale = l.localeId;
          break;
        }
      }

      await _speechToText.listen(
        onResult: (result) {
          final words = result.recognizedWords.trim();
          if (words.isNotEmpty) {
            onResult(words);
          }
        },
        listenOptions: SpeechListenOptions(
          cancelOnError: false,
          partialResults: true,
          listenMode: ListenMode.dictation,
          localeId: selectedLocale ?? 'es_AR',
        ),
      );
    } catch (e) {
      _isListening = false;
      debugPrint('Error en VoiceAssistant.start: $e');
      onError('No se pudo acceder al micrófono: $e');
      if (onEnd != null) onEnd();
    }
  }

  Future<void> _startWindows({
    required void Function() onListening,
    required void Function(String transcript) onResult,
    required void Function(String message) onError,
    void Function()? onEnd,
  }) async {
    _isListening = true;
    onListening();

    final script = '''
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName System.Speech
try {
    \$rec = New-Object System.Speech.Recognition.SpeechRecognitionEngine
    \$rec.SetInputToDefaultAudioDevice()
    \$grammar = New-Object System.Speech.Recognition.DictationGrammar
    \$rec.LoadGrammar(\$grammar)
    
    Register-ObjectEvent -InputObject \$rec -EventName SpeechHypothesized -Action {
        [Console]::WriteLine("HYP:" + \$EventArgs.Result.Text)
    } | Out-Null

    \$res = \$rec.Recognize([TimeSpan]::FromSeconds(15))
    if (\$res) {
        [Console]::WriteLine("FINAL:" + \$res.Text)
    }
} catch {
    [Console]::WriteLine("ERR:" + \$_)
}
''';

    try {
      final process = await Process.start(
        'powershell',
        ['-NoProfile', '-NonInteractive', '-Command', script],
      );
      _windowsProcess = process;

      process.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
        final trimmed = line.trim();
        if (trimmed.startsWith('HYP:')) {
          final text = trimmed.substring(4).trim();
          if (text.isNotEmpty) {
            onResult(text);
          }
        } else if (trimmed.startsWith('FINAL:')) {
          final text = trimmed.substring(6).trim();
          if (text.isNotEmpty) {
            onResult(text);
          }
        } else if (trimmed.startsWith('ERR:')) {
          onError('Error micrófono Windows: ${trimmed.substring(4)}');
        }
      });

      process.exitCode.then((_) {
        _isListening = false;
        _windowsProcess = null;
        if (onEnd != null) onEnd();
      });
    } catch (e) {
      _isListening = false;
      onError('No se pudo iniciar el micrófono en Windows: $e');
      if (onEnd != null) onEnd();
    }
  }

  Future<void> stop() async {
    _isListening = false;
    try {
      if (_windowsProcess != null) {
        _windowsProcess?.kill();
        _windowsProcess = null;
      }
      if (_speechToText.isListening) {
        await _speechToText.stop();
      }
    } catch (_) {}
  }
}
