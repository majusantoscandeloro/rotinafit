import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'storage_service.dart';

/// Banner: produção RotinaFit_Banner_Home; debug usa IDs de teste.
String get _bannerAdUnitId {
  if (Platform.isIOS) {
    if (kDebugMode) return 'ca-app-pub-3940256099942544/2934735716'; // teste iOS
    return 'ca-app-pub-7050795334686713/5544912937'; // RotinaFit_Banner_Home (iOS produção)
  }
  if (kDebugMode) return 'ca-app-pub-3940256099942544/6300978111'; // teste Android
  return 'ca-app-pub-7050795334686713/9711388654'; // RotinaFit_Banner_Home (Android produção)
}
/// Rewarded água: produção RotinaFit_Rewarded_WaterGoal; debug usa teste.
String get _rewardedWaterGoalAdUnitId {
  if (Platform.isIOS) {
    if (kDebugMode) return 'ca-app-pub-3940256099942544/1712485313'; // teste iOS
    return 'ca-app-pub-7050795334686713/3030430231'; // RotinaFit_Rewarded_WaterGoal (iOS produção)
  }
  if (kDebugMode) return 'ca-app-pub-3940256099942544/5224354917'; // teste Android
  return 'ca-app-pub-7050795334686713/8295189610'; // RotinaFit_Rewarded_WaterGoal (Android produção)
}
/// Rewarded % gordura: produção RotinaFit_Rewarded_BodyFat; debug usa teste.
String get _rewardedBodyFatAdUnitId {
  if (Platform.isIOS) {
    if (kDebugMode) return 'ca-app-pub-3940256099942544/1712485313'; // teste iOS
    return 'ca-app-pub-7050795334686713/1661508248'; // RotinaFit_Rewarded_BodyFat (iOS produção)
  }
  if (kDebugMode) return 'ca-app-pub-3940256099942544/5224354917'; // teste Android
  return 'ca-app-pub-7050795334686713/9595838580'; // RotinaFit_Rewarded_BodyFat (Android produção)
}
/// Rewarded lembretes personalizados: produção RotinaFit_Rewarded_CustomReminder; debug usa teste.
String get _rewardedCustomReminderAdUnitId {
  if (Platform.isIOS) {
    if (kDebugMode) return 'ca-app-pub-3940256099942544/1712485313'; // teste iOS
    return 'ca-app-pub-7050795334686713/2191991286'; // RotinaFit_Rewarded_CustomReminder (iOS produção)
  }
  if (kDebugMode) return 'ca-app-pub-3940256099942544/5224354917'; // teste Android
  return 'ca-app-pub-7050795334686713/4020078277'; // RotinaFit_Rewarded_CustomReminder (Android produção)
}

/// Serviço de anúncios. Banner e rewarded (vídeo para ganhar recompensa).
/// Free = com anúncios; Premium = sem anúncios.
class AdsService {
  final StorageService _storage = StorageService();

  BannerAd? _bannerAd;
  RewardedAd? _rewardedWaterAd;
  RewardedAd? _rewardedBodyFatAd;
  RewardedAd? _rewardedCustomReminderAd;
  bool _showAds = true;

  bool get showAds => _showAds;

  /// Premium = sem anúncios: não inicializa SDK nem carrega nenhum ad (banner/rewarded).
  Future<void> init() async {
    final premium = await _storage.isPremium();
    _showAds = !premium;
    if (premium) return;
    await MobileAds.instance.initialize();
    loadRewardedWaterAd();
    loadRewardedBodyFatAd();
    loadRewardedCustomReminderAd();
  }

  void updateShowAds(bool premium) {
    _showAds = !premium;
  }

  /// Uma única instância de banner (cache). Criada uma vez, reutilizada, dispose no dispose().
  BannerAd? getOrCreateBannerAd() {
    if (!_showAds) return null;
    if (_bannerAd != null) return _bannerAd;
    _bannerAd = BannerAd(
      adUnitId: _bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {},
        onAdFailedToLoad: (_, e) {},
      ),
    );
    _bannerAd!.load();
    return _bannerAd;
  }

  /// Widget do banner para usar na UI (Home rodapé, etc). Reutiliza a mesma instância.
  Widget getBannerWidget() {
    final ad = getOrCreateBannerAd();
    if (ad == null) return const SizedBox.shrink();
    return SizedBox(
      width: ad.size.width.toDouble(),
      height: ad.size.height.toDouble(),
      child: AdWidget(ad: ad),
    );
  }

  void loadRewardedWaterAd() {
    if (!_showAds) return;
    RewardedAd.load(
      adUnitId: _rewardedWaterGoalAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewardedWaterAd = ad,
        onAdFailedToLoad: (_) {},
      ),
    );
  }

  void loadRewardedBodyFatAd() {
    if (!_showAds) return;
    RewardedAd.load(
      adUnitId: _rewardedBodyFatAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewardedBodyFatAd = ad,
        onAdFailedToLoad: (_) {},
      ),
    );
  }

  void loadRewardedCustomReminderAd() {
    if (!_showAds) return;
    RewardedAd.load(
      adUnitId: _rewardedCustomReminderAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewardedCustomReminderAd = ad,
        onAdFailedToLoad: (_) {},
      ),
    );
  }

  /// Exibe o anúncio em vídeo (rewarded). [forBodyFat] = RotinaFit_Rewarded_BodyFat, [forCustomReminder] = CustomReminder, senão = WaterGoal.
  /// Retorna true se o usuário assistiu até o fim e ganhou a recompensa.
  Future<bool> showRewardedAd({bool forBodyFat = false, bool forCustomReminder = false}) async {
    final RewardedAd? ad = forCustomReminder
        ? _rewardedCustomReminderAd
        : (forBodyFat ? _rewardedBodyFatAd : _rewardedWaterAd);
    if (!_showAds || ad == null) return false;
    final completer = Completer<bool>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        if (forCustomReminder) {
          _rewardedCustomReminderAd = null;
          loadRewardedCustomReminderAd();
        } else if (forBodyFat) {
          _rewardedBodyFatAd = null;
          loadRewardedBodyFatAd();
        } else {
          _rewardedWaterAd = null;
          loadRewardedWaterAd();
        }
        if (!completer.isCompleted) completer.complete(false);
      },
    );
    ad.show(
      onUserEarnedReward: (_, __) {
        if (!completer.isCompleted) completer.complete(true);
      },
    );
    return completer.future;
  }

  void dispose() {
    _bannerAd?.dispose();
    _rewardedWaterAd?.dispose();
    _rewardedBodyFatAd?.dispose();
    _rewardedCustomReminderAd?.dispose();
  }
}
