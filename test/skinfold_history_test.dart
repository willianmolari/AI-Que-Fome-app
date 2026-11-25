import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutridobra/models/skinfold_record.dart';
import 'package:nutridobra/screens/skinfold_screen.dart';
import 'package:nutridobra/services/storage_service.dart';
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
  notes: 'Mesma técnica de medição',
  createdAt: date,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('serializa e restaura uma avaliação completa', () {
    final original = _record(DateTime(2026, 3, 12, 9, 30));
    final json = jsonDecode(jsonEncode(original.toJson()));
    final restored = SkinfoldRecord.fromJson(json as Map<String, dynamic>);

    expect(restored.id, original.id);
    expect(restored.createdAt, original.createdAt);
    expect(restored.sex, 'male');
    expect(restored.weightKg, 80);
    expect(restored.sites.chest, 12);
    expect(restored.threeSite, isNotNull);
    expect(
      restored.sevenSite.bodyFatPercent,
      closeTo(original.sevenSite.bodyFatPercent, 0.0001),
    );
    expect(restored.notes, 'Mesma técnica de medição');
  });

  test('AppState persiste o histórico e ordena do mais recente', () async {
    final state = AppState(await StorageService.create());
    await state.load();
    expect(state.skinfoldHistory, isEmpty);

    final old = _record(DateTime(2025, 1, 10));
    final recent = _record(DateTime(2026, 5, 20));
    await state.addSkinfoldRecord(old);
    await state.addSkinfoldRecord(recent);

    expect(state.skinfoldHistory.length, 2);
    expect(state.skinfoldHistory.first.id, recent.id);

    await state.removeSkinfoldRecord(old.id);
    final reloaded = AppState(await StorageService.create());
    await reloaded.load();
    expect(reloaded.skinfoldHistory.length, 1);
    expect(reloaded.skinfoldHistory.single.id, recent.id);
  });

  testWidgets('tela de dobras exibe o histórico', (tester) async {
    final state = AppState(await StorageService.create());
    await state.load();
    await state.addSkinfoldRecord(_record(DateTime(2026, 5, 20)));

    await tester.pumpWidget(MaterialApp(home: SkinfoldScreen(state: state)));
    await tester.pump();
    await tester.tap(find.text('Jackson & Pollock (dobras)'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.textContaining('20 mai 2026'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    // Um título é das dobras e outro é da nova seção de circunferências.
    expect(find.text('Histórico'), findsNWidgets(2));
    expect(find.textContaining('20 mai 2026'), findsOneWidget);
    expect(find.text('Carregar'), findsNothing);

    await tester.tap(find.textContaining('20 mai 2026'));
    await tester.pumpAndSettle();

    expect(find.text('Carregar'), findsOneWidget);
    expect(find.text('Excluir'), findsOneWidget);
  });
}
