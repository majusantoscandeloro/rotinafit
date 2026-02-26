import 'dart:io' show Platform;
import 'package:app_tracking_transparency/app_tracking_transparency.dart';

/// App Tracking Transparency (iOS 14+).
/// Solicita permissão de rastreamento para anúncios mais relevantes e melhor atribuição.
/// Só executa no iOS; no Android não faz nada.
class AttService {
  /// Chame após o primeiro frame da tela principal (ex.: na Home).
  /// Só exibe o diálogo do sistema se o status for [TrackingStatus.notDetermined].
  static Future<void> requestTrackingIfNeeded() async {
    if (!Platform.isIOS) return;
    try {
      final status = await AppTrackingTransparency.trackingAuthorizationStatus;
      if (status != TrackingStatus.notDetermined) return;
      // Pequeno atraso para o usuário ver a tela antes do diálogo (recomendado pela Apple)
      await Future<void>.delayed(const Duration(milliseconds: 500));
      await AppTrackingTransparency.requestTrackingAuthorization();
    } catch (_) {
      // Ignora erros (ex.: em simulador antigo ou não-iOS)
    }
  }
}
