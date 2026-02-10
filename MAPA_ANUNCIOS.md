# Mapa de Anúncios — RotinaFit

Auditoria completa de anúncios (AdMob / Google Mobile Ads) no app.  
**Data:** 10/02/2025 | **Escopo:** código em `lib/`, `android/`, `ios/`.

---

## A) Mapa de Anúncios (tabela)

| Tipo | Tela/Feature | Arquivo e linha | Posição | Ad Unit ID (teste) | Ad Unit ID (produção) | Condições de exibição |
|------|--------------|-----------------|---------|--------------------|------------------------|------------------------|
| **Banner** | Home | `lib/screens/home_screen.dart:201-214` | Rodapé da lista (acima do padding final) | `ca-app-pub-3940256099942544/6300978111` | Não definido | `showAds == true` (não premium e não adsRemoved). **Nota:** na tela hoje é exibido apenas um **placeholder** ("Anúncio"); o `BannerAd` do `AdsService.getBannerAd()` **não é usado** (não há `AdWidget`). |
| **Interstitial** | Medidas (salvar check-in) | `lib/screens/measurements_screen.dart:93` | Após salvar check-in do mês, antes do SnackBar e do `pop` | `ca-app-pub-3940256099942544/1033173712` | Não definido | `showAds == true`. Chamado via `app.showInterstitialOnSave()` imediatamente após `saveMeasurements`. |
| **Interstitial** | Medidas (calcular % gordura) | `lib/screens/measurements_screen.dart:172` | Ao clicar no botão "Calcular % gordura" | `ca-app-pub-3940256099942544/1033173712` | Não definido | `showAds == true`. Intersticial abre no clique; ao fechar, `setState` para mostrar resultado. |
| **Rewarded** | Água (alterar meta) | `lib/screens/water_screen.dart:54-55` | Ao abrir o fluxo "Alterar meta" (antes do diálogo da meta) | `ca-app-pub-3940256099942544/5224354917` | Não definido | `showAds == true`. Usuário precisa assistir ao vídeo até o fim para alterar a meta; senão mostra SnackBar. |
| **Rewarded** | Lembretes personalizados (criar) | `lib/screens/custom_reminders_screen.dart:79` | Ao tocar em "Criar lembrete" quando já tem 1 lembrete (plano free) | `ca-app-pub-3940256099942544/5224354917` | Não definido | `mustWatchAdToAddCustomReminder == true` (plano free, anúncios ativos, limite de 1 lembrete). Assistir até o fim para abrir o formulário de criação. |

**App ID (plataforma):**

| Plataforma | Arquivo | Tipo | Valor atual | Produção |
|------------|---------|------|-------------|----------|
| Android | `android/app/src/main/AndroidManifest.xml:36-38` | `com.google.android.gms.ads.APPLICATION_ID` | `ca-app-pub-3940256099942544~3347511713` (teste) | Não definido |
| iOS | `ios/Runner/Info.plist` | `GADApplicationIdentifier` | **Ausente** | N/A |

**Resumo de IDs:**

- **Todos os Ad Unit IDs e o App ID do Android estão hardcoded** em:
  - `lib/services/ads_service.dart` (Banner, Interstitial, Rewarded)
  - `android/app/src/main/AndroidManifest.xml` (App ID).
- **Nenhum ID de produção** está definido; apenas IDs de **teste** do AdMob (`ca-app-pub-3940256099942544/...`).
- **iOS:** não há `GADApplicationIdentifier` no `Info.plist`; anúncios no iOS podem falhar ou não inicializar corretamente.

---

## B) Lista de problemas e riscos

### 1) Política e uso de IDs

- **IDs de teste em produção:** todos os IDs são de teste. Se o app for publicado assim, continuará exibindo anúncios de teste (política do AdMob proíbe uso de IDs de teste em app publicado).
- **App ID no Android:** `AndroidManifest` usa App ID de teste; em release é obrigatório usar o App ID real do app no AdMob.

### 2) Banner não exibido / vazamento em potencial

- **Banner na Home:** a Home mostra um **placeholder** (container com o texto "Anúncio") quando `app.showAds` é true. O método `AdsService.getBannerAd()` existe e cria um `BannerAd` com ID de teste, mas **nenhum lugar do app usa `AdWidget`** nem chama `getBannerAd()`. Ou seja, o banner real não aparece e o código do banner no service está órfão.
- **Se passarem a usar `getBannerAd()` como está:** cada chamada cria um **novo** `BannerAd` e chama `load()`, sem fazer `dispose()` do anterior → **vazamento de instâncias** e múltiplos requests.

### 3) Inicialização e lifecycle

- **MobileAds.initialize():** é chamado em `AdsService.init()` (por sua vez chamado em `AppProvider.load()`). Correto.
- **Dispose:** `AdsService.dispose()` existe e faz `dispose` de banner, intersticial e rewarded, mas **nunca é chamado**. O `AppProvider` não implementa `dispose` nem chama `_ads.dispose()`, então ao encerrar o app os ads não são liberados explicitamente (risco menor, mas recomendável fechar recursos).

### 4) UX e momento de exibição

- **Interstitial no botão "Calcular % gordura":** o anúncio abre **no mesmo momento do toque** no botão, sem delay. Pode ser percebido como intrusivo (anúncio bloqueando ação imediata). Recomenda-se considerar um pequeno delay ou exibir após o cálculo (ex.: ao fechar o resultado).
- **Interstitial após salvar medidas:** fluxo save → intersticial → fechar → SnackBar + pop é aceitável; apenas garantir que o `await showInterstitial()` não seja ignorado (hoje está correto).
- **Rewarded em Água e Lembretes:** uso condicionado à ação (alterar meta / criar lembrete) e recompensa clara está alinhado com boas práticas.

### 5) App Open e Native

- **AppOpenAd e NativeAd:** não utilizados no projeto. Nenhum risco adicional associado.

### 6) iOS

- **Info.plist:** falta a chave `GADApplicationIdentifier` com o App ID do AdMob para iOS. Sem isso, o SDK pode não inicializar corretamente no iOS.

---

## C) Sugestão de padronização

### 1) AdsService único (singleton) com init, load, cache e showX

- Garantir **uma única instância** de `AdsService` (singleton ou fornecido via injeção/Provider) para evitar múltiplas inicializações e estados duplicados.
- Manter um único ponto de entrada: `init()` (já chamado no load do app), e métodos `showInterstitial()`, `showRewardedAd()`, e para banner: por exemplo `getBannerWidget()` que retorna um `Widget` (ex.: `AdWidget` com banner em cache) em vez de criar novo `BannerAd` a cada chamada.
- **Cache de banner:** criar o `BannerAd` uma vez (ou ao primeiro uso), reutilizar a mesma instância e só fazer `dispose` no `AdsService.dispose()`. Não criar novo banner em cada `getBannerAd()`.

### 2) Centralizar Ad Unit IDs por plataforma e ambiente

- Criar um módulo de config (ex.: `lib/config/ads_config.dart` ou `lib/services/ads_config.dart`) com:
  - **Ambiente:** `kDebugMode` ou variável de ambiente (ex.: `--dart-define=ENV=prod`) para escolher teste vs produção.
  - **Por plataforma:** uso de `dart:io` `Platform.isAndroid` / `Platform.isIOS` para IDs diferentes Android/iOS se necessário.
- Exemplo de estrutura:

```dart
// ads_config.dart (exemplo)
class AdsConfig {
  static bool get useTestAds => kDebugMode; // ou const bool.fromEnvironment('PROD_ADS', defaultValue: false)
  static String get appIdAndroid => useTestAds ? 'ca-app-pub-3940256099942544~3347511713' : 'ca-app-pub-XXXXXXXX~YYYYYYYY';
  static String get appIdIos => useTestAds ? 'ca-app-pub-3940256099942544~1458002511' : 'ca-app-pub-XXXXXXXX~ZZZZZZZZ';
  static String get bannerAdUnitIdAndroid => useTestAds ? 'ca-app-pub-3940256099942544/6300978111' : 'ca-app-pub-XXXXXXXX/AAAAAAAA';
  static String get interstitialAdUnitIdAndroid => ...;
  static String get rewardedAdUnitIdAndroid => ...;
  // idem para iOS se tiver IDs diferentes
}
```

- **Android:** em build de release, o App ID pode vir de `AndroidManifest` (meta-data) com valor por build type (ex.: flavor ou `--dart-define`) para não deixar ID de produção hardcoded no repo, se desejado.
- **iOS:** adicionar no `Info.plist` a chave `GADApplicationIdentifier` com o valor de `AdsConfig.appIdIos` (ou equivalente) para o ambiente correto.

### 3) Nomes sugeridos para Ad Units no painel AdMob

- **Banner:** `RotinaFit_Banner_Home`
- **Interstitial:** `RotinaFit_Interstitial_AfterSaveMeasurements`, `RotinaFit_Interstitial_BodyFat` (ou um único intersticial reutilizado: `RotinaFit_Interstitial_Medidas`)
- **Rewarded:** `RotinaFit_Rewarded_WaterGoal`, `RotinaFit_Rewarded_CustomReminder`

Assim fica fácil identificar no AdMob onde cada unidade é usada e ajustar por tela/feature.

---

## D) Patches sugeridos (resumo)

1. **IDs e ambiente**
   - Introduzir `AdsConfig` (ou similar) com Ad Unit IDs e App IDs por plataforma e por ambiente (teste vs produção).
   - Trocar todos os usos em `ads_service.dart` e no Android (e futuramente iOS) para usar essa config.
   - Em build de release, garantir uso de IDs de produção e App ID de produção no `AndroidManifest` e no `Info.plist`.

2. **Banner**
   - Opção A: Se quiser exibir o banner de verdade na Home, usar `AdWidget` com um banner **único** criado/cacheado no `AdsService` (criar uma vez, reutilizar, fazer `dispose` no `AdsService.dispose()`).
   - Opção B: Se a decisão for não exibir banner, remover ou comentar o código de `getBannerAd()` e manter só o placeholder até haver decisão; assim evita código morto e risco de vazamento se alguém passar a chamar `getBannerAd()` no futuro.

3. **Dispose**
   - Fazer `AppProvider` implementar `dispose()` e chamar `_ads.dispose()` ao ser descartado (ou garantir que o Provider que segura o `AppProvider` dispense o valor e que esse dispose chame `_ads.dispose()`).

4. **iOS**
   - Adicionar em `ios/Runner/Info.plist` a chave `GADApplicationIdentifier` com o App ID do AdMob para iOS (teste em debug e produção em release).

5. **UX intersticial “Calcular % gordura”**
   - Avaliar exibir o intersticial **depois** do cálculo (ex.: ao fechar o card de resultado ou após um breve delay), em vez de no exato momento do toque, para reduzir sensação de bloqueio.

---

*Relatório gerado por auditoria estática do código. Nenhum comportamento do app foi alterado.*
