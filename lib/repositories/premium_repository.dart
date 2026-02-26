import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';

/// Status premium persistido (Firebase + cache local).
class PremiumStatus {
  const PremiumStatus({
    required this.isPremium,
    this.premiumUntil,
    this.productId,
    this.purchaseId,
    this.platform,
    this.updatedAt,
  });

  final bool isPremium;
  final String? premiumUntil;
  final String? productId;
  final String? purchaseId;
  final String? platform;
  final DateTime? updatedAt;

  static PremiumStatus get defaultFree =>
      const PremiumStatus(isPremium: false);
}

/// Repositório de status premium: lê/escreve no Firebase (users/{uid}) e mantém
/// cache local (SharedPreferences) em sync. Nunca marca premium só local sem
/// sincronizar com Firebase quando o usuário estiver logado.
/// [firestore] e [storage] são opcionais para testes; em produção use os do AppProvider.
class PremiumRepository {
  PremiumRepository({
    StorageService? storage,
  }) : _storage = storage ?? StorageService();

  final StorageService _storage;

  /// Lê o status premium. Fonte da verdade: Firestore; cache local é só fallback.
  /// Quando Firestore está disponível, o valor lido sobrescreve o cache.
  Future<PremiumStatus> getPremiumStatus(FirestoreService? firestore) async {
    if (firestore != null && firestore.isAvailable) {
      try {
        final effective = await firestore.isPremium();
        final fields = await firestore.getPremiumFields();
        final until = fields?.premiumUntil;
        await _storage.setPremium(effective);
        return PremiumStatus(
          isPremium: effective,
          premiumUntil: until,
          updatedAt: null,
        );
      } catch (e) {
        if (kDebugMode) {
          debugPrint('PremiumRepository getPremiumStatus Firestore error: $e');
        }
      }
    }
    final local = await _storage.isPremium();
    return PremiumStatus(isPremium: local, updatedAt: null);
  }

  /// Persiste status premium a partir de uma compra validada. Escreve no
  /// Firebase (users/{uid}) e no cache local. Só chame após verificação
  /// (ex.: purchaseStatus == purchased/restored e verificationData não vazio).
  Future<void> setPremiumFromPurchase(
    FirestoreService? firestore, {
    required bool isPremium,
    String? premiumUntil,
    String? productId,
    String? purchaseId,
    String? platform,
  }) async {
    final platformStr = platform ?? (Platform.isAndroid ? 'android' : 'ios');
    if (firestore != null && firestore.isAvailable) {
      try {
        await firestore.setPremiumFromPurchase(
          isPremium: isPremium,
          premiumUntil: premiumUntil,
          productId: productId,
          purchaseId: purchaseId,
          platform: platformStr,
        );
      } catch (e) {
        if (kDebugMode) {
          debugPrint('PremiumRepository setPremiumFromPurchase Firestore error: $e');
        }
        rethrow;
      }
    }
    await _storage.setPremium(isPremium);
  }

  /// Apenas seta o bool (ex.: restore local ou debug). Mantém Firebase e local em sync.
  Future<void> setPremium(FirestoreService? firestore, bool value) async {
    if (firestore != null && firestore.isAvailable) {
      try {
        await firestore.setPremium(value);
      } catch (e) {
        if (kDebugMode) debugPrint('PremiumRepository setPremium Firestore error: $e');
      }
    }
    await _storage.setPremium(value);
  }
}
