import 'package:flutter/foundation.dart';
import '../models/body_measurements.dart';
import '../models/custom_reminder.dart';
import '../models/reminders_config.dart';
import '../models/water_progress.dart';
import '../services/storage_service.dart';
import '../services/notifications_service.dart';
import '../services/ads_service.dart';

enum Plan { free, premium, adsRemoved }

/// No plano free: só pode criar 1 lembrete personalizado e precisa assistir vídeo.
const int freePlanMaxCustomReminders = 1;

class AppProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final AdsService _ads = AdsService();

  List<BodyMeasurements> _measurements = [];
  RemindersConfig _reminders = RemindersConfig();
  List<CustomReminder> _customReminders = [];
  Map<String, WaterProgress> _waterProgress = {};
  bool _isPremium = false;
  bool _adsRemoved = false;
  bool _loading = true;
  String? _imcFreeViewedMonth;

  List<BodyMeasurements> get measurements => _measurements;
  RemindersConfig get reminders => _reminders;
  List<CustomReminder> get customReminders => _customReminders;
  Map<String, WaterProgress> get waterProgress => _waterProgress;
  bool get isPremium => _isPremium;
  bool get adsRemoved => _adsRemoved;
  bool get loading => _loading;
  bool get showAds => _ads.showAds;

  /// Plano free (com ou sem anúncios): máximo 1 lembrete personalizado. Premium: ilimitado.
  bool get canAddCustomReminder {
    if (_isPremium) return true;
    return _customReminders.length < freePlanMaxCustomReminders;
  }

  /// Para criar no plano free precisa assistir ao vídeo.
  bool get mustWatchAdToAddCustomReminder {
    return !_isPremium && !_adsRemoved && _customReminders.length < freePlanMaxCustomReminders;
  }

  Plan get plan {
    if (_isPremium) return Plan.premium;
    if (_adsRemoved) return Plan.adsRemoved;
    return Plan.free;
  }

  bool get canSeeHistory => _isPremium;
  bool get canSeeCharts => _isPremium;
  bool get canComparePreviousMonth => _isPremium;

  /// No plano free, IMC só pode ser visualizado uma vez por mês.
  bool get canViewImcThisMonth {
    if (_isPremium) return true;
    final now = DateTime.now();
    final key = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    return _imcFreeViewedMonth != key;
  }

  Future<void> markImcViewedThisMonth() async {
    if (_isPremium) return;
    final now = DateTime.now();
    final key = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    if (_imcFreeViewedMonth == key) return;
    _imcFreeViewedMonth = key;
    await _storage.setImcFreeViewedMonth(key);
    notifyListeners();
  }

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _measurements = await _storage.getMeasurements();
    _reminders = await _storage.getRemindersConfig();
    _customReminders = await _storage.getCustomReminders();
    _waterProgress = await _storage.getWaterProgress();
    _isPremium = await _storage.isPremium();
    _adsRemoved = await _storage.isAdsRemoved();
    _imcFreeViewedMonth = await _storage.getImcFreeViewedMonth();
    try {
      await _ads.init();
    } catch (_) {}
    _ads.updateShowAds(_isPremium, _adsRemoved);
    _ads.loadInterstitial();
    try {
      await NotificationsService.init();
      if (_reminders.notificationsEnabled) {
        await NotificationsService.applyConfig(_reminders, _customReminders);
      } else {
        await NotificationsService.applyCustomRemindersOnly(_customReminders);
      }
    } catch (_) {}
    _loading = false;
    notifyListeners();
  }

  BodyMeasurements? getCurrentMonthMeasurements() {
    final now = DateTime.now();
    final key = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    // Pega sempre o check-in MAIS RECENTE do mês atual (se houver vários).
    for (final m in _measurements.reversed) {
      if (m.monthKey == key) return m;
    }
    // Se não houver nada no mês atual, cai para o último check-in salvo.
    if (_measurements.isEmpty) return null;
    return _measurements.last;
  }

  List<BodyMeasurements> getMeasurementsForHistory() {
    return List.from(_measurements)
      ..sort((a, b) => b.monthKey.compareTo(a.monthKey));
  }

  BodyMeasurements? getPreviousMonthMeasurements(String monthKey) {
    final parts = monthKey.split('-');
    if (parts.length != 2) return null;
    var y = int.tryParse(parts[0]) ?? 0;
    var m = int.tryParse(parts[1]) ?? 0;
    m--;
    if (m < 1) {
      m = 12;
      y--;
    }
    final prevKey = '$y-${m.toString().padLeft(2, '0')}';
    // Para comparação, usa o ÚLTIMO check-in registrado do mês anterior.
    for (final bm in _measurements.reversed) {
      if (bm.monthKey == prevKey) return bm;
    }
    return null;
  }

  WaterProgress getTodayWater() {
    final now = DateTime.now();
    final key =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return _waterProgress[key] ?? WaterProgress(dateKey: key);
  }

  Future<void> addWaterGlass() async {
    final w = getTodayWater();
    w.currentGlasses = (w.currentGlasses + 1).clamp(0, 99);
    _waterProgress[w.dateKey] = w;
    await _storage.saveWaterProgress(_waterProgress);
    notifyListeners();
  }

  Future<void> removeWaterGlass() async {
    final w = getTodayWater();
    w.currentGlasses = (w.currentGlasses - 1).clamp(0, 99);
    _waterProgress[w.dateKey] = w;
    await _storage.saveWaterProgress(_waterProgress);
    notifyListeners();
  }

  Future<void> setWaterGoal(int glasses) async {
    final w = getTodayWater();
    w.goalGlasses = glasses.clamp(1, 20);
    _waterProgress[w.dateKey] = w;
    await _storage.saveWaterProgress(_waterProgress);
    notifyListeners();
  }

  /// Marca a meta do dia como completa (current = goal).
  Future<void> completeWaterGoal() async {
    final w = getTodayWater();
    w.currentGlasses = w.goalGlasses;
    _waterProgress[w.dateKey] = w;
    await _storage.saveWaterProgress(_waterProgress);
    notifyListeners();
  }

  Future<void> saveMeasurements(BodyMeasurements m) async {
    final existing = _measurements.indexWhere((e) => e.id == m.id);
    if (existing >= 0) {
      _measurements[existing] = m;
    } else {
      _measurements.add(m);
    }
    await _storage.saveMeasurements(_measurements);
    notifyListeners();
  }

  Future<void> updateReminders(RemindersConfig config) async {
    _reminders = config;
    await _storage.saveRemindersConfig(_reminders);
    try {
      if (_reminders.notificationsEnabled) {
        await NotificationsService.applyConfig(_reminders, _customReminders);
      } else {
        await NotificationsService.applyCustomRemindersOnly(_customReminders);
      }
    } catch (_) {
      // Ex.: exact_alarms_not_permitted no Android 14+; horários são salvos mesmo assim
    }
    notifyListeners();
  }

  Future<String?> addCustomReminder(CustomReminder reminder) async {
    if (!canAddCustomReminder) return 'Plano gratuito permite apenas $freePlanMaxCustomReminders lembrete personalizado.';
    _customReminders.add(reminder);
    await _storage.saveCustomReminders(_customReminders);
    try {
      await NotificationsService.applyCustomRemindersOnly(_customReminders);
    } catch (_) {}
    notifyListeners();
    return null;
  }

  Future<void> updateCustomReminder(CustomReminder reminder) async {
    final i = _customReminders.indexWhere((r) => r.id == reminder.id);
    if (i >= 0) {
      _customReminders[i] = reminder;
      await _storage.saveCustomReminders(_customReminders);
      try {
        await NotificationsService.applyCustomRemindersOnly(_customReminders);
      } catch (_) {}
      notifyListeners();
    }
  }

  Future<void> removeCustomReminder(String id) async {
    _customReminders.removeWhere((r) => r.id == id);
    await _storage.saveCustomReminders(_customReminders);
    try {
      await NotificationsService.applyCustomRemindersOnly(_customReminders);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> setPremium(bool value) async {
    _isPremium = value;
    await _storage.setPremium(value);
    _ads.updateShowAds(_isPremium, _adsRemoved);
    notifyListeners();
  }

  Future<void> setAdsRemoved(bool value) async {
    _adsRemoved = value;
    await _storage.setAdsRemoved(value);
    _ads.updateShowAds(_isPremium, _adsRemoved);
    notifyListeners();
  }

  Future<void> showInterstitialOnSave() async {
    await _ads.showInterstitialOnSave();
  }

  /// Exibe intersticial (ex.: ao calcular % gordura). Retorna quando o anúncio for fechado.
  Future<void> showInterstitial() async {
    await _ads.showInterstitial();
  }

  /// Exibe anúncio em vídeo (rewarded). Retorna true se o usuário assistiu até o fim.
  Future<bool> showRewardedAd() async {
    return _ads.showRewardedAd();
  }

  void loadInterstitial() {
    _ads.loadInterstitial();
  }
}
