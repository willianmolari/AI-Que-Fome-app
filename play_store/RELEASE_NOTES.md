# Ai que fome — v1.1.0

Correções e melhorias solicitadas por quem usou a v1.0.0.

## Novidades

- **Refeição correta ao adicionar**: ao tocar em “+” em café da manhã,
  almoço, jantar ou lanches, a refeição já vem selecionada no diálogo.
- **Bebidas e líquidos no catálogo**: refrigerantes (Coca-Cola, Pepsi,
  Guaraná, Fanta, Sprite e zeros), águas, sucos, néctares, energéticos,
  isotônicos e bebidas vegetais. Leite agora é medido em **ml**.
- **Filtro “Líquidos” funcional**: encontra qualquer alimento medido em ml,
  inclusive os cadastrados manualmente.
- **Contador de água** no diário, com metas configuráveis no perfil e
  atalhos de 200/300/500 ml (valor fica salvo por dia).
- **% de gordura automático**: o perfil passa a usar o resultado do último
  Jackson-Pollock salvo, com botão para sincronizar manualmente.
- **Cadastro manual de alimentos**: informe nome, marca, porção, unidade
  (g/ml), categoria e valores nutricionais. O alimento fica em “Meus
  alimentos” e pode ser excluído.
- **Leitura de código de barras**: use a câmera para consultar o Open Food
  Facts. Se o produto não existir, você é convidado a cadastrá-lo.
- **Aviso de atualização**: ao abrir o app (ou em Perfil → Verificar
  atualização), ele consulta o GitHub Releases e oferece o download do APK.

## Correções

- Alimentos adicionados pelo diário não caíam sempre em “Café da manhã”.
- Refrigerantes e líquidos ausentes ou sem unidade adequada no catálogo.
- Filtros de categoria não retornavam bebidas.

## Instalação

Baixe `app-release.apk`, permita a instalação de fontes desconhecidas no
Android e abra o arquivo. Requer Android 7.0 (API 24) ou superior.

Para atualizar a partir da v1.0.0, basta instalar o APK por cima: os dados
locais do diário, dobras e peso são preservados.

## Arquivos desta release

- `app-release.apk` — instalação direta no Android.
- `app-release.aab` — pacote para publicação na Play Store.

## SHA-256

`app-release.apk`:
`dff507a4062c5ee4ad6732fd0c0a9ed81ea965055f3f490b2f675b2dc04096b5`

`app-release.aab`:
`5bafec90d28a74981bdf6724eb19f1d197702560633502784ac6e2ba3f27b46a`

## Aviso

Dobras cutâneas fornecem uma estimativa com erro típico de ±3–4% e não
substituem avaliação profissional. O app não fornece diagnóstico médico.
