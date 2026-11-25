import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/account_info.dart';
import '../models/body_measure_record.dart';
import '../models/custom_meal.dart';
import '../models/diary_entry.dart';
import '../models/food_item.dart';
import '../models/skinfold_record.dart';
import '../models/user_profile.dart';
import '../models/weight_record.dart';

/// Persistência local simples, em JSON, sem sincronização com servidores.
class StorageService {
  static const _entriesKey = 'nutridobra.entries.v1';
  static const _profileKey = 'nutridobra.profile.v1';
  static const _accountKey = 'nutridobra.account.v1';
  static const _skinfoldHistoryKey = 'nutridobra.skinfold.history.v1';
  static const _bodyMeasuresKey = 'nutridobra.body.measures.v1';
  static const _weightHistoryKey = 'nutridobra.weight.history.v1';
  static const _customFoodsKey = 'nutridobra.custom.foods.v1';
  static const _customMealsKey = 'nutridobra.custom.meals.v1';
  static const _remoteCatalogKey = 'nutridobra.remote.catalog.v1';
  static const _waterKey = 'nutridobra.water.v1';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> create() async {
    return StorageService(await SharedPreferences.getInstance());
  }

  List<DiaryEntry> getEntries() {
    final raw = _prefs.getString(_entriesKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(DiaryEntry.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> saveEntries(List<DiaryEntry> entries) {
    return _prefs.setString(
      _entriesKey,
      jsonEncode(entries.map((e) => e.toJson()).toList()),
    );
  }

  UserProfile getProfile() {
    final raw = _prefs.getString(_profileKey);
    if (raw == null || raw.isEmpty) return const UserProfile();
    try {
      return UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const UserProfile();
    }
  }

  Future<bool> saveProfile(UserProfile profile) {
    return _prefs.setString(_profileKey, jsonEncode(profile.toJson()));
  }

  AccountInfo? getAccount() {
    final raw = _prefs.getString(_accountKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return AccountInfo.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<bool> saveAccount(AccountInfo account) {
    return _prefs.setString(_accountKey, jsonEncode(account.toJson()));
  }

  Future<bool> clearAccount() => _prefs.remove(_accountKey);

  List<SkinfoldRecord> getSkinfoldHistory() {
    final raw = _prefs.getString(_skinfoldHistoryKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(SkinfoldRecord.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> saveSkinfoldHistory(List<SkinfoldRecord> records) {
    return _prefs.setString(
      _skinfoldHistoryKey,
      jsonEncode(records.map((r) => r.toJson()).toList()),
    );
  }

  List<BodyMeasureRecord> getBodyMeasures() {
    final raw = _prefs.getString(_bodyMeasuresKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(BodyMeasureRecord.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> saveBodyMeasures(List<BodyMeasureRecord> records) {
    return _prefs.setString(
      _bodyMeasuresKey,
      jsonEncode(records.map((r) => r.toJson()).toList()),
    );
  }

  List<WeightRecord> getWeightHistory() {
    final raw = _prefs.getString(_weightHistoryKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(WeightRecord.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> saveWeightHistory(List<WeightRecord> records) {
    return _prefs.setString(
      _weightHistoryKey,
      jsonEncode(records.map((r) => r.toJson()).toList()),
    );
  }

  List<FoodItem> getCustomFoods() {
    final raw = _prefs.getString(_customFoodsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(FoodItem.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> saveCustomFoods(List<FoodItem> foods) {
    return _prefs.setString(
      _customFoodsKey,
      jsonEncode(foods.map((f) => f.toJson()).toList()),
    );
  }

  /// Slots de refeições personalizadas. Quatro vagas são criadas vazias e
  /// desativadas: só aparecem no diário depois que o usuário as configura.
  List<CustomMeal> getCustomMeals() {
    final defaults = List<CustomMeal>.generate(
      4,
      (i) => CustomMeal(key: 'custom${i + 1}', name: '', enabled: false),
    );
    final raw = _prefs.getString(_customMealsKey);
    if (raw == null || raw.isEmpty) return defaults;
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      final saved = decoded
          .whereType<Map<String, dynamic>>()
          .map(CustomMeal.fromJson)
          .toList();
      for (var i = 0; i < defaults.length; i++) {
        if (i < saved.length && saved[i].key == defaults[i].key) {
          defaults[i] = saved[i];
        }
      }
      return defaults;
    } catch (_) {
      return defaults;
    }
  }

  Future<bool> saveCustomMeals(List<CustomMeal> meals) {
    return _prefs.setString(
      _customMealsKey,
      jsonEncode(meals.map((m) => m.toJson()).toList()),
    );
  }

  /// Cópia local do catálogo remoto, usada quando não há internet.
  List<FoodItem> getRemoteCatalog() {
    final raw = _prefs.getString(_remoteCatalogKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(FoodItem.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> saveRemoteCatalog(String json) =>
      _prefs.setString(_remoteCatalogKey, json);

  /// Mililitros de água por data (yyyy-MM-dd).
  Map<String, double> getWater() {
    final raw = _prefs.getString(_waterKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      );
    } catch (_) {
      return {};
    }
  }

  Future<bool> saveWater(Map<String, double> water) {
    return _prefs.setString(_waterKey, jsonEncode(water));
  }
}
