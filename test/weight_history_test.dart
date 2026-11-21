import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutridobra/models/user_profile.dart';
import 'package:nutridobra/models/weight_record.dart';
import 'package:nutridobra/screens/profile_screen.dart';
import 'package:nutridobra/services/storage_service.dart';
import 'package:nutridobra/state/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('serializa peso atual e peso alvo no perfil', () {
    const profile = UserProfile(weightKg: 82.5, targetWeightKg: 74);
    final restored = UserProfile.fromJson(
      jsonDecode(jsonEncode(profile.toJson())) as Map<String, dynamic>,
    );
    expect(restored.weightKg, 82.5);
    expect(restored.targetWeightKg, 74);
    expect(
      profile.copyWith(targetWeightKg: 76).targetWeightKg,
      76,
    );
  });

  test('serializa e restaura uma medição de peso', () {
    final record = WeightRecord.create(
      date: DateTime(2026, 11, 21, 15, 30),
      weightKg: 80.4,
    );
    final restored = WeightRecord.fromJson(
      jsonDecode(jsonEncode(record.toJson())) as Map<String, dynamic>,
    );
    expect(restored.id, '2026-11-21');
    expect(restored.date, DateTime(2026, 11, 21));
    expect(restored.weightKg, 80.4);
  });

  test('AppState persiste, ordena e substitui pesagens do mesmo dia', () async {
    final state = AppState(await StorageService.create());
    await state.load();
    expect(state.weightHistory, isEmpty);

    await state.addWeightRecord(
      WeightRecord.create(date: DateTime(2026, 5, 20), weightKg: 84),
    );
    await state.addWeightRecord(
      WeightRecord.create(date: DateTime(2026, 11, 21), weightKg: 81),
    );
    expect(state.weightHistory.length, 2);
    expect(state.weightHistory.first.date, DateTime(2026, 5, 20));

    await state.addWeightRecord(
      WeightRecord.create(date: DateTime(2026, 11, 21, 20), weightKg: 80.5),
    );
    expect(state.weightHistory.length, 2);
    expect(state.weightHistory.last.weightKg, 80.5);

    final reloaded = AppState(await StorageService.create());
    await reloaded.load();
    expect(reloaded.weightHistory.length, 2);
    expect(reloaded.weightHistory.last.weightKg, 80.5);
  });

  testWidgets('perfil mostra peso, gráfico e registra uma pesagem',
      (tester) async {
    final state = AppState(await StorageService.create());
    await state.load();
    await state.updateProfile(
      const UserProfile(weightKg: 80, targetWeightKg: 74),
    );

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: ProfileScreen(state: state))),
    );
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('Evolução do peso'),
      400,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('Peso atual (kg)'), findsOneWidget);
    expect(find.text('Peso alvo (kg)'), findsOneWidget);
    expect(find.text('Registrar peso de hoje'), findsOneWidget);

    await tester.tap(find.text('Registrar peso de hoje'));
    await tester.pumpAndSettle();

    expect(state.weightHistory.length, 1);
    expect(state.weightHistory.single.weightKg, 80);
    expect(state.profile.targetWeightKg, 74);
  });
}
