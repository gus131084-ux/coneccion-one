import 'dart:async';
import 'dart:js' as js;
import 'package:flutter/foundation.dart';

class VoiceAssistant {
  bool _isListening = false;

  bool get isListening => _isListening;

  VoiceAssistant() {
    _injectJsHelper();
  }

  void _injectJsHelper() {
    try {
      js.context.callMethod('eval', [
        '''
        if (!window.__jarvisSpeechHelper) {
          window.__jarvisSpeechHelper = {
            instance: null,
            start: function(lang, onStart, onResult, onError, onEnd) {
              var SpeechRec = window.SpeechRecognition || window.webkitSpeechRecognition;
              if (!SpeechRec) {
                if (onError) onError("El navegador no admite reconocimiento de voz. Usa Chrome o Edge.");
                return null;
              }
              try {
                if (window.__jarvisSpeechHelper.instance) {
                  try { window.__jarvisSpeechHelper.instance.abort(); } catch(e) {}
                }
                var rec = new SpeechRec();
                rec.lang = lang || "es-419";
                rec.continuous = false;
                rec.interimResults = true;
                rec.maxAlternatives = 1;

                rec.onstart = function() {
                  if (onStart) onStart();
                };

                rec.onresult = function(event) {
                  var transcript = "";
                  if (event && event.results) {
                    for (var i = 0; i < event.results.length; i++) {
                      var item = event.results[i];
                      if (item && item[0] && item[0].transcript) {
                        transcript += item[0].transcript;
                      }
                    }
                  }
                  if (transcript.trim().length > 0 && onResult) {
                    onResult(transcript.trim());
                  }
                };

                rec.onerror = function(event) {
                  var err = (event && event.error) ? event.error : "desconocido";
                  if (err === "not-allowed" || err === "permission-denied") {
                    if (onError) onError("Permiso de micrófono denegado. Habilítalo en el candado de la barra de direcciones.");
                  } else if (err !== "no-speech") {
                    if (onError) onError("Micrófono: " + err);
                  }
                  if (onEnd) onEnd();
                };

                rec.onend = function() {
                  if (onEnd) onEnd();
                };

                rec.start();
                window.__jarvisSpeechHelper.instance = rec;
                return rec;
              } catch (err) {
                if (onError) onError("No se pudo iniciar el micrófono: " + err);
                if (onEnd) onEnd();
                return null;
              }
            },
            stop: function() {
              if (window.__jarvisSpeechHelper.instance) {
                try { window.__jarvisSpeechHelper.instance.stop(); } catch(e) {}
                window.__jarvisSpeechHelper.instance = null;
              }
            }
          };
        }
        '''
      ]);
    } catch (e) {
      debugPrint('Error al inyectar helper JS de voz: $e');
    }
  }

  Future<void> start({
    required void Function() onListening,
    required void Function(String transcript) onResult,
    required void Function(String message) onError,
    void Function()? onEnd,
  }) async {
    _injectJsHelper();

    final helper = js.context['__jarvisSpeechHelper'];
    if (helper == null) {
      onError('Reconocimiento de voz no disponible en este navegador.');
      if (onEnd != null) onEnd();
      return;
    }

    try {
      _isListening = true;
      (helper as js.JsObject).callMethod('start', [
        'es-419',
        js.allowInterop(() {
          _isListening = true;
          onListening();
        }),
        js.allowInterop((dynamic transcript) {
          if (transcript != null) {
            onResult(transcript.toString());
          }
        }),
        js.allowInterop((dynamic error) {
          _isListening = false;
          if (error != null) {
            onError(error.toString());
          }
        }),
        js.allowInterop(() {
          _isListening = false;
          if (onEnd != null) onEnd();
        }),
      ]);
    } catch (e) {
      _isListening = false;
      onError('Error iniciando micrófono: $e');
      if (onEnd != null) onEnd();
    }
  }

  Future<void> stop() async {
    _isListening = false;
    try {
      final helper = js.context['__jarvisSpeechHelper'];
      if (helper != null) {
        (helper as js.JsObject).callMethod('stop', const []);
      }
    } catch (_) {}
  }
}
