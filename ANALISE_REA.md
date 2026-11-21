# Análise REA — Calorie Counter by fatsecret 11.10.0.3 (XAPK)

> Escopo: engenharia reversa estática para levantar **requisitos funcionais** e
> produzir uma reimplementação **original** (clean room). Nenhum código, asset,
> marca, strings de UI ou banco de dados proprietário foi copiado.

## 1. Artefato analisado

| Campo | Valor |
| --- | --- |
| Arquivo | `Calorie+Counter+by+fatsecret_11.10.0.3_APKPure.xapk` |
| SHA-256 | `d5fd82c29224c781379a693dc3589f4a8e7262501bf7a90d7debe68b9b775e7b` |
| Formato | ZIP (XAPK) com 6 entradas |
| APK base | `com.fatsecret.android.apk` — 86.775.023 bytes |
| SHA-256 do APK base | `d1ab28a8c793a870cd46580ec17a4c0c03fe56ea42854e50d98cc0f27673c401` |
| Splits | `config.arm64_v8a.apk`, `config.xxhdpi.apk` |
| Outros | `icon.png`, `manifest.json` |
| Provider de decompilação | jadx-headless-mcp 0.7.1 (JAR verificado) |

## 2. Identidade e configuração do app

- Package: `com.fatsecret.android`
- Versão: `11.10.0.3` (versionCode `809`)
- minSdk 21 / targetSdk 36
- 101 activities declaradas, 167 componentes no total.
- Permissões relevantes observadas: `INTERNET`, `CAMERA`, `ACTIVITY_RECOGNITION`,
  `POST_NOTIFICATIONS`, Health Connect (peso, passos, calorias, nutrição),
  `BILLING`, `RECEIVE_BOOT_NOT_COMPLETED`, `READ/WRITE_EXTERNAL_STORAGE`.

## 3. Mapa funcional inferido (somente requisitos)

| Função observada | Evidência (activity / permissão) | Entrará na v1 original? |
| --- | --- | --- |
| Diário alimentar | `FoodJournalAddActivity`, `FoodJournalSearchComposeActivity`, `FoodEditActivity` | **Sim** |
| Busca de alimentos | `NewSearchActivity`, `FoodInfoActivity`, `FoodDetailsActivity` | **Sim** |
| Metas diárias | `MyGoalsActivity`, `PredictedGoalDateActivity` | **Sim** |
| Histórico/calendário | `CalendarHistoryActivity`, `WeightHistoryActivity` | **Sim** (diário por data) |
| Refeições salvas / planejador | `SavedMealActivity`, `MealPlannerActivity`, `MealPlanActivity` | Não nesta v1 |
| Receitas | `RecipeDetailsActivity`, `CreateRecipeActivity` | Não nesta v1 |
| Exercícios | `ExerciseDiaryActivity`, `ExerciseDiaryAddActivity`, `AppsAndDevicesActivity` | Não nesta v1 |
| Peso | `WeighInActivity`, `WeightHistoryActivity`, Health Connect | **Sim** (atual, alvo, histórico e gráfico) |
| Câmera / código de barras | `MLKitCaptureActivity`, `FoodImageCaptureActivity`, `CAMERA` | Não nesta v1 |
| Assinatura / premium | `SubscriptionProductsActivity`, `BILLING` | Não |
| Social / IA / onboarding | `NewsFeedCommentsActivity`, `SmartAssistantActivity`, `OnboardingActivity` | Não |

### Conclusão funcional

O núcleo é um **diário energético com busca de alimentos, metas e histórico**.
A reimplementação foca exatamente nesse núcleo, com dados públicos do USDA e
uma aba adicional de composição corporal.

## 4. Decisões de implementação (clean room)

- Stack: **Flutter 3.38.10 / Dart 3.10.9** (versão compatível com macOS 13).
- Dados de alimentos:
  - **catálogo local original** com alimentos brasileiros, tabela TACO
    (valores médios públicos), suplementos de marcas brasileiras e redes de
    fast food, mantido em `lib/data/food_catalog.dart` e `lib/data/taco_foods.dart`;
  - **Open Food Facts** (API aberta, filtrada para produtos do Brasil) e
    **USDA FoodData Central API v1** (CC0) como fontes opcionais online.
- Login: **Firebase Auth + Google Sign-In**, com `google-services.json` do
  projeto `ai-que-fome-dba43` e SHA-1 do keystore de debug cadastrada.
- Perfil com dados pessoais, metas e modo escuro; `%` de gordura pode ser
  preenchido automaticamente pela aba de dobras.
- Persistência local: `shared_preferences` (JSON) para diário, metas, perfil,
  modo escuro, histórico de dobras e histórico de peso, sem sincronização de
  dados com servidores.
- Identidade visual, nomes, ícones e textos são **originais**.
- Nenhuma chamada de rede ao domínio do app analisado foi reutilizada.

## 5. Jackson & Pollock — fórmulas implementadas

Todas as dobras em **milímetros**; densidade corporal em g/cm³; conversão final
pela equação de Siri: `BF% = (4.95 / BD - 4.50) * 100`.

### 3 sítios — homens (peito, abdome, coxa)

```
BD = 1.10938 - 0.0008267 * S + 0.0000016 * S^2 - 0.0002574 * idade
S  = peito + abdome + coxa
```

### 3 sítios — mulheres (tríceps, coxa, supra-ilíaco)

```
BD = 1.0994921 - 0.0009929 * S + 0.0000023 * S^2 - 0.0001392 * idade
S  = tríceps + coxa + supra-ilíaco
```

### 7 sítios — homens (peito, axila, tríceps, subescapular, abdome, supra-ilíaco, coxa)

```
BD = 1.112 - 0.00043499 * S + 0.00000055 * S^2 - 0.00028826 * idade
```

### 7 sítios — mulheres (mesmos 7 sítios)

```
BD = 1.097 - 0.00046971 * S + 0.00000056 * S^2 - 0.00012828 * idade
```

Referências: Jackson & Pollock (1978), Jackson, Pollock & Ward (1980), Siri (1956).
Fórmulas e locais de medição conferidos em
<https://www.topendsports.com/testing/density-jackson-pollock.htm> e
<https://en.wikipedia.org/wiki/Body_fat_percentage>.

> A estimativa por dobras cutâneas tem erro típico de ±3–4% e depende de técnica,
> caliper calibrado e população. O app exibe essa limitação na tela.

## 6. USDA FoodData Central

- Busca: `GET https://api.nal.usda.gov/fdc/v1/foods/search?api_key=...&query=...`
- Detalhe: `GET https://api.nal.usda.gov/fdc/v1/food/{fdcId}?api_key=...`
- Nutrientes mapeados (por 100 g): energia 1008 (kcal), proteína 1003 (g),
  lipídeos 1004 (g), carboidratos 1050 (g), fibra 1079 (g), açúcares 2000 (g).
- Limite padrão: 1.000 requisições/hora por IP; `DEMO_KEY`: 30/hora e 50/dia.
- Documentação: <https://fdc.nal.usda.gov/api-guide.html>

## 7. Estado da entrega

- `flutter analyze`: **sem issues**.
- `flutter test`: **17 testes aprovados** (fórmulas 3/7 sítios, sítios femininos,
  validação de faixa, buscas no catálogo, whey, TACO, aveia/leite
  semidesnatado, categorias comuns, histórico de dobras e histórico/gráfico
  de peso com peso atual e alvo).
- APK release gerado em `build/app/outputs/flutter-apk/app-release.apk`.
  - SHA-256: `78eeb1cc80acdc1667c476a7a1a1d217efc716d8dbcfe7f2d81e1acd5ee1bc3a`
- AAB para publicação gerado em
  `build/app/outputs/bundle/release/app-release.aab`.
  - SHA-256: `674b6ae0e5eaa590d1106a77776ed5b48504c5c42f943b80c27759f833861098`
- Material da Play Store preparado em `play_store/` (listagem pt-BR, política
  de privacidade, roteiro de publicação e 4 capturas reais do aparelho).
  - Permissão `INTERNET` confirmada no manifest compilado.
  - `minSdk 24`, `targetSdk 36`, `versionName 1.0.0`.
  - App renomeado para **Ai que fome** (pacote inalterado).
- APK instalado e aberto no Samsung SM-S721B via `adb`, sem erros fatais.
- Melhorias da terceira iteração:
  - whey e suplementos de Growth, Integral Médica, Black Skull, Max Titanium,
    Dux, New Millen, Bodytech, Probiótica etc.;
  - tabela TACO offline e integração com Open Food Facts (Brasil);
  - filtros **Brasil / TACO / Fast food / Suplementos / Open Food Facts / USDA**;
  - aba **Perfil** substituiu **Metas**, com login Google, modo escuro e
    configurações;
  - resultado de dobras agora atualiza automaticamente o `%` de gordura no perfil;
  - tema escuro aplicado em todas as telas (inclusive cartões de atalhos);
  - catálogo ampliado com aveia, leites semidesnatados, pães, massas,
    legumes, frutas, oleaginosas e pratos prontos brasileiros;
  - identidade visual própria: ícone 512x512 e imagem de destaque 1024x500
    em `assets_store/`, também aplicados ao launcher Android;
  - histórico local de avaliações de dobras (data, observação, medidas,
    resultados, carregar/excluir);
  - peso atual e peso alvo salvos no perfil, com histórico de pesagens por
    data e gráfico de evolução (sem dependência de biblioteca de gráficos).
- Ambiente usado: Flutter 3.38.10 / Dart 3.10.9, JDK 21, Android SDK 36,
  Kotlin Gradle Plugin 2.4.0.
