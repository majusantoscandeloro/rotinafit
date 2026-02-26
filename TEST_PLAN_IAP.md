# Plano de testes – IAP Premium (RotinaFit)

## Trechos de código relevantes

### 1) Android: acknowledgement (completePurchase quando pendingCompletePurchase)

**Arquivo:** `lib/services/iap_service.dart`

```dart
void _completePurchaseIfNeeded(PurchaseDetails purchase) {
  if (purchase.pendingCompletePurchase) {
    _iap.completePurchase(purchase);
  }
}
```

- Em `_onPurchaseUpdates`, para `purchased` e `restored` (após validar e chamar `onPremiumGranted`) chama-se `_completePurchaseIfNeeded(purchase)`.
- Para `error` e `canceled` também se chama `_completePurchaseIfNeeded` para limpar estado.
- Sem esse acknowledgement o Google Play pode reembolsar a compra após alguns dias.

### 2) Assinatura: isPremium depende de premiumUntil

**Arquivo:** `lib/services/firestore_service.dart`

```dart
/// isPremium efetivo: flag true E (premiumUntil == null OU now < premiumUntil).
Future<bool> isPremium() async {
  final fields = await getPremiumFields();
  if (fields != null) {
    if (!fields.isPremiumFlag) return false;
    if (fields.premiumUntil == null || fields.premiumUntil!.isEmpty) return true;
    final until = DateTime.tryParse(fields.premiumUntil!);
    if (until != null && DateTime.now().isAfter(until)) return false;
    return true;
  }
  // fallback preferences
}
```

- Documento do usuário: `users/{uid}` com `isPremium`, `premiumUntil` (ISO8601), `productId`, `purchaseId`, `platform`, `premiumUpdatedAt`.
- Se `premiumUntil` estiver no passado, `isPremium()` retorna `false`.

### 3) Cancelamento/expiração no bootstrap

**Arquivo:** `lib/providers/app_provider.dart` (em `load()`)

```dart
final premiumStatus = await _premiumRepo.getPremiumStatus(_firestore);
_isPremium = premiumStatus.isPremium;
if (premiumStatus.isPremium &&
    premiumStatus.premiumUntil != null &&
    premiumStatus.premiumUntil!.isNotEmpty) {
  final until = DateTime.tryParse(premiumStatus.premiumUntil!);
  if (until != null && DateTime.now().isAfter(until)) {
    await _premiumRepo.setPremium(_firestore, false);
    _isPremium = false;
  }
}
```

- Ao abrir o app, se o status for premium e existir `premiumUntil` já passado, premium é desativado no Firestore e no cache e `_isPremium` é setado para `false`.

### 4) Restore no bootstrap (throttle 24h)

**Arquivo:** `lib/providers/app_provider.dart` (em `load()`)

```dart
final lastRestore = await _storage.getLastRestoreAtMs();
const throttleMs = 24 * 60 * 60 * 1000;
if (lastRestore == null || (DateTime.now().millisecondsSinceEpoch - lastRestore) > throttleMs) {
  await _storage.setLastRestoreAtMs(DateTime.now().millisecondsSinceEpoch);
  _iap.restorePurchases();
}
```

- Restore automático só roda se nunca tiver rodado ou se a última execução foi há mais de 24h.
- Chave em SharedPreferences: `rotinafit_last_restore_at_ms`.

### 5) Fonte da verdade: Firestore sobrescreve cache

**Arquivo:** `lib/repositories/premium_repository.dart`

```dart
Future<PremiumStatus> getPremiumStatus(FirestoreService? firestore) async {
  if (firestore != null && firestore.isAvailable) {
    try {
      final effective = await firestore.isPremium();
      final fields = await firestore.getPremiumFields();
      await _storage.setPremium(effective);  // Firestore sobrescreve cache
      return PremiumStatus(isPremium: effective, premiumUntil: fields?.premiumUntil, ...);
    } catch (e) { ... }
  }
  final local = await _storage.isPremium();  // fallback offline
  return PremiumStatus(isPremium: local, ...);
}
```

- Com Firestore disponível: lê do Firestore, calcula `effective` (incluindo `premiumUntil`) e grava no cache.
- Sem Firestore: usa só o cache como fallback.

### 6) AdMob: não inicializar quando premium

**Arquivo:** `lib/services/ads_service.dart`

```dart
Future<void> init() async {
  final premium = await _storage.isPremium();
  _showAds = !premium;
  if (premium) return;  // não chama MobileAds.initialize() nem load*
  await MobileAds.instance.initialize();
  loadRewardedWaterAd();
  loadRewardedBodyFatAd();
  loadRewardedCustomReminderAd();
}
```

- Se premium: não inicializa o SDK e não carrega banner nem rewarded.
- `getOrCreateBannerAd()` retorna `null` quando `!_showAds`; `getBannerWidget()` retorna `SizedBox.shrink()`.

---

## Android – passos de teste

### Configuração

- **License testing:** Play Console → Setup → License testing → adicionar e-mail de teste.
- **Internal testing:** Criar release interno e instalar pelo link (ou build debug com conta de teste no dispositivo).

### 1. Compra (test account + internal testing)

1. Instalar o app (internal testing ou debug) com conta de teste na Play Store.
2. Fazer login no app (Firebase).
3. Abrir o paywall (ex.: “Conheça o Premium” na Home ou “Desbloquear com Premium” em Resultados).
4. Escolher assinatura mensal ou anual e concluir a compra (valor R$ 0,00 em license testing).
5. **Esperado:** mensagem de sucesso, anúncios somem, features premium liberadas; no Firestore `users/{uid}`: `isPremium: true`, `productId`, `purchaseId`, `platform: "android"`, `premiumUpdatedAt`.

### 2. Restaurar compras

1. Com uma compra já feita, desinstalar o app.
2. Reinstalar e fazer login com o mesmo usuário.
3. Abrir o app (bootstrap pode chamar restore após throttle).
4. Ou: abrir paywall e tocar em “Restaurar compras”.
5. **Esperado:** volta a ficar premium; snackbar “Compra restaurada. Você é Premium!” se aplicável.

### 3. Trocar conta (Play / Firebase)

1. Na Play Store, trocar para outra conta (ou outro device com outra conta).
2. No app, fazer logout e login com outro usuário Firebase.
3. **Esperado:** novo usuário inicia como free; se esse usuário tiver compra na nova conta Play, usar “Restaurar compras” para ativar premium para ele.

### 4. Reembolso (quando possível)

1. No Play Console (ou Google Play padrão), solicitar reembolso do teste (se disponível).
2. Ou usar uma assinatura de teste que expire.
3. **Esperado:** quando a loja reportar cancelamento/expiração, o app pode continuar premium até o próximo bootstrap que lê `premiumUntil` (ou até você implementar Real-time Developer Notifications e atualizar `premiumUntil` no backend). Para teste manual, alterar no Firestore `premiumUntil` para uma data no passado e reabrir o app: deve desativar premium e voltar a mostrar anúncios.

### 5. Throttle de restore

1. Abrir o app (dispara restore se passou 24h ou primeira vez).
2. Fechar e reabrir o app em seguida.
3. **Esperado:** restore não é chamado de novo na segunda abertura (throttle 24h).

### 6. AdMob com premium

1. Com usuário premium, reiniciar o app.
2. **Esperado:** nenhum banner na Home; nenhuma chamada de rewarded ao tentar ações que pedem vídeo (ou vídeo não carrega). Em `AdsService.init()`, com premium o código retorna antes de `MobileAds.instance.initialize()` e dos `load*`.

---

## iOS – passos de teste

### Configuração

- **Sandbox:** App Store Connect → Users and Access → Sandbox → criar Sandbox Tester.
- No device: Settings → App Store → sair da conta; ao comprar, usar conta sandbox quando solicitado.

### 1. Compra (sandbox tester)

1. Instalar o app (debug ou TestFlight) e fazer login (Firebase).
2. Abrir o paywall e escolher assinatura mensal ou anual.
3. Quando a App Store pedir conta, usar o Sandbox Tester.
4. Concluir a compra.
5. **Esperado:** premium ativado, anúncios somem; Firestore com `isPremium: true`, `platform: "ios"`, etc.

### 2. Restaurar compras

1. Desinstalar o app, reinstalar e fazer login com o mesmo usuário.
2. Abrir paywall → “Restaurar compras”.
3. **Esperado:** premium restaurado e snackbar de confirmação.

### 3. Renovar (sandbox)

1. Assinaturas em sandbox renovam em intervalo reduzido (ex.: 1 semana → 3 min).
2. Deixar o app em background ou fechar e reabrir após “renovação”.
3. **Esperado:** continua premium; quando houver `premiumUntil` no Firestore (se implementado via backend), o app deve respeitar essa data.

### 4. Cancelar (sandbox)

1. Em Settings → Apple ID → Subscriptions (ou sandbox), cancelar a assinatura do app.
2. Aguardar o fim do período pago (sandbox encurta).
3. Reabrir o app após expiração.
4. **Esperado:** se o backend/ Firestore tiver `premiumUntil` atualizado (ex.: via server notifications), no próximo bootstrap `isPremium()` retorna false e o app desativa premium e mostra anúncios. Para teste manual, definir `premiumUntil` no passado no Firestore e reabrir o app.

---

## Checklist rápido

| Item | Android | iOS |
|------|---------|-----|
| Compra com conta de teste / sandbox | ☐ | ☐ |
| Restore após reinstalar | ☐ | ☐ |
| Trocar conta (Play/Apple e Firebase) | ☐ | ☐ |
| Reembolso / cancelamento e expiração | ☐ | ☐ |
| Throttle restore (1x em 24h) | ☐ | ☐ |
| Premium → sem banner, sem init AdMob | ☐ | ☐ |
| premiumUntil no passado → desativa no bootstrap | ☐ | ☐ |
