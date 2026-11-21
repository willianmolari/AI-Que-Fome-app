# Ai que fome

Aplicativo Flutter original de diário alimentar com:

- diário por data e 4 refeições, com **calendário semanal** (dias com
  registros, barras de calorias e grade mensal);
- **catálogo local** com alimentos brasileiros comuns (aveia, leites
  semidesnatados, pães, massas, legumes, frutas e pratos prontos), tabela
  **TACO**, suplementos (Growth, Integral Médica, Black Skull, Max Titanium
  etc.) e redes de fast food, com filtros por origem e categoria;
- busca opcional no **Open Food Facts** (produtos do Brasil) e no
  **USDA FoodData Central**;
- calorias e macronutrientes por porção;
- aba de **Perfil** com nome, idade, **peso atual e peso alvo**, altura, sexo,
  % de gordura, metas, chave do USDA e **modo escuro**;
- **histórico de peso** com registro por data, exclusão de medições e
  **gráfico de evolução** com linha do peso alvo;
- login com **Google via Firebase Auth**;
- aba de **dobras cutâneas Jackson & Pollock (3 e 7 sítios)** com
  **histórico local**: salve avaliações com data, observação, medidas e
  resultados; depois é possível carregar ou excluir cada registro. O perfil
  usa automaticamente o % de gordura da avaliação mais recente.
- **contador de água** diário com meta configurável no perfil e atalhos de
  200/300/500 ml.
- **cadastro manual de alimentos** e leitura de **código de barras** via
  câmera (consulta no Open Food Facts), com opção de cadastrar o produto
  caso não seja encontrado.
- **aviso de atualização**: o app consulta a release mais recente no GitHub e
  oferece o download direto do APK.

Este projeto é uma reimplementação funcional independente: não reutiliza
código, layout, assets, marca, chaves ou banco de dados do aplicativo analisado.
O relatório de engenharia reversa está em [`ANALISE_REA.md`](ANALISE_REA.md).

## Download

A versão mais recente está publicada em
[GitHub Releases](https://github.com/willianmolari/AI-Que-Fome-app/releases/latest),
com `app-release.apk` para instalação direta e `app-release.aab` para a
Play Store. A versão 1.0.0 permanece disponível
[aqui](https://github.com/willianmolari/AI-Que-Fome-app/releases/tag/v1.0.0).

Política de privacidade:
<https://willianmolari.github.io/AI-Que-Fome-app/>.

## Requisitos

- Flutter 3.38.10 / Dart 3.10.9 (testado neste ambiente macOS 13) ou versão
  compatível superior.
- JDK 17+ e Android SDK com platform 36 / build-tools 36 para gerar o APK.
- Uma chave gratuita do USDA FoodData Central (opcional; sem ela o app usa
  `DEMO_KEY`, com limite baixo).
- Projeto Firebase com Authentication/Google ativado. O arquivo
  `android/app/google-services.json` já está configurado para o projeto
  `ai-que-fome-dba43`.

## Executar

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

Para gerar o APK ou o pacote de publicação:

```bash
flutter build apk --release
flutter build appbundle --release
```

Material da Play Store (ícone, banner, capturas, texto da listagem, política
de privacidade e roteiro de publicação) está em `play_store/`.

### Reconfigurar o Firebase em outro projeto

1. No Firebase Console, registre o app Android com o pacote
   `com.willianmolari.nutridobra.nutridobra`.
2. Baixe o `google-services.json` e substitua `android/app/google-services.json`.
3. Em **Configurações do projeto → Seus apps**, adicione a SHA-1 do keystore
   usado no build (`keytool -list -v -keystore ~/.android/debug.keystore -storepass android`).
4. Em **Authentication → Método de login**, ative o provedor **Google** e salve.
5. Rode `flutter pub get && flutter build apk --release`.

## Estrutura

```
lib/
  main.dart                          navegação e tema
  data/food_catalog.dart             índice do catálogo local
  data/common_brazilian_foods.dart   alimentos comuns no Brasil
  data/taco_foods.dart               tabela pública TACO-inspired
  models/                            entidades serializáveis (diário, dobras e peso)
  screens/                           telas Diário, Alimentos, Perfil e Dobras
  services/auth_service.dart         login Google (Firebase Auth)
  services/open_food_facts_client.dart  API aberta do Open Food Facts
  services/usda_client.dart          USDA FoodData Central
  state/app_state.dart               estado compartilhado
  theme/app_theme.dart               temas claro/escuro
  utils/skinfold_calculator.dart     equações Jackson & Pollock + Siri
  widgets/macro_bar.dart             barras de macronutrientes
  widgets/week_calendar.dart         calendário semanal e grade mensal
  widgets/weight_chart.dart          gráfico de evolução do peso
test/skinfold_calculator_test.dart
test/skinfold_history_test.dart
test/weight_history_test.dart
test/food_catalog_test.dart
assets_store/
  app-icon-play.svg / .png           ícone 512x512 cheio para a Play Store
  app-icon.svg / app-icon.png        versão com cantos arredondados
  feature-graphic.svg / .png         imagem de destaque 1024x500
play_store/
  listing-pt-BR.md                   textos, tags e respostas da loja
  privacy-policy.html                política de privacidade para hospedar
  PUBLICACAO.md                      passo a passo e SHA-1 do Play Signing
  screenshots/                       4 capturas 1080x2340
```

O ícone também foi aplicado ao launcher Android (`mipmap-*`).

## Privacidade

Registros do diário (alimentos por data/refeição), metas, perfil, histórico de
dobras, histórico de peso e chave da API ficam apenas no dispositivo
(`shared_preferences`, em JSON). O login com Google é usado somente para
identificar a conta; não há sincronização de dados nem telemetria própria.

## Aviso

Dobras cutâneas fornecem uma **estimativa** de composição corporal, com erro
típico de ±3–4% e dependência da técnica de medição. Não substituem avaliação
de um profissional de saúde ou métodos como DEXA.
