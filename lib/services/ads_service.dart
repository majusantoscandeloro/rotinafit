import 'dart:async';
import 'dart:io' show Platform;
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'storage_service.dart';

/// IDs de teste AdMob: Android e iOS usam sufixos diferentes.
String get _bannerAdUnitId =>
    Platform.isIOS ? 'ca-app-pub-3940256099942544/2934735716' : 'ca-app-pub-3940256099942544/6300978111';
String get _interstitialAdUnitId =>
    Platform.isIOS ? 'ca-app-pub-3940256099942544/4411468910' : 'ca-app-pub-3940256099942544/1033173712';
String get _rewardedAdUnitId =>
    Platform.isIOS ? 'ca-app-pub-3940256099942544/1712485313' : 'ca-app-pub-3940256099942544/5224354917';

/// Serviço de anúncios. Banner, intersticial e rewarded (vídeo para ganhar recompensa).
/// Respeita premium e compra única "remover anúncios".
class AdsService {
  final StorageService _storage = StorageService();

  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  bool _showAds = true;

  bool get showAds => _showAds;

  Future<void> init() async {
    await MobileAds.instance.initialize();
    final premium = await _storage.isPremium();
    final adsRemoved = await _storage.isAdsRemoved();
    _showAds = !premium && !adsRemoved;
    loadRewardedAd();
  }

  void updateShowAds(bool premium, bool adsRemoved) {
    _showAds = !premium && !adsRemoved;
  }

  BannerAd? getBannerAd() {
    if (!_showAds) return null;
    // IDs de teste do AdMob. Trocar pelos reais em produção.
    _bannerAd = BannerAd(
      adUnitId: _bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {},
        onAdFailedToLoad: (_, e) {},
      ),
    )..load();
    return _bannerAd;
  }

  void loadInterstitial() {
    if (!_showAds) return;
    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitialAd = ad,
        onAdFailedToLoad: (_) {},
      ),
    );
  }

  void loadRewardedAd() {
    if (!_showAds) return;
    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewardedAd = ad,
        onAdFailedToLoad: (_) {},
      ),
    );
  }

  /// Exibe o anúncio em vídeo (rewarded). Retorna true se o usuário assistiu até o fim e ganhou a recompensa.
  Future<bool> showRewardedAd() async {
    if (!_showAds || _rewardedAd == null) return false;
    final completer = Completer<bool>();
    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        loadRewardedAd();
        if (!completer.isCompleted) completer.complete(false);
      },
    );
    _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        if (!completer.isCompleted) completer.complete(true);
      },
    );
    return completer.future;
  }

  /// Exibe o intersticial (ex.: ao salvar ou ao calcular % gordura). Retorna quando o anúncio for fechado.
  Future<void> showInterstitial() async {
    if (!_showAds || _interstitialAd == null) return;
    await _interstitialAd!.show();
    _interstitialAd = null;
    loadInterstitial(); // pré-carrega próximo
  }

  Future<void> showInterstitialOnSave() async {
    await showInterstitial();
  }

  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
  }
}
