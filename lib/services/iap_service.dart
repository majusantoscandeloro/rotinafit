import 'dart:async';
import 'dart:io' show Platform;
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// IDs dos produtos de assinatura. Configure os mesmos IDs na Google Play Console e no App Store Connect.
const String kProductIdMonthly = 'rotinafit_premium_monthly';
const String kProductIdYearly = 'rotinafit_premium_yearly';
const Set<String> kProductIds = {kProductIdMonthly, kProductIdYearly};

/// Resultado de compra/restauração validada: dados para persistir no Firebase.
class PremiumGrantResult {
  const PremiumGrantResult({
    required this.isPremium,
    this.productId,
    this.purchaseId,
    this.platform,
    this.serverVerificationData,
  });
  final bool isPremium;
  final String? productId;
  final String? purchaseId;
  final String? platform;
  /// Token/receipt para enviar à Cloud Function (validar e obter premiumUntil).
  final String? serverVerificationData;
}

/// Serviço de compra in-app (assinatura Premium).
/// Inicialize com [init] e defina [onPremiumGranted] para ser chamado quando uma compra for concluída ou restaurada.
/// Só concede premium após [PurchaseStatus.purchased/restored] e [verificationData.serverVerificationData] não vazio.
class IapService {
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  bool _available = false;
  List<ProductDetails> _products = [];
  String? _loadError;

  /// Chamado quando uma compra ou restauração validada confere Premium. Persista via [PremiumRepository.setPremiumFromPurchase].
  void Function(PremiumGrantResult result)? onPremiumGranted;

  bool get isAvailable => _available;
  List<ProductDetails> get products => List.unmodifiable(_products);
  String? get loadError => _loadError;

  /// Produto mensal, se carregado.
  ProductDetails? get monthlyProduct =>
      _products.where((p) => p.id == kProductIdMonthly).firstOrNull;

  /// Produto anual, se carregado.
  ProductDetails? get yearlyProduct =>
      _products.where((p) => p.id == kProductIdYearly).firstOrNull;

  /// Inicializa o IAP e escuta o stream de compras. Chame uma vez no início do app.
  Future<void> init() async {
    _available = await _iap.isAvailable();
    if (!_available) return;

    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdates,
      onDone: () => _subscription?.cancel(),
      onError: (Object e) {
        if (kDebugMode) debugPrint('IapService purchaseStream error: $e');
      },
    );

    await loadProducts();
  }

  /// Carrega os detalhes dos produtos (preço, título) das lojas.
  Future<void> loadProducts() async {
    _loadError = null;
    if (!_available) return;
    try {
      final response = await _iap.queryProductDetails(kProductIds);
      if (response.notFoundIDs.isNotEmpty && kDebugMode) {
        debugPrint('IapService: produtos não encontrados: ${response.notFoundIDs}');
      }
      _products = response.productDetails;
      if (response.error != null) {
        _loadError = response.error!.message;
      }
    } catch (e) {
      _loadError = e.toString();
      if (kDebugMode) debugPrint('IapService loadProducts: $e');
    }
  }

  void _onPurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) {
    for (final purchase in purchaseDetailsList) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          if (kDebugMode) debugPrint('IapService: purchase pending ${purchase.productID}');
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (!_isPremiumProduct(purchase.productID)) {
            _completePurchaseIfNeeded(purchase);
            break;
          }
          final serverData = purchase.verificationData.serverVerificationData;
          if (serverData.isEmpty) {
            if (kDebugMode) {
              debugPrint('IapService: ignorando compra sem verificationData (${purchase.productID})');
            }
            _completePurchaseIfNeeded(purchase);
            break;
          }
          final platform = Platform.isAndroid ? 'android' : 'ios';
          onPremiumGranted?.call(PremiumGrantResult(
            isPremium: true,
            productId: purchase.productID,
            purchaseId: purchase.purchaseID,
            platform: platform,
            serverVerificationData: serverData,
          ));
          // Android: acknowledge (completePurchase) quando pendingCompletePurchase==true.
          // iOS: finaliza a transação. Sem isso o Android pode reembolsar após 3 dias.
          _completePurchaseIfNeeded(purchase);
          break;
        case PurchaseStatus.error:
          if (kDebugMode) {
            debugPrint('IapService purchase error: ${purchase.error?.message}');
          }
          _completePurchaseIfNeeded(purchase);
          break;
        case PurchaseStatus.canceled:
          _completePurchaseIfNeeded(purchase);
          break;
      }
    }
  }

  /// Chama completePurchase apenas quando o platform espera (pendingCompletePurchase),
  /// para acknowledgement correto no Android e finalização no iOS.
  void _completePurchaseIfNeeded(PurchaseDetails purchase) {
    if (purchase.pendingCompletePurchase) {
      _iap.completePurchase(purchase);
    }
  }

  bool _isPremiumProduct(String productId) =>
      productId == kProductIdMonthly || productId == kProductIdYearly;

  /// Inicia o fluxo de compra para o produto [productId]. O resultado vem via [purchaseStream] e [onPremiumGranted].
  /// Retorna true se o pedido foi enviado à loja; false se IAP indisponível ou produto inválido.
  Future<bool> purchase(String productId) async {
    if (!_available) return false;
    final product = _products.where((p) => p.id == productId).firstOrNull;
    if (product == null) return false;
    return _iap.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: product),
    );
  }

  /// Restaura compras anteriores. Os itens restaurados chegam em [purchaseStream] com status [PurchaseStatus.restored].
  Future<void> restorePurchases() async {
    if (!_available) return;
    await _iap.restorePurchases();
  }

  void dispose() {
    _subscription?.cancel();
  }
}
