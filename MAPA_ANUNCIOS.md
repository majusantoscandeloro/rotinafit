# Mapa de Anúncios — RotinaFit

Auditoria dos anúncios (AdMob / Google Mobile Ads) no app.  
**Data:** 11/02/2025 | **Escopo:** código em `lib/`, `android/`, `ios/`.

---

## A) Mapa de Anúncios (tabela)

| Tipo | Tela/Feature | Arquivo e linha | Posição | Ad Unit ID (teste) | Ad Unit ID (produção) | Condições de exibição |
|------|--------------|-----------------|---------|--------------------|------------------------|------------------------|
| **Banner** | Home | `lib/screens/home_screen.dart:216-219` | Rodapé da lista (SafeArea, acima do padding final) | Debug: teste | Android **9711388654** · iOS **5544912937** (RotinaFit_Banner_Home) | `showAds == true`. Release usa produção; debug usa IDs de teste. |
| **Rewarded** | Água (alterar meta) | `lib/screens/water_screen.dart:83` | Ao escolher "Assistir vídeo e liberar" no fluxo de alterar meta | Debug: teste | Android **8295189610** · iOS **3030430231** (RotinaFit_Rewarded_WaterGoal) | `showAds == true`. Usuário assiste ao vídeo até o fim para liberar a alteração da meta; senão SnackBar. |
| **Rewarded** | Medidas (calcular % gordura) | `lib/screens/measurements_screen.dart:112` | Ao tocar em "Assistir vídeo e liberar" no diálogo "Ver percentual de gordura" | Debug: teste | Android **9595838580** · iOS **1661508248** (RotinaFit_Rewarded_BodyFat) | Quando `canViewBodyFatWithoutAd == false`. Recompensa: desbloqueio por 24h (`unlockBodyFatFor24Hours`). |
| **Rewarded** | Lembretes personalizados (criar) | `lib/screens/custom_reminders_screen.dart:79` | Ao tocar em "Criar lembrete" quando já tem 1 lembrete (plano free) | Debug: teste | Android **4020078277** · iOS **2191991286** (RotinaFit_Rewarded_CustomReminder) | `mustWatchAdToAddCustomReminder == true`. Assistir até o fim para abrir o formulário de criação. |

**Intersticial:** o `AdsService` possui `loadInterstitial()`, `showInterstitial()` e `showInterstitialOnSave()`, mas **nenhuma tela chama esses métodos**. Nenhum intersticial está em uso no app atualmente. IDs de teste disponíveis para uso futuro: Android `ca-app-pub-3940256099942544/1033173712`, iOS `ca-app-pub-3940256099942544/4411468910`.

**App ID (plataforma):**

| Plataforma | Arquivo | Tipo | Valor atual | Produção |
|------------|---------|------|-------------|----------|
| Android | `android/app/src/main/AndroidManifest.xml` | `com.google.android.gms.ads.APPLICATION_ID` | `ca-app-pub-7050795334686713~5707552704` (produção) | Definido |
| iOS | `ios/Runner/Info.plist:66-67` | `GADApplicationIdentifier` | `ca-app-pub-7050795334686713~5425483690` (produção) | Definido |

**Onde estão os IDs:**

- **Ad Unit IDs:** `lib/services/ads_service.dart` (Banner, Interstitial, Rewarded; Android e iOS com sufixos diferentes).
- **App ID Android:** `android/app/src/main/AndroidManifest.xml`.
- **App ID iOS:** `ios/Runner/Info.plist` (GADApplicationIdentifier + SKAdNetworkItems).
- **Android e iOS:** Banner e os três Rewarded têm IDs de produção em `ads_service.dart`; App IDs em `AndroidManifest.xml` (Android) e `Info.plist` (iOS). Em debug, todos usam IDs de teste.

---

## B) Lista de problemas e riscos

### 1) Política e uso de IDs

- **IDs de teste em produção:** todos os IDs são de teste. Ao publicar o app, trocar por Ad Unit IDs e App IDs reais do AdMob (política proíbe IDs de teste em app publicado).
- **Troca para produção:** ao colocar os anúncios verdadeiros, atualizar `ads_service.dart`, `AndroidManifest.xml` e `Info.plist` com os valores de produção (ou usar config por ambiente, ex.: `kDebugMode` / `--dart-define`).

### 2) Banner

- **Implementação atual:** banner é criado uma vez em cache (`getOrCreateBannerAd()`), reutilizado em `getBannerWidget()` e exibido na Home com `AdWidget`. Dispose em `AdsService.dispose()`. Sem vazamento.
- **Intersticial não usado:** o código de intersticial existe mas não é chamado por nenhuma tela. Se quiser usar (ex.: após salvar check-in de medidas), chamar `app.showInterstitialOnSave()` no fluxo desejado; caso contrário pode ignorar ou remover no futuro.

### 3) Inicialização e lifecycle

- **MobileAds.initialize():** chamado em `AdsService.init()` (por sua vez em `AppProvider.load()`). OK.
- **Dispose:** `AdsService.dispose()` existe e faz dispose de banner, intersticial e rewarded. Se o `AppProvider` for descartado (ex.: logout ou encerramento), recomenda-se chamar `_ads.dispose()` no dispose do provider.

### 4) UX

- **Rewarded (Água, % gordura, Lembretes):** uso condicionado à ação e recompensa clara está alinhado com boas práticas.
- **% gordura:** usuário escolhe no diálogo entre Cancelar, Premium ou Assistir vídeo; o rewarded só roda após "Assistir vídeo e liberar".

### 5) App Open e Native

- **AppOpenAd e NativeAd:** não utilizados no projeto.

---

## C) Sugestão de padronização (para quando colocar anúncios verdadeiros)

### 1) Centralizar IDs por ambiente

- Criar algo como `lib/config/ads_config.dart` (ou variáveis em `ads_service.dart`) com:
  - `useTestAds => kDebugMode` (ou `bool.fromEnvironment('PROD_ADS', defaultValue: false)`).
  - Por plataforma: `Platform.isAndroid` / `Platform.isIOS` para Ad Unit IDs e App IDs de teste vs produção.
- Em release, usar sempre IDs de produção.

### 2) Nomes sugeridos para Ad Units no painel AdMob (produção)

- **Banner:** `RotinaFit_Banner_Home`
- **Rewarded:** `RotinaFit_Rewarded_WaterGoal` (água), `RotinaFit_Rewarded_BodyFat` (% gordura), `RotinaFit_Rewarded_CustomReminder` (lembretes personalizados)
- **Interstitial (se passar a usar):** ex. `RotinaFit_Interstitial_Medidas` (ex.: após salvar check-in)

Assim fica fácil identificar no AdMob onde cada unidade é usada.

### 3) Checklist antes de publicar

1. Criar no AdMob o app e as unidades (Banner, Rewarded; Interstitial se for usar).
2. Substituir em `ads_service.dart` os Ad Unit IDs de teste pelos de produção (por plataforma).
3. Substituir no `AndroidManifest.xml` o `APPLICATION_ID` pelo App ID de produção.
4. Substituir no `Info.plist` o `GADApplicationIdentifier` pelo App ID de produção do iOS.
5. (Opcional) Garantir que `AdsService.dispose()` seja chamado quando o provider for descartado.

---

## D) Resumo rápido (estado atual)

| Tipo      | Em uso? | Onde |
|-----------|--------|------|
| Banner    | Sim    | Home (rodapé) |
| Interstitial | Não | Nenhuma tela |
| Rewarded  | Sim    | Água (meta), Medidas (% gordura), Lembretes personalizados (criar) |

*Documento atualizado conforme o código em 11/02/2025.*
