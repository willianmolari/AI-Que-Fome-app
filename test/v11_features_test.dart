import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nutridobra/data/food_catalog.dart';
import 'package:nutridobra/models/diary_entry.dart';
import 'package:nutridobra/models/food_item.dart';
import 'package:nutridobra/models/skinfold_record.dart';
import 'package:nutridobra/services/storage_service.dart';
import 'package:nutridobra/services/update_service.dart';
import 'package:nutridobra/state/app_state.dart';
import 'package:nutridobra/utils/skinfold_calculator.dart';
import 'package:shared_preferences/shared_preferences.dart';

SkinfoldCalculation _calculation() => SkinfoldCalculator.calculate(
      sex: 'male',
      age: 30,
      weightKg: 80,
      sites: const SkinfoldSites(
        chest: 12,
        axilla: 10,
        triceps: 12,
        subscapular: 14,
        abdomen: 18,
        suprailiac: 16,
        thigh: 14,
      ),
    );

SkinfoldRecord _record(DateTime date) => SkinfoldRecord.create(
      sex: 'male',
      age: 30,
      weightKg: 80,
      sites: const SkinfoldSites(
        chest: 12,
        axilla: 10,
        triceps: 12,
        subscapular: 14,
        abdomen: 18,
        suprailiac: 16,
        thigh: 14,
      ),
      calculation: _calculation(),
      createdAt: date,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('catálogo de bebidas', () {
    test('refrigerantes e líquidos estão disponíveis no catálogo', () {
      final results = FoodCatalog.search('coca cola');
      expect(results, isNotEmpty);
      expect(
        results.any((f) => f.name.toLowerCase().contains('coca-cola')),
        isTrue,
      );

      final water = FoodCatalog.search('agua mineral');
      expect(water, isNotEmpty);
      expect(water.first.servingUnit, 'ml');
    });

    test('filtro Líquidos inclui bebidas e leite em ml', () {
      final results = FoodCatalog.search('', category: 'Líquidos');
      expect(results.length, greaterThan(10));
      expect(
        results.every(
          (f) => f.servingUnit == 'ml' || f.category == 'Bebidas',
        ),
        isTrue,
      );
      expect(
        results.any((f) => f.name.toLowerCase().contains('leite integral')),
        isTrue,
      );
    });

    test('leite comum usa ml', () {
      final leite = FoodCatalog.search('leite integral');
      expect(leite, isNotEmpty);
      expect(
        leite.any((f) => f.servingUnit == 'ml' && f.servingSize == 200),
        isTrue,
      );
    });
  });

  test('DiaryEntry serializa a unidade g/ml', () {
    final entry = DiaryEntry(
      id: '1',
      date: '2026-11-21',
      fdcId: -9001,
      foodName: 'Coca-Cola',
      meal: 'almoco',
      grams: 350,
      unit: 'ml',
      kcal: 147,
      protein: 0,
      carbs: 37,
      fat: 0,
      createdAt: DateTime(2026, 11, 21),
    );
    final restored = DiaryEntry.fromJson(
      jsonDecode(jsonEncode(entry.toJson())) as Map<String, dynamic>,
    );
    expect(restored.unit, 'ml');
    expect(restored.grams, 350);
    expect(restored.meal, 'almoco');
  });

  test('AppState persiste água por dia', () async {
    final state = AppState(await StorageService.create());
    await state.load();

    final today = DateTime(2026, 11, 21);
    await state.addWater(today, 200);
    await state.addWater(today, 300);
    await state.addWater(DateTime(2026, 11, 20), 500);

    expect(state.waterFor(today), 500);
    expect(state.waterFor(DateTime(2026, 11, 20)), 500);

    await state.addWater(today, -200);
    expect(state.waterFor(today), 300);

    final reloaded = AppState(await StorageService.create());
    await reloaded.load();
    expect(reloaded.waterFor(today), 300);
  });

  test('AppState persiste alimentos cadastrados pelo usuário', () async {
    final state = AppState(await StorageService.create());
    await state.load();

    final food = FoodItem(
      fdcId: 123456789,
      name: 'Bolo da vovó',
      dataType: 'Cadastro manual',
      servingSize: 100,
      servingUnit: 'g',
      kcal: 250,
      protein: 4,
      carbs: 40,
      fat: 8,
      source: 'custom',
      category: 'Doces',
    );
    await state.addCustomFood(food);
    expect(state.customFoods, hasLength(1));
    expect(state.customFoods.first.name, 'Bolo da vovó');

    final reloaded = AppState(await StorageService.create());
    await reloaded.load();
    expect(reloaded.customFoods, hasLength(1));
    expect(reloaded.customFoods.first.servingUnit, 'g');

    await reloaded.removeCustomFood(123456789);
    expect(reloaded.customFoods, isEmpty);
  });

  group('comparação de versões', () {
    test('detecta versões mais novas', () {
      expect(UpdateService.isNewer('v1.1.0', '1.0.0'), isTrue);
      expect(UpdateService.isNewer('v1.0.1', '1.0.0'), isTrue);
      expect(UpdateService.isNewer('v2.0.0', '1.9.9'), isTrue);
    });

    test('ignora versões iguais ou mais antigas', () {
      expect(UpdateService.isNewer('v1.0.0', '1.0.0'), isFalse);
      expect(UpdateService.isNewer('v0.9.9', '1.0.0'), isFalse);
      expect(UpdateService.isNewer('v1.1.0+2', '1.1.0'), isFalse);
    });
  });

  test('AppState preenche a gordura com a última avaliação Jackson-Pollock',
      () async {
    final state = AppState(await StorageService.create());
    await state.load();

    await state.addSkinfoldRecord(_record(DateTime(2026, 1, 10)));
    final expected = state.skinfoldHistory.first.sevenSite.bodyFatPercent;
    expect(state.profile.bodyFatPercent, closeTo(expected, 0.05));

    await state.updateBodyFat(12.34);
    expect(state.profile.bodyFatPercent, 12.3);

    await state.syncBodyFatFromLatestSkinfold();
    expect(
      state.profile.bodyFatPercent,
      closeTo((expected * 10).roundToDouble() / 10, 0.001),
    );
  });
}
