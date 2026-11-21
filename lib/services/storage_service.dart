import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/account_info.dart';
import '../models/diary_entry.dart';
import '../models/skinfold_record.dart';
import '../models/user_profile.dart';
import '../models/weight_record.dart';

/// Persistência local simples, em JSON, sem sincronização com servidores.
class StorageService {
  static const _entriesKey = 'nutridobra.entries.v1';
  static const _profileKey = 'nutridobra.profile.v1';
  static const _apiKeyKey = 'nutridobra.usda.apikey.v1';
  static const _accountKey = 'nutridobra.account.v1';
  static const _skinfoldHistoryKey = 'nutridobra.skinfold.history.v1';
  static const _weightHistoryKey = 'nutridobra.weight.history.v1';

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

  String? getUsdaApiKey() => _prefs.getString(_apiKeyKey);

  Future<bool> setUsdaApiKey(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return _prefs.remove(_apiKeyKey);
    return _prefs.setString(_apiKeyKey, trimmed);
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
}
