# Checklist – Premium via In-App Purchase (IAP)

## Product IDs no código

| ID | Uso |
|----|-----|
| `rotinafit_premium_monthly` | Assinatura mensal |
| `rotinafit_premium_yearly` | Assinatura anual |

Definidos em: `lib/services/iap_service.dart` (`kProductIdMonthly`, `kProductIdYearly`).

---

## Onde configurar produtos

### Google Play Console

1. **Monetize** → **Subscriptions** (ou **In-app products** se usar produto não consumível).
2. Crie os produtos com os **mesmos IDs** acima.
3. Ative e defina preço (ex.: R$ 5,90/mês e R$ 49,90/ano).
4. **Licença de teste**: em **Setup** → **License testing** adicione e-mails de teste para compras sem cobrança real.

### App Store Connect

1. **My Apps** → seu app → **Subscriptions** (ou **In-App Purchases**).
2. Crie **Subscription Group** (ex.: "RotinaFit Premium").
3. Crie as assinaturas com os **mesmos IDs**: `rotinafit_premium_monthly`, `rotinafit_premium_yearly`.
4. **Sandbox**: use conta de teste em **Users and Access** → **Sandbox** para testar sem cobrança.

---

## Passos para testar

### Android

1. Adicione e-mail de teste em **License testing** (Play Console).
2. Instale o app em dispositivo/emulador com a conta de teste.
3. Faça uma compra: o valor será R$ 0,00 (licença de teste).
4. Teste **Restaurar compras**: desinstale, reinstale e toque em "Restaurar compras" no paywall.

### iOS

1. Crie **Sandbox Tester** em App Store Connect.
2. No dispositivo, saia da conta da App Store (Settings → App Store) e, ao comprar, use a conta sandbox quando solicitado.
3. Faça uma compra de teste (sandbox).
4. Teste **Restaurar compras** da mesma forma que no Android.

---

## Arquivos alterados/criados e motivos

| Arquivo | Motivo |
|---------|--------|
| `lib/services/iap_service.dart` | Validação anti-fraude com `verificationData.serverVerificationData`; callback `onPremiumGranted(PremiumGrantResult)` com productId, purchaseId, platform; logs. |
| `lib/services/firestore_service.dart` | Campos de premium no documento do usuário: `isPremium`, `premiumUntil`, `productId`, `purchaseId`, `platform`, `premiumUpdatedAt`; `setPremiumFromPurchase()`; `isPremium()` lê do user doc com fallback em config/preferences. |
| `lib/repositories/premium_repository.dart` | **Novo.** Camada de repositório: `getPremiumStatus(firestore)`, `setPremiumFromPurchase(firestore, ...)`, `setPremium(firestore, value)`; sincroniza Firebase + cache local. |
| `lib/providers/app_provider.dart` | Usa `PremiumRepository` para carregar e persistir premium; `_onPremiumGranted(PremiumGrantResult)` persiste via repo com dados da compra; chama `restorePurchases()` após `_iap.init()` no bootstrap para reconciliar compras locais com Firebase. |
| `lib/services/verify_purchase_service.dart` | **Novo.** Estrutura para validação no backend (Cloud Function/endpoint): `verifyWithBackend(uid, serverVerificationData, productId, purchaseId, platform)`. TODO: configurar função e chamar antes ou após persistir. |

---

## Fluxo atual

1. **App start**: `AppProvider.load()` carrega premium do Firebase (ou cache local), inicia IAP e chama `restorePurchases()` em background.
2. **Compra/restauração**: `IapService` recebe no `purchaseStream`; só concede premium se `verificationData.serverVerificationData` não vazio; chama `onPremiumGranted(PremiumGrantResult)`.
3. **Persistência**: `AppProvider._onPremiumGranted` chama `PremiumRepository.setPremiumFromPurchase(_firestore, ...)`, que grava em `users/{uid}` (e em config/preferences) e no cache local; atualiza ads e notifica a UI.
4. **AdMob**: `AdsService.updateShowAds(!isPremium)`; quando premium, banner não é exibido.
5. **Features**: `app.isPremium`, `canSeeHistory`, `canSeeCharts`, etc. controlam o que é exibido.

---

## Backend (opcional, anti-fraude forte)

Para validar compras no servidor:

- **Android**: Cloud Function (ou outro backend) usa **Google Play Developer API** (endpoint `purchases.subscriptions.get` ou equivalente) com o `purchaseToken` (serverVerificationData).
- **iOS**: Cloud Function usa **App Store Server API** (validar receipt) com o receipt enviado pelo app.

O client pode chamar `VerifyPurchaseService.verifyWithBackend(...)` após uma compra; o backend valida e grava `users/{uid}` no Firestore. O app pode então recarregar o status ou confiar na escrita do backend.
