# Roteiro de publicação — Ai que fome

## Pré-requisitos antes do upload

1. **Conta Google com acesso à conta de desenvolvedor Molarizado** no
   [Play Console](https://play.google.com/console/).
2. **URL pública da política de privacidade**: a Play Console exige essa URL
   para apps com login/Internet. O HTML pronto está em `privacy-policy.html`
   e também em `docs/index.html` (para GitHub Pages).
3. Arquivos prontos nesta pasta:
   - `app-release.aab` (em `build/app/outputs/bundle/release/`);
   - `../assets_store/app-icon-play.png` (512×512);
   - `../assets_store/feature-graphic.png` (1024×500);
   - `screenshots/01-diario.png` … `04-dobras.png` (1080×2340).
4. Textos em `listing-pt-BR.md`.

## Publicar a política no GitHub Pages

1. Criar um repositório público (por exemplo `ai-que-fome-privacidade`) na
   conta GitHub do Molarizado.
2. Enviar o conteúdo da pasta `play_store/docs/` para a branch `main`
   (o arquivo precisa ficar na raiz com o nome `index.html`).
3. Em **Settings → Pages**, escolher **Deploy from a branch**, branch `main`,
   pasta `/ (root)` e salvar.
4. A URL será `https://<usuario>.github.io/<repositorio>/`. É essa URL que
   deve ser informada na Play Console.

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
