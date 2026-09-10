import 'package:flutter/services.dart';

/// Service pour activer/désactiver la protection contre les captures d'écran
/// et les enregistrements vidéo (Android FLAG_SECURE / iOS security).
class ScreenSecurityService {
  ScreenSecurityService._();

  static const MethodChannel _channel =
      MethodChannel('com.example.examsecure/screen_security');

  /// Active le blocage des captures d'écran et masquage dans l'aperçu multitâche.
  static Future<void> enableSecure() async {
    try {
      await _channel.invokeMethod('enableSecure');
    } catch (_) {
      // Ignore si non supporté sur la plateforme courante
    }
  }

  /// Désactive le blocage des captures d'écran.
  static Future<void> disableSecure() async {
    try {
      await _channel.invokeMethod('disableSecure');
    } catch (_) {
      // Ignore si non supporté sur la plateforme courante
    }
  }
}
