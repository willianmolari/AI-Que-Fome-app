import 'dart:convert';

import 'package:flutter/material.dart';

import '../data/food_catalog.dart';
import '../models/account_info.dart';
import '../models/body_measure_record.dart';
import '../models/custom_meal.dart';
import '../models/diary_entry.dart';
import '../models/food_item.dart';
import '../models/skinfold_record.dart';
import '../models/user_profile.dart';
import '../models/weight_record.dart';
import '../services/catalog_sync_service.dart';
import '../services/storage_service.dart';

/// Estado compartilhado do app. Toda persistência passa por aqui.
class AppState extends ChangeNotifier {
  AppState(this._storage);

  final StorageService _storage;

  late List<DiaryEntry> _entries;
  late List<SkinfoldRecord> _skinfoldHistory;
  late List<BodyMeasureRecord> _bodyMeasures;
  late List<WeightRecord> _weightHistory;
  late List<FoodItem> _customFoods;
  late List<FoodItem> _remoteFoods;
  late List<CustomMeal> _customMeals;
  late Map<String, double> _waterByDate;
  late UserProfile _profile;
  AccountInfo? _account;

  static const meals = [
    ('cafe', 'Café da manhã'),
    ('almoco', 'Almoço'),
    ('jantar', 'Jantar'),
    ('lanches', 'Lanches'),
  ];

  /// Refeições exibidas no diário: as quatro padrão mais as personalizadas
  /// que o usuário nomeou e ativou.
  List<(String, String)> get availableMeals => [
    ...meals,
    for (final meal in _customMeals.where((m) => m.isAvailable))
      (meal.key, meal.name.trim()),
  ];

  List<DiaryEntry> get entries => List.unmodifiable(_entries);
  List<SkinfoldRecord> get skinfoldHistory {
    final sorted = [..._skinfoldHistory]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(sorted);
  }

  /// Circunferências salvas, do mais recente para o mais antigo.
  List<BodyMeasureRecord> get bodyMeasures {
    final sorted = [..._bodyMeasures]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(sorted);
  }

  /// Histórico do mais recente para o mais antigo (usado no gráfico).
  List<WeightRecord> get weightHistory {
    final sorted = [..._weightHistory]
      ..sort((a, b) => a.date.compareTo(b.date));
    return List.unmodifiable(sorted);
  }

  /// Alimentos cadastrados pelo usuário, reutilizáveis no catálogo.
  List<FoodItem> get customFoods => List.unmodifiable(_customFoods);

  /// Alimentos vindos do JSON público do GitHub, já sem duplicatas do catálogo
  /// interno. Continua disponível offline via cache local.
  List<FoodItem> get remoteFoods => List.unmodifiable(_remoteFoods);

  /// Slots de refeições personalizadas, inclusive os ainda não ativados.
  List<CustomMeal> get customMeals => List.unmodifiable(_customMeals);

  UserProfile get profile => _profile;
  AccountInfo? get account => _account;
  ThemeMode get themeMode =>
      _profile.darkMode ? ThemeMode.dark : ThemeMode.light;

  Future<void> load() async {
    _entries = _storage.getEntries();
    _skinfoldHistory = _storage.getSkinfoldHistory();
    _bodyMeasures = _storage.getBodyMeasures();
    _weightHistory = _storage.getWeightHistory();
    _customFoods = _storage.getCustomFoods();
    _remoteFoods = _onlyNewFoods(_storage.getRemoteCatalog());
    _customMeals = _storage.getCustomMeals();
    _waterByDate = _storage.getWater();
    _profile = _storage.getProfile();
    _account = _storage.getAccount();
    _syncBodyFatFromHistory(save: false);
    notifyListeners();
  }

  /// Remove itens que já existem no catálogo interno e repetições por nome.
  static List<FoodItem> _onlyNewFoods(List<FoodItem> foods) {
    final known = <String>{
      for (final food in FoodCatalog.all) FoodItem.normalizeFoodText(food.name),
    };
    final seen = <String>{};
    return foods.where((food) {
      final key = FoodItem.normalizeFoodText(food.name);
      if (key.isEmpty || known.contains(key) || !seen.add(key)) return false;
      return true;
    }).toList();
  }

  /// Tenta atualizar o catálogo a partir do JSON público no GitHub.
  /// Falhas de rede não apagam a cópia em cache.
  Future<void> refreshCatalog({CatalogSyncService? service}) async {
    final sync = service ?? CatalogSyncService();
    try {
      final foods = await sync.fetch();
      if (foods.isEmpty) return;
      _remoteFoods = _onlyNewFoods(foods);
      await _storage.saveRemoteCatalog(
        jsonEncode(foods.map((food) => food.toJson()).toList()),
      );
      notifyListeners();
    } catch (_) {
      // Offline: mantém o cache carregado em `load()`.
    } finally {
      sync.dispose();
    }
  }

  List<DiaryEntry> entriesFor(String date) =>
      _entries.where((e) => e.date == date).toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  Map<String, double> totalsFor(String date) {
    var kcal = 0.0;
    var protein = 0.0;
    var carbs = 0.0;
    var fat = 0.0;
    for (final e in entriesFor(date)) {
      kcal += e.kcal;
      protein += e.protein;
      carbs += e.carbs;
      fat += e.fat;
    }
    return {'kcal': kcal, 'protein': protein, 'carbs': carbs, 'fat': fat};
  }

  /// Água registrada em um dia, em mililitros.
  double waterFor(DateTime date) => _waterByDate[dateKey(date)] ?? 0;

  /// Soma `ml` à água do dia (use um valor negativo para remover).
  Future<void> addWater(DateTime date, double ml) async {
    final key = dateKey(date);
    final next = (_waterByDate[key] ?? 0) + ml;
    if (next <= 0) {
      _waterByDate.remove(key);
    } else {
      _waterByDate[key] = next;
    }
    await _storage.saveWater(_waterByDate);
    notifyListeners();
  }

  Future<void> addCustomFood(FoodItem food) async {
    _customFoods = [..._customFoods, food];
    await _storage.saveCustomFoods(_customFoods);
    notifyListeners();
  }

  Future<void> removeCustomFood(int fdcId) async {
    _customFoods = _customFoods.where((f) => f.fdcId != fdcId).toList();
    await _storage.saveCustomFoods(_customFoods);
    notifyListeners();
  }

  /// Salva os slots de refeições personalizadas (nome e visibilidade).
  Future<void> updateCustomMeals(List<CustomMeal> meals) async {
    _customMeals = List.unmodifiable(meals);
    await _storage.saveCustomMeals(_customMeals);
    notifyListeners();
  }

  /// Rótulo de uma refeição, inclusive as personalizadas.
  String labelForMeal(String meal) {
    for (final item in availableMeals) {
      if (item.$1 == meal) return item.$2;
    }
    return mealLabel(meal);
  }

  Future<void> addEntry(DiaryEntry entry) async {
    _entries = [..._entries, entry];
    await _storage.saveEntries(_entries);
    notifyListeners();
  }

  /// Adiciona várias porções de uma vez (seleção múltipla no buscador).
  Future<void> addEntries(List<DiaryEntry> newEntries) async {
    if (newEntries.isEmpty) return;
    _entries = [..._entries, ...newEntries];
    await _storage.saveEntries(_entries);
    notifyListeners();
  }

  /// Atualiza uma porção já registrada (nome, quantidade ou macros).
  Future<void> updateEntry(DiaryEntry entry) async {
    _entries = _entries.map((e) => e.id == entry.id ? entry : e).toList();
    await _storage.saveEntries(_entries);
    notifyListeners();
  }

  /// Copia todos os alimentos de uma refeição para outra data/refeição.
  /// Retorna a quantidade de itens copiados.
  Future<int> copyMeal({
    required String fromDate,
    required String fromMeal,
    required String toDate,
    required String toMeal,
    bool replace = false,
  }) async {
    final source = entriesFor(
      fromDate,
    ).where((e) => e.meal == fromMeal).toList();
    if (source.isEmpty) return 0;

    final now = DateTime.now();
    final copies = source.map((e) {
      return e.copyWith(
        id: '${now.microsecondsSinceEpoch}_${e.id}',
        date: toDate,
        meal: toMeal,
        createdAt: now,
      );
    }).toList();

    final targetHasItems = _entries.any(
      (e) => e.date == toDate && e.meal == toMeal,
    );

    _entries = replace && targetHasItems
        ? [
            ..._entries.where((e) => !(e.date == toDate && e.meal == toMeal)),
            ...copies,
          ]
        : [..._entries, ...copies];

    await _storage.saveEntries(_entries);
    notifyListeners();
    return copies.length;
  }

  Future<void> removeEntry(String id) async {
    _entries = _entries.where((e) => e.id != id).toList();
    await _storage.saveEntries(_entries);
    notifyListeners();
  }

  Future<void> addSkinfoldRecord(SkinfoldRecord record) async {
    _skinfoldHistory = [..._skinfoldHistory, record];
    await _storage.saveSkinfoldHistory(_skinfoldHistory);
    await _syncBodyFatFromHistory(save: true);
    notifyListeners();
  }

  Future<void> removeSkinfoldRecord(String id) async {
    _skinfoldHistory = _skinfoldHistory.where((r) => r.id != id).toList();
    await _storage.saveSkinfoldHistory(_skinfoldHistory);
    await _syncBodyFatFromHistory(save: true);
    notifyListeners();
  }

  Future<void> clearSkinfoldHistory() async {
    _skinfoldHistory = [];
    await _storage.saveSkinfoldHistory(_skinfoldHistory);
    await _syncBodyFatFromHistory(save: true);
    notifyListeners();
  }

  Future<void> addBodyMeasure(BodyMeasureRecord record) async {
    _bodyMeasures = [..._bodyMeasures, record];
    await _storage.saveBodyMeasures(_bodyMeasures);
    notifyListeners();
  }

  Future<void> removeBodyMeasure(String id) async {
    _bodyMeasures = _bodyMeasures.where((r) => r.id != id).toList();
    await _storage.saveBodyMeasures(_bodyMeasures);
    notifyListeners();
  }

  Future<void> clearBodyMeasures() async {
    _bodyMeasures = [];
    await _storage.saveBodyMeasures(_bodyMeasures);
    notifyListeners();
  }

  /// Registra (ou atualiza) o peso do dia. Uma medição por data.
  Future<void> addWeightRecord(WeightRecord record) async {
    _weightHistory = [
      ..._weightHistory.where((r) => r.dateKey != record.dateKey),
      record,
    ];
    await _storage.saveWeightHistory(_weightHistory);
    notifyListeners();
  }

  Future<void> removeWeightRecord(String id) async {
    _weightHistory = _weightHistory.where((r) => r.id != id).toList();
    await _storage.saveWeightHistory(_weightHistory);
    notifyListeners();
  }

  Future<void> updateProfile(UserProfile profile) async {
    _profile = profile;
    await _storage.saveProfile(profile);
    notifyListeners();
  }

  Future<void> setAccount(AccountInfo? value) async {
    if (value == null) {
      await _storage.clearAccount();
    } else {
      await _storage.saveAccount(value);
    }
    _account = value;
    notifyListeners();
  }

  Future<void> setDarkMode(bool enabled) async {
    await updateProfile(_profile.copyWith(darkMode: enabled));
  }

  Future<void> updateBodyFat(double percent) async {
    if (percent <= 0 || percent >= 100) return;
    await updateProfile(
      _profile.copyWith(bodyFatPercent: (percent * 10).roundToDouble() / 10),
    );
  }

  /// Preenche o perfil com o % de gordura da última avaliação salva.
  Future<void> syncBodyFatFromLatestSkinfold() async {
    await _syncBodyFatFromHistory(save: true);
    notifyListeners();
  }

  Future<void> _syncBodyFatFromHistory({required bool save}) async {
    final records = skinfoldHistory; // getter já ordena do mais recente
    final percent = records.isEmpty
        ? 0.0
        : (records.first.sevenSite.bodyFatPercent * 10).roundToDouble() / 10;
    if ((_profile.bodyFatPercent - percent).abs() < 0.05) return;
    _profile = _profile.copyWith(bodyFatPercent: percent);
    if (save) await _storage.saveProfile(_profile);
  }
}

String dateKey(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

String mealLabel(String meal) {
  for (final item in AppState.meals) {
    if (item.$1 == meal) return item.$2;
  }
  return meal;
}
