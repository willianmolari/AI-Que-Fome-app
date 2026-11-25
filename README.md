# Ai que fome

Aplicativo Flutter original de diário alimentar com:

- diário por data, **4 refeições padrão + até 4 refeições personalizadas** e
  **calendário semanal** (dias com registros, barras de calorias e grade mensal);
- refeições extras nomeadas e ativadas pelo usuário no ícone de ajustes do
  diário — slots vazios/desativados não aparecem;
- **catálogo local** com alimentos brasileiros comuns, tabela **TACO**,
  suplementos, marcas (Ninho, Molico, Danone, Cutrale, Fischer etc.),
  lanchonetes (Burger King, McDonald's e Demeter Burger), pratos do Posto
  Pelanda, féculas/farinhas e 1.261 itens únicos;
- **catálogo remoto em JSON público**, atualizado na abertura com cache offline:
  é possível ampliar os alimentos editando um arquivo no GitHub, sem gerar novo
  APK;
- busca de alimentos direto no diário, sem aba dedicada — a refeição é inferida
  do clique;
- seleção múltipla com checkboxes, edição de porção antes de adicionar e
  edição de porção dos itens já salvos;
- cópia de refeição entre dias/refeições (com opção de substituir);
- busca opcional no **Open Food Facts** e leitura de **código de barras**;
- calorias e macronutrientes por porção;
- aba de **Perfil** reorganizada: dados pessoais primeiro, depois peso, metas e
  preferências;
- **histórico de peso** com registro por data, exclusão de medições e
  **gráfico de evolução** com linha do peso alvo;
- login com **Google via Firebase Auth**;
- aba de **Medidas** com:
  - **Jackson & Pollock (3 e 7 sítios)** minimizado e expansível, com histórico
    local (data, observação, medidas e resultados);
  - **circunferências com fita, estilo ISAK**: pescoço, peito, abdômen,
    quadril, coxa esquerda/direita flexionada e relaxada, braço
    esquerdo/direito flexionado e relaxado — com salvamento, carregamento,
    exclusão e histórico local;
- **contador de água** compacto, com meta configurável no perfil e atalhos de
  200/300/500 ml;
- **cadastro manual de alimentos** e código de barras via câmera, com opção de
  cadastrar o produto caso não seja encontrado;
- **aviso de atualização**: o app consulta a release mais recente no GitHub e
  oferece o download direto do APK;
- **visual inspirado na Apple** com acento azul, superfícies agrupadas,
  separadores finos, títulos grandes e gráfico semanal de calorias, macros e
  água.

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
- Projeto Firebase com Authentication/Google ativado. O arquivo
  `android/app/google-services.json` já está configurado para o projeto
  `ai-que-fome-dba43`.

Não há mais chave de API: a busca USDA foi removida e o catálogo remoto é um
arquivo JSON público, sem credencial.

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

### Como ampliar o catálogo sem recompilar

O app consulta, ao abrir, este arquivo do próprio repositório:

```text
.food_catalog.json
```

Ele fica na raiz do repositório (começa com ponto, portanto não aparece na
listagem normal do GitHub/Finder) e é servido por:

```text
https://raw.githubusercontent.com/willianmolari/AI-Que-Fome-app/main/.food_catalog.json
```

Para adicionar alimentos:

1. Edite `.food_catalog.json` e inclua novos objetos em `foods`.
2. Use um `fdcId` negativo e único (por exemplo `-20001`).
3. Informe `name`, `dataType`, `kcal`, `protein`, `fat`, `carbs` e,
   opcionalmente, `brand`, `category`, `fiber`, `sugars`, `servingSize`,
   `servingUnit` e `source`.
4. Faça commit/push. Na próxima abertura, o app baixa a lista, descarta nomes
   que já existem no catálogo interno e salva uma cópia local para uso offline.

Se não houver internet, o app usa a última cópia salva no dispositivo. Um
arquivo público no GitHub não é secreto: quem tiver a URL exata consegue lê-lo,
mas ela não é exibida nem anunciada dentro do app.

O script `dart run tool/export_catalog.dart` gera um snapshot do catálogo
compilado. Use-o apenas para criar/atualizar a base inicial; se você adicionar
itens diretamente no JSON, não rode o exportador depois, pois ele sobrescreve o
arquivo.

### Reconfigurar o Firebase em outro projeto

1. No Firebase Console, registre o app Android com o pacote
   `com.willianmolari.nutridobra.nutridobra`.
2. Baixe o `google-services.json` e substitua `android/app/google-services.json`.
3. Em **Configurações do projeto → Seus apps**, adicione a SHA-1 do keystore
   usado no build (`keytool -list -v -keystore ~/.android/debug.keystore -storepass android`).
4. Em **Authentication → Método de login**, ative o provedor **Google** e salve.
5. Rode `flutter pub get && flutter build apk --release`.

## Estrutura

```text
.food_catalog.json                 catálogo ampliável sem recompilar
nutridobra/
  main.dart                          navegação, tema e sincronização inicial
  data/food_catalog.dart             índice deduplicado do catálogo local
  data/brands_foods.dart             marcas e alimentos brasileiros adicionais
  models/                            entidades serializáveis (diário, dobras, fita, peso)
  screens/                           telas Diário, Busca, Perfil e Medidas
  services/catalog_sync_service.dart download do JSON público do GitHub
  services/auth_service.dart         login Google (Firebase Auth)
  services/open_food_facts_client.dart API aberta do Open Food Facts
  state/app_state.dart               estado compartilhado
  theme/app_theme.dart               temas claro/escuro
  utils/skinfold_calculator.dart     equações Jackson & Pollock + Siri
  widgets/body_measures_section.dart circunferências ISAK e histórico
  widgets/water_card.dart            contador de água compacto
  tool/export_catalog.dart           gera snapshot inicial do catálogo
  test/v13_features_test.dart        cobertura da v1.3
```

## Privacidade

Registros do diário (alimentos por data/refeição), refeições personalizadas,
metas, perfil, histórico de dobras, histórico de medidas, histórico de peso e
água ficam apenas no dispositivo (`shared_preferences`, em JSON). O login com
Google é usado somente para identificar a conta; não há sincronização do diário
nem telemetria própria. A única consulta de rede adicional é o download do
JSON público do catálogo e do Open Food Facts, quando usado.

## Aviso

Dobras cutâneas e circunferências fornecem **estimativas** de composição
corporal, com erro dependente da técnica e do equipamento. Não substituem
avaliação de um profissional de saúde ou métodos como DEXA.
