import 'package:flutter_test/flutter_test.dart';
import 'package:nutridobra/utils/skinfold_calculator.dart';

void main() {
  const sites = SkinfoldSites(
    chest: 10,
    axilla: 10,
    triceps: 10,
    subscapular: 10,
    abdomen: 15,
    suprailiac: 10,
    thigh: 15,
  );

  test('calcula densidade e gordura para homem (3 e 7 sítios)', () {
    final result = SkinfoldCalculator.calculate(
      sex: 'male',
      age: 30,
      weightKg: 75,
      sites: sites,
    );

    expect(result.threeSite!.density, closeTo(1.07115, 0.0001));
    expect(result.threeSite!.bodyFatPercent, closeTo(12.1, 0.1));
    expect(result.sevenSite.density, closeTo(1.072073, 0.0001));
    expect(result.sevenSite.bodyFatPercent, closeTo(11.7, 0.1));
    expect(result.sevenSite.fatMassKg, closeTo(75 * 0.117, 0.5));
    expect(
      result.sevenSite.leanMassKg + result.sevenSite.fatMassKg,
      closeTo(75, 0.0001),
    );
  });

  test('usa os sítios corretos para mulheres', () {
    final result = SkinfoldCalculator.calculate(
      sex: 'female',
      age: 30,
      weightKg: 60,
      sites: sites,
    );

    // 3 sítios femininos: tríceps (10) + coxa (15) + supra-ilíaco (10) = 35.
    expect(result.threeSite!.sitesDescription, contains('tríceps'));
    expect(result.threeSite!.sitesDescription, contains('supra-ilíaco'));
    expect(result.threeSite!.bodyFatPercent, greaterThan(0));
    expect(result.sevenSite.bodyFatPercent, greaterThan(0));
  });

  test('rejeita medidas fora da faixa', () {
    expect(
      () => SkinfoldCalculator.calculate(
        sex: 'male',
        age: 30,
        weightKg: 70,
        sites: sites,
      ),
      returnsNormally,
    );

    expect(
      () => SkinfoldCalculator.calculate(
        sex: 'male',
        age: 30,
        weightKg: 70,
        sites: const SkinfoldSites(
          chest: 0,
          axilla: 10,
          triceps: 10,
          subscapular: 10,
          abdomen: 10,
          suprailiac: 10,
          thigh: 10,
        ),
      ),
      throwsArgumentError,
    );
  });
}
