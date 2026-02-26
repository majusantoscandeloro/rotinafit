import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

/// Serviço de validação de compra no backend (Cloud Function).
///
/// A função [verifyPurchase] no Firebase:
/// - Android: valida com Google Play Developer API e obtém [premiumUntil].
/// - iOS: valida receipt com App Store e obtém [premiumUntil].
/// - Grava em Firestore: users/{uid} com isPremium, premiumUntil, productId, etc.
///
/// Configure a função e os secrets conforme [functions/README_SETUP.md].
class VerifyPurchaseService {
  static final _functions = FirebaseFunctions.instance;

  /// Chama a Cloud Function [verifyPurchase] para validar a compra e gravar premium (com premiumUntil).
  /// [uid] = Firebase Auth UID; [serverVerificationData] = purchaseToken (Android) ou receipt (iOS).
  /// Retorna true se o backend validou e gravou; false em erro ou se desabilitado.
  static Future<bool> verifyWithBackend({
    required String uid,
    required String serverVerificationData,
    required String productId,
    required String? purchaseId,
    required String platform,
  }) async {
    try {
      final callable = _functions.httpsCallable('verifyPurchase');
      final result = await callable.call<Map<String, dynamic>>({
        'purchaseToken': serverVerificationData,
        'productId': productId,
        'purchaseId': purchaseId,
        'platform': platform,
      });
      final data = result.data;
      if (data == null) return false;
      return data['success'] == true;
    } on FirebaseFunctionsException catch (e) {
      if (kDebugMode) {
        debugPrint('VerifyPurchaseService: ${e.code} ${e.message}');
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('VerifyPurchaseService: $e');
      }
      return false;
    }
  }
}
