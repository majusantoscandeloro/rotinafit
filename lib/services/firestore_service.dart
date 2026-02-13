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

  Future<bool> isPremium() async {
    final p = await _getPreferences();
    return p['premium'] as bool? ?? false;
  }

  Future<void> setPremium(bool value) async {
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
