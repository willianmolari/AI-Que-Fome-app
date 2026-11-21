# Roteiro de publicação — Ai que fome

## Pré-requisitos antes do upload

1. **Conta Google com acesso à conta de desenvolvedor Molarizado** no
   [Play Console](https://play.google.com/console/).
2. **URL pública da política de privacidade**: já publicada via GitHub Pages
   em <https://willianmolari.github.io/AI-Que-Fome-app/> (arquivo
   `docs/index.html`, serviço configurado para a branch `main`, pasta `/docs`).
   A Play Console exige essa URL para apps com login/Internet.
3. Arquivos prontos nesta pasta:
   - `app-release.aab` (em `build/app/outputs/bundle/release/`);
   - `../assets_store/app-icon-play.png` (512×512);
   - `../assets_store/feature-graphic.png` (1024×500);
   - `screenshots/01-diario.png` … `04-dobras.png` (1080×2340).
4. Textos em `listing-pt-BR.md`.

## Política no GitHub Pages (já configurada)

- Repositório: `willianmolari/AI-Que-Fome-app`
- Origem: branch `main`, pasta `/docs`
- URL: <https://willianmolari.github.io/AI-Que-Fome-app/>
- Não é preciso repositório separado: o site usa o próprio `docs/index.html`.

## Download da v1.0.0 no GitHub

Release: <https://github.com/willianmolari/AI-Que-Fome-app/releases/tag/v1.0.0>

Anexos: `app-release.apk` (53,5 MB) e `app-release.aab` (44,8 MB).

## Passo a passo no Play Console

1. Criar o app: nome **Ai que fome**, idioma **Português (Brasil)**,
   categoria **Saúde e fitness**, app **gratuito**.
2. **Configurar o aplicativo → Listagem da loja**:
   - descrição curta e completa de `listing-pt-BR.md`;
   - ícone 512×512, imagem de destaque 1024×500;
   - 4 capturas de tela e as legendas do arquivo de listagem.
3. **Configurar o aplicativo → Declaração de dados**: usar as respostas de
   `listing-pt-BR.md`. Classificação de conteúdo: responder "Não" a tudo;
   resultado esperado **Todos**.
4. Informar a URL da política de privacidade.
5. **Teste e versão → Versões → Criar versão**:
   - aceitar o **Play App Signing** (obrigatório para apps novos);
   - enviar `app-release.aab`;
   - notas da versão: texto de `listing-pt-BR.md`.
6. Recomendado: publicar primeiro em **teste interno/fechado**, instalar pela
   Play Store e confirmar o login Google. Depois promover para **produção**.
7. Para publicar direto em produção, escolher **Produzir → Criar versão** e
   depois **Iniciar lançamento**.

## SHA-1 do Firebase após o Play App Signing

Com o Play App Signing ativo, o certificado que assina o app na Play Store não
é o mesmo do build local. É preciso cadastrar o SHA-1 **de assinatura do app**:

1. No Play Console, abrir **Configurar o aplicativo → Integridade do app →
   Certificados de assinatura do app** e copiar o **SHA-1 do certificado de
   assinatura do app**.
2. No [Firebase Console](https://console.firebase.google.com/), projeto
   `ai-que-fome-dba43`, ir em **Configurações do projeto → Seus apps → app
   Android → Adicionar impressão digital SHA-1** e colar o valor copiado.
3. Baixar o novo `google-services.json`, substituir
   `android/app/google-services.json`, gerar um novo AAB e enviar uma nova
   versão (aumentando o `versionCode` em `pubspec.yaml`, de `+1` para `+2`).

> O login Google cadastrado apenas com a SHA-1 de debug funciona em build local,
> mas pode falhar na versão publicada sem esse passo.

## Atualizações futuras

- Incrementar `versionCode` (`1.0.0+2`, `1.0.0+3`, …) em `pubspec.yaml`.
- `flutter build appbundle --release` e enviar o novo AAB.
- Manter o mesmo pacote: `com.willianmolari.nutridobra.nutridobra`.

## Versão 1.1 (planejada, não inclusa nesta entrega)

- gráficos de macronutrientes por semana;
- cadastro de alimentos personalizados pelo usuário.
