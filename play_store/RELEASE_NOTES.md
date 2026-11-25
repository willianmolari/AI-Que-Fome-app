# Ai que fome — v1.3.0

Esta versão foca no banco de dados próprio, em refeições personalizadas e nas
medidas corporais.

## Novidades

- **Banco ampliado**: 508 novos alimentos e marcas — iogurtes, leite em pó,
  sucos, Burger King, McDonald's, Demeter Burger, pratos do Posto Pelanda,
  féculas, farinhas e outros itens brasileiros. O catálogo interno agora tem
  1.261 registros únicos, sem duplicatas por nome.
- **Catálogo editável no GitHub**: o app lê um JSON público na abertura e guarda
  uma cópia local. Assim, novos alimentos podem ser adicionados ao arquivo sem
  precisar compilar e publicar um novo APK. Sem internet, o cache continua
  funcionando.
- **Busca USDA removida**: sem chave de API e sem consulta ao USDA. Continuam
  disponíveis o catálogo local, o Open Food Facts e a leitura de código de
  barras.
- **Até 4 refeições personalizadas**: nomeie e ative slots extras no diário.
  Eles só aparecem quando configurados.
- **Aba “Medidas”**: antigamente “Dobras”. Jackson & Pollock continua igual,
  porém minimizado e expansível com um toque.
- **Circunferências com fita (ISAK)**: pescoço, peito, abdômen, quadril, coxas
  e braços flexionados/relaxados, com observação, data/hora, histórico,
  carregamento e exclusão — no mesmo padrão do histórico de dobras.
- **Perfil reorganizado**: dados pessoais primeiro, depois peso e demais
  configurações.
- **Contador de água compacto**: ocupa menos espaço no diário.

## Correções

- Nomes repetidos no catálogo (carnes, whey e barras de proteína) foram
  unificados.
- Textos que citavam “Dobras” foram atualizados para “Medidas” onde necessário.

## Instalação

Baixe `app-release.apk`, permita a instalação de fontes desconhecidas no
Android e abra o arquivo. Requer Android 7.0 (API 24) ou superior.

Para atualizar a partir da v1.2.x, instale o APK por cima: diário, dobras,
medidas, peso, água e preferências são preservados. O catálogo remoto passa a
ser baixado na primeira abertura com internet.

## Arquivos desta release

- `app-release.apk` — instalação direta no Android.
- `app-release.aab` — pacote para publicação na Play Store.

## SHA-256

`app-release.apk`:
`b5a56061587c692cdec2c2beb560482b10c78d793f36eefc1097ad7a04f4d245`

`app-release.aab`:
`ba7c0267381b4d5f9569656ba201e223f4ce9e572038582173cccabf900437a3`

## Aviso

Dobras cutâneas e circunferências fornecem estimativas com erro dependente da
técnica e do equipamento. O app não fornece diagnóstico médico nem prescrição
alimentar.
