import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/body_measurements.dart';
import '../models/custom_reminder.dart';
import '../models/reminders_config.dart';
import '../models/water_progress.dart';

class StorageService {
  static const _keyMeasurements = 'rotinafit_measurements';
  static const _keyReminders = 'rotinafit_reminders';
  static const _keyCustomReminders = 'rotinafit_custom_reminders';
  static const _keyWater = 'rotinafit_water';
  static const _keyPremium = 'rotinafit_premium';
  static const _keyAdsRemoved = 'rotinafit_ads_removed';
  static const _keyImcFreeViewedMonth = 'rotinafit_imc_free_viewed_month';

  Future<List<BodyMeasurements>> getMeasurements() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_keyMeasurements);
    if (list == null) return [];
    return list
        .map((s) => BodyMeasurements.fromJson(
            jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveMeasurements(List<BodyMeasurements> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _keyMeasurements,
      list.map((m) => jsonEncode(m.toJson())).toList(),
    );
  }

  Future<RemindersConfig> getRemindersConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(_keyReminders);
    if (s == null) return RemindersConfig();
    return RemindersConfig.fromJson(
        jsonDecode(s) as Map<String, dynamic>);
  }

  Future<void> saveRemindersConfig(RemindersConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyReminders, jsonEncode(config.toJson()));
  }

  Future<List<CustomReminder>> getCustomReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_keyCustomReminders);
    if (list == null) return [];
    return list
        .map((s) => CustomReminder.fromJson(
            jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveCustomReminders(List<CustomReminder> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _keyCustomReminders,
      list.map((r) => jsonEncode(r.toJson())).toList(),
    );
  }

  Future<Map<String, WaterProgress>> getWaterProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(_keyWater);
    if (s == null) return {};
    final map = jsonDecode(s) as Map<String, dynamic>;
    return map.map((k, v) =>
        MapEntry(k, WaterProgress.fromJson(v as Map<String, dynamic>)));
  }

  Future<void> saveWaterProgress(Map<String, WaterProgress> map) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyWater,
        jsonEncode(map.map((k, v) => MapEntry(k, v.toJson()))));
  }

  Future<bool> isPremium() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyPremium) ?? false;
  }

  Future<void> setPremium(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPremium, value);
  }

  Future<bool> isAdsRemoved() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyAdsRemoved) ?? false;
  }

  Future<void> setAdsRemoved(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAdsRemoved, value);
  }

  Future<String?> getImcFreeViewedMonth() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyImcFreeViewedMonth);
  }

  Future<void> setImcFreeViewedMonth(String monthKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyImcFreeViewedMonth, monthKey);
  }
}
