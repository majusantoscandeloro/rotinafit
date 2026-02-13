import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../models/body_measurements.dart';
import '../models/custom_reminder.dart';
import '../models/reminders_config.dart';
import '../models/water_progress.dart';
import '../services/storage_service.dart';
import '../services/firestore_service.dart';
import '../services/notifications_service.dart';
import '../services/ads_service.dart';

enum Plan { free, premium }

/// No plano free: só pode criar 1 lembrete personalizado e precisa assistir vídeo.
const int freePlanMaxCustomReminders = 1;

class AppProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final AdsService _ads = AdsService();
  FirestoreService? _firestore;
  String? _lastLoadedUid;
  StreamSubscription<User?>? _authSubscription;

  AppProvider() {
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((User? user) {
      final newUid = user?.uid;
      if (newUid != _lastLoadedUid) load();
    });
  }

  List<BodyMeasurements> _measurements = [];
  RemindersConfig _reminders = RemindersConfig();
  List<CustomReminder> _customReminders = [];
  Map<String, WaterProgress> _waterProgress = {};
  bool _isPremium = false;
  bool _loading = true;
  String? _imcFreeViewedMonth;
  String? _bodyFatUnlockedUntil;
  String? _waterGoalChangeDate;
  int _waterGoalChangeCount = 0;

  List<BodyMeasurements> get measurements => _measurements;
  RemindersConfig get reminders => _reminders;
  List<CustomReminder> get customReminders => _customReminders;
  Map<String, WaterProgress> get waterProgress => _waterProgress;
  bool get isPremium => _isPremium;
  bool get loading => _loading;
  bool get showAds => _ads.showAds;

  /// Plano free: máximo 1 lembrete personalizado. Premium: ilimitado.
  bool get canAddCustomReminder {
    if (_isPremium) return true;
    return _customReminders.length < freePlanMaxCustomReminders;
  }

  /// No plano free, para criar lembrete extra precisa assistir ao vídeo.
  bool get mustWatchAdToAddCustomReminder {
    return !_isPremium && _customReminders.length < freePlanMaxCustomReminders;
  }

  Plan get plan => _isPremium ? Plan.premium : Plan.free;

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

  void _normalizeWaterGoalChangeCountForToday() {
    final now = DateTime.now();
    final todayKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    if (_waterGoalChangeDate != todayKey) {
      _waterGoalChangeDate = todayKey;
      _waterGoalChangeCount = 0;
    }
  }

  /// Pode ver % gordura sem anúncio: premium ou desbloqueado por 24h (rewarded).
  bool get canViewBodyFatWithoutAd {
    if (_isPremium) return true;
    if (_bodyFatUnlockedUntil == null) return false;
    final until = DateTime.tryParse(_bodyFatUnlockedUntil!);
    return until != null && DateTime.now().isBefore(until);
  }

  Future<void> unlockBodyFatFor24Hours() async {
    final until = DateTime.now().add(const Duration(hours: 24));
    _bodyFatUnlockedUntil = until.toIso8601String();
    if (_firestore != null) {
      await _firestore!.setBodyFatUnlockedUntil(_bodyFatUnlockedUntil!);
    } else {
      await _storage.setBodyFatUnlockedUntil(_bodyFatUnlockedUntil!);
    }
    notifyListeners();
  }

  /// Quantas vezes o usuário free já alterou a meta de água hoje (1ª é grátis, depois rewarded).
  int get waterGoalChangesToday {
    _normalizeWaterGoalChangeCountForToday();
    return _waterGoalChangeCount;
  }

  bool get canChangeWaterGoalForFree {
    if (_isPremium) return true;
    return waterGoalChangesToday == 0;
  }

  Future<void> recordWaterGoalChange() async {
    _normalizeWaterGoalChangeCountForToday();
    final now = DateTime.now();
    final todayKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    _waterGoalChangeDate = todayKey;
    _waterGoalChangeCount++;
    if (_firestore != null) {
      await _firestore!.setWaterGoalChangeForToday(todayKey, _waterGoalChangeCount);
    } else {
      await _storage.setWaterGoalChangeForToday(todayKey, _waterGoalChangeCount);
    }
    notifyListeners();
  }

  Widget getBannerWidget() => _ads.getBannerWidget();

  Future<void> markImcViewedThisMonth() async {
    if (_isPremium) return;
    final now = DateTime.now();
    final key = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    if (_imcFreeViewedMonth == key) return;
    _imcFreeViewedMonth = key;
    if (_firestore != null) {
      await _firestore!.setImcFreeViewedMonth(key);
    } else {
      await _storage.setImcFreeViewedMonth(key);
    }
    notifyListeners();
  }

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    _firestore = uid != null ? FirestoreService(uid) : null;
    if (_firestore != null) {
      await _firestore!.ensureUserProfile(
        email: FirebaseAuth.instance.currentUser?.email,
        displayName: FirebaseAuth.instance.currentUser?.displayName,
      );
      _measurements = await _firestore!.getMeasurements();
      _reminders = await _firestore!.getRemindersConfig();
      _customReminders = await _firestore!.getCustomReminders();
      _waterProgress = await _firestore!.getWaterProgress();
      _isPremium = await _firestore!.isPremium();
      _imcFreeViewedMonth = await _firestore!.getImcFreeViewedMonth();
      _bodyFatUnlockedUntil = await _firestore!.getBodyFatUnlockedUntil();
      _waterGoalChangeDate = await _firestore!.getWaterGoalChangeDate();
      _waterGoalChangeCount = await _firestore!.getWaterGoalChangeCount();
    } else {
      _measurements = await _storage.getMeasurements();
      _reminders = await _storage.getRemindersConfig();
      _customReminders = await _storage.getCustomReminders();
      _waterProgress = await _storage.getWaterProgress();
      _isPremium = await _storage.isPremium();
      _imcFreeViewedMonth = await _storage.getImcFreeViewedMonth();
      _bodyFatUnlockedUntil = await _storage.getBodyFatUnlockedUntil();
      _waterGoalChangeDate = await _storage.getWaterGoalChangeDate();
      _waterGoalChangeCount = await _storage.getWaterGoalChangeCount();
    }
    _normalizeWaterGoalChangeCountForToday();
    try {
      await _ads.init();
    } catch (_) {}
    _ads.updateShowAds(_isPremium);
    _ads.loadInterstitial();
    try {
      await NotificationsService.init();
      if (_reminders.notificationsEnabled) {
        await NotificationsService.applyConfig(_reminders, _customReminders);
      } else {
        await NotificationsService.applyCustomRemindersOnly(_customReminders);
      }
    } catch (_) {}
    _lastLoadedUid = uid;
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
    if (_firestore != null) {
      await _firestore!.saveWaterProgress(_waterProgress);
    } else {
      await _storage.saveWaterProgress(_waterProgress);
    }
    notifyListeners();
  }

  Future<void> removeWaterGlass() async {
    final w = getTodayWater();
    w.currentGlasses = (w.currentGlasses - 1).clamp(0, 99);
    _waterProgress[w.dateKey] = w;
    if (_firestore != null) {
      await _firestore!.saveWaterProgress(_waterProgress);
    } else {
      await _storage.saveWaterProgress(_waterProgress);
    }
    notifyListeners();
  }

  Future<void> setWaterGoal(int glasses) async {
    final w = getTodayWater();
    w.goalGlasses = glasses.clamp(1, 20);
    _waterProgress[w.dateKey] = w;
    if (_firestore != null) {
      await _firestore!.saveWaterProgress(_waterProgress);
    } else {
      await _storage.saveWaterProgress(_waterProgress);
    }
    notifyListeners();
  }

  /// Marca a meta do dia como completa (current = goal).
  Future<void> completeWaterGoal() async {
    final w = getTodayWater();
    w.currentGlasses = w.goalGlasses;
    _waterProgress[w.dateKey] = w;
    if (_firestore != null) {
      await _firestore!.saveWaterProgress(_waterProgress);
    } else {
      await _storage.saveWaterProgress(_waterProgress);
    }
    notifyListeners();
  }

  Future<void> saveMeasurements(BodyMeasurements m) async {
    final existing = _measurements.indexWhere((e) => e.id == m.id);
    if (existing >= 0) {
      _measurements[existing] = m;
    } else {
      _measurements.add(m);
    }
    if (_firestore != null) {
      await _firestore!.saveMeasurements(_measurements);
    } else {
      await _storage.saveMeasurements(_measurements);
    }
    notifyListeners();
  }

  Future<void> updateReminders(RemindersConfig config) async {
    _reminders = config;
    if (_firestore != null) {
      await _firestore!.saveRemindersConfig(_reminders);
    } else {
      await _storage.saveRemindersConfig(_reminders);
    }
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
    if (_firestore != null) {
      await _firestore!.saveCustomReminders(_customReminders);
    } else {
      await _storage.saveCustomReminders(_customReminders);
    }
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
      if (_firestore != null) {
        await _firestore!.saveCustomReminders(_customReminders);
      } else {
        await _storage.saveCustomReminders(_customReminders);
      }
      try {
        await NotificationsService.applyCustomRemindersOnly(_customReminders);
      } catch (_) {}
      notifyListeners();
    }
  }

  Future<void> removeCustomReminder(String id) async {
    _customReminders.removeWhere((r) => r.id == id);
    if (_firestore != null) {
      await _firestore!.saveCustomReminders(_customReminders);
    } else {
      await _storage.saveCustomReminders(_customReminders);
    }
    try {
      await NotificationsService.applyCustomRemindersOnly(_customReminders);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> setPremium(bool value) async {
    _isPremium = value;
    if (_firestore != null) {
      await _firestore!.setPremium(value);
    } else {
      await _storage.setPremium(value);
    }
    _ads.updateShowAds(_isPremium);
    notifyListeners();
  }

  Future<void> showInterstitialOnSave() async {
    await _ads.showInterstitialOnSave();
  }

  /// Exibe intersticial (ex.: ao calcular % gordura). Retorna quando o anúncio for fechado.
  Future<void> showInterstitial() async {
    await _ads.showInterstitial();
  }

  /// Exibe anúncio em vídeo (rewarded). [forBodyFat] = BodyFat, [forCustomReminder] = CustomReminder, senão = WaterGoal. Retorna true se assistiu até o fim.
  Future<bool> showRewardedAd({bool forBodyFat = false, bool forCustomReminder = false}) async {
    return _ads.showRewardedAd(forBodyFat: forBodyFat, forCustomReminder: forCustomReminder);
  }

  void loadInterstitial() {
    _ads.loadInterstitial();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
