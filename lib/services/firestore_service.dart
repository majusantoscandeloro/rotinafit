import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/body_measurements.dart';
import '../models/custom_reminder.dart';
import '../models/reminders_config.dart';
import '../models/water_progress.dart';

/// Serviço de persistência no Firestore. Dados escopados por usuário: `users/{uid}/...`
/// Quando [uid] é null, todos os métodos de leitura retornam valor vazio/default e escritas são no-op.
class FirestoreService {
  FirestoreService([this._uid]);

  final String? _uid;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  String? get uid => _uid;

  bool get isAvailable => _uid != null && _uid.isNotEmpty;

  /// Referência ao documento do usuário (perfil).
  DocumentReference<Map<String, dynamic>>? get _userRef =>
      _uid != null ? _firestore.collection('users').doc(_uid) : null;

  // ---------- Perfil do usuário (criado/atualizado no login) ----------

  /// Cria ou atualiza o documento do usuário no primeiro login/signup.
  Future<void> ensureUserProfile({String? email, String? displayName}) async {
    if (_userRef == null) return;
    final data = <String, dynamic>{
      'email': email,
      'displayName': displayName,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await _userRef!.set(data, SetOptions(merge: true));
    final snap = await _userRef!.get();
    if (snap.data()?['createdAt'] == null) {
      await _userRef!.update({'createdAt': FieldValue.serverTimestamp()});
    }
  }

  // ---------- Medidas (evolução do corpo) ----------

  static const _measurementsPath = 'measurements';

  Future<List<BodyMeasurements>> getMeasurements() async {
    if (_userRef == null) return [];
    final snap = await _userRef!.collection(_measurementsPath).orderBy('monthKey', descending: true).get();
    return snap.docs
        .map((d) => BodyMeasurements.fromJson({...d.data(), 'id': d.id}))
        .toList();
  }

  Future<void> saveMeasurements(List<BodyMeasurements> list) async {
    if (_userRef == null) return;
    final col = _userRef!.collection(_measurementsPath);
    for (final m in list) {
      final data = m.toJson();
      data.remove('id');
      await col.doc(m.id).set(data, SetOptions(merge: true));
    }
    // Remover documentos que não estão mais na lista (opcional: manter histórico completo)
    final existing = await col.get();
    final ids = list.map((e) => e.id).toSet();
    for (final d in existing.docs) {
      if (!ids.contains(d.id)) await d.reference.delete();
    }
  }

  // ---------- Config: lembretes ----------

  Future<RemindersConfig> getRemindersConfig() async {
    if (_userRef == null) return RemindersConfig();
    final snap = await _userRef!.collection('config').doc('reminders').get();
    if (!snap.exists || snap.data() == null) return RemindersConfig();
    return RemindersConfig.fromJson(snap.data()!);
  }

  Future<void> saveRemindersConfig(RemindersConfig config) async {
    if (_userRef == null) return;
    await _userRef!.collection('config').doc('reminders').set(config.toJson(), SetOptions(merge: true));
  }

  // ---------- Config: preferências (premium, IMC, gordura, água) ----------

  Future<Map<String, dynamic>> _getPreferences() async {
    if (_userRef == null) return {};
    final snap = await _userRef!.collection('config').doc('preferences').get();
    return snap.data() ?? {};
  }

  Future<void> _savePreferences(Map<String, dynamic> prefs) async {
    if (_userRef == null) return;
    await _userRef!.collection('config').doc('preferences').set(prefs, SetOptions(merge: true));
  }

  /// Campos de premium no documento do usuário (users/{uid}).
  static const String _userFieldIsPremium = 'isPremium';
  static const String _userFieldPremiumUntil = 'premiumUntil';
  static const String _userFieldProductId = 'productId';
  static const String _userFieldPurchaseId = 'purchaseId';
  static const String _userFieldPlatform = 'platform';
  static const String _userFieldPremiumUpdatedAt = 'premiumUpdatedAt';

  /// Lê isPremium e premiumUntil do documento do usuário.
  /// Retorna null se não houver dados de premium no user doc.
  Future<({bool isPremiumFlag, String? premiumUntil})?> getPremiumFields() async {
    if (_userRef == null) return null;
    final snap = await _userRef!.get();
    final data = snap.data();
    if (data == null || !data.containsKey(_userFieldIsPremium)) return null;
    final flag = data[_userFieldIsPremium] as bool? ?? false;
    final until = data[_userFieldPremiumUntil] as String?;
    return (isPremiumFlag: flag, premiumUntil: until);
  }

  /// isPremium efetivo: flag true E (premiumUntil == null OU now < premiumUntil).
  /// Assinatura expirada (now >= premiumUntil) retorna false.
  Future<bool> isPremium() async {
    final fields = await getPremiumFields();
    if (fields != null) {
      if (!fields.isPremiumFlag) return false;
      if (fields.premiumUntil == null || fields.premiumUntil!.isEmpty) return true;
      final until = DateTime.tryParse(fields.premiumUntil!);
      if (until != null && DateTime.now().isAfter(until)) return false;
      return true;
    }
    final p = await _getPreferences();
    return p['premium'] as bool? ?? false;
  }

  /// Salva status premium completo no documento do usuário e em config/preferences (retrocompat).
  Future<void> setPremiumFromPurchase({
    required bool isPremium,
    String? premiumUntil,
    String? productId,
    String? purchaseId,
    String? platform,
  }) async {
    if (_userRef == null) return;
    final now = FieldValue.serverTimestamp();
    final userData = <String, dynamic>{
      _userFieldIsPremium: isPremium,
      _userFieldPremiumUpdatedAt: now,
    };
    if (isPremium) {
      if (premiumUntil != null) userData[_userFieldPremiumUntil] = premiumUntil;
      if (productId != null) userData[_userFieldProductId] = productId;
      if (purchaseId != null) userData[_userFieldPurchaseId] = purchaseId;
      if (platform != null) userData[_userFieldPlatform] = platform;
    } else {
      userData[_userFieldPremiumUntil] = null;
      userData[_userFieldProductId] = null;
      userData[_userFieldPurchaseId] = null;
      userData[_userFieldPlatform] = null;
    }
    await _userRef!.set(userData, SetOptions(merge: true));
    await _savePreferences({'premium': isPremium});
  }

  Future<void> setPremium(bool value) async {
    if (_userRef != null) {
      final data = <String, dynamic>{
        _userFieldIsPremium: value,
        _userFieldPremiumUpdatedAt: FieldValue.serverTimestamp(),
      };
      if (!value) {
        data[_userFieldPremiumUntil] = null;
        data[_userFieldProductId] = null;
        data[_userFieldPurchaseId] = null;
        data[_userFieldPlatform] = null;
      }
      await _userRef!.set(data, SetOptions(merge: true));
    }
    await _savePreferences({'premium': value});
  }

  Future<String?> getImcFreeViewedMonth() async {
    final p = await _getPreferences();
    return p['imcFreeViewedMonth'] as String?;
  }

  Future<void> setImcFreeViewedMonth(String monthKey) async {
    await _savePreferences({'imcFreeViewedMonth': monthKey});
  }

  Future<String?> getBodyFatUnlockedUntil() async {
    final p = await _getPreferences();
    return p['bodyFatUnlockedUntil'] as String?;
  }

  Future<void> setBodyFatUnlockedUntil(String isoDateTime) async {
    await _savePreferences({'bodyFatUnlockedUntil': isoDateTime});
  }

  Future<String?> getWaterGoalChangeDate() async {
    final p = await _getPreferences();
    return p['waterGoalChangeDate'] as String?;
  }

  Future<int> getWaterGoalChangeCount() async {
    final p = await _getPreferences();
    return (p['waterGoalChangeCount'] as num?)?.toInt() ?? 0;
  }

  Future<void> setWaterGoalChangeForToday(String dateKey, int count) async {
    await _savePreferences({'waterGoalChangeDate': dateKey, 'waterGoalChangeCount': count});
  }

  // ---------- Lembretes personalizados ----------

  static const _customRemindersPath = 'custom_reminders';

  Future<List<CustomReminder>> getCustomReminders() async {
    if (_userRef == null) return [];
    final snap = await _userRef!.collection(_customRemindersPath).get();
    return snap.docs
        .map((d) => CustomReminder.fromJson({...d.data(), 'id': d.id}))
        .toList();
  }

  Future<void> saveCustomReminders(List<CustomReminder> list) async {
    if (_userRef == null) return;
    final col = _userRef!.collection(_customRemindersPath);
    for (final r in list) {
      final data = r.toJson();
      data.remove('id');
      await col.doc(r.id).set(data, SetOptions(merge: true));
    }
    final existing = await col.get();
    final ids = list.map((e) => e.id).toSet();
    for (final d in existing.docs) {
      if (!ids.contains(d.id)) await d.reference.delete();
    }
  }

  // ---------- Água (progresso por dia) ----------

  static const _waterProgressPath = 'water_progress';

  Future<Map<String, WaterProgress>> getWaterProgress() async {
    if (_userRef == null) return {};
    final snap = await _userRef!.collection(_waterProgressPath).get();
    final map = <String, WaterProgress>{};
    for (final d in snap.docs) {
      map[d.id] = WaterProgress.fromJson({...d.data(), 'dateKey': d.id});
    }
    return map;
  }

  Future<void> saveWaterProgress(Map<String, WaterProgress> map) async {
    if (_userRef == null) return;
    final col = _userRef!.collection(_waterProgressPath);
    for (final e in map.entries) {
      final data = e.value.toJson();
      data.remove('dateKey');
      await col.doc(e.key).set(data, SetOptions(merge: true));
    }
  }
}
