# Publicação do RotinaFit – O que falta e preciso de backend?

## Preciso ter backend?

**Não é obrigatório.** Hoje o app já usa o **Firebase como “backend”**:

- **Firebase Auth** – login (e-mail e Google)
- **Firestore** – dados do usuário: medidas, lembretes, água, **status premium** (`users/{uid}`), preferências

Ou seja: autenticação e persistência já estão no Firebase. Você **não precisa** de um servidor próprio (Node, Python, etc.) para publicar.

### Backend extra (opcional)

- **Validação de compra no servidor (anti-fraude)**  
  O app já valida no dispositivo (`verificationData` não vazio). Para reforçar, você pode criar uma **Cloud Function** que:
  - Android: valida com a Google Play Developer API (usando o `purchaseToken`)
  - iOS: valida o receipt com a App Store  
  e grava `isPremium` / `premiumUntil` no Firestore.  
  A estrutura está em `lib/services/verify_purchase_service.dart` (TODO). **Dá para publicar sem isso** e ativar depois.

- **“Mês 1 comprou, mês 2 não renovou”**  
  O app **já sabe** desligar o Premium quando a data `premiumUntil` passou (está no código). O que falta é **alguém preencher** essa data: as lojas (Google/Apple) é que sabem quando a assinatura termina. Por isso, na prática, você precisa de um backend (Cloud Function) que valide a compra com a loja, pegue a data de fim e grave `premiumUntil` no Firestore. Assim o app “vê” que a pessoa não renovou na próxima vez que abrir. Detalhes em **COMO_FUNCIONA_ASSINATURA.md**.

- **Real-time Developer Notifications (Android)**  
  Quando a assinatura for cancelada ou expirada, o Google pode avisar seu backend; aí você atualiza `premiumUntil` no Firestore. Também é **opcional** para a primeira publicação.

**Resumo:** publique com o que já tem (Firebase). Backend/Cloud Function é opcional para deixar o fluxo de assinatura mais robusto depois.

---

## O que falta para publicar

Siga o **PUBLISH_CHECKLIST.md** completo. Abaixo está o resumo do que ainda falta fazer.

### Android

| O que | Onde / como |
|-------|---------------------|
| **Assinatura de release** | Criar keystore e `key.properties`, configurar no `build.gradle.kts` (ver PUBLISH_CHECKLIST.md). Sem isso a Play Store não aceita. |
| **Produtos IAP** | Play Console → Assinaturas: criar `rotinafit_premium_monthly` e `rotinafit_premium_yearly` com preços. |
| **Política de privacidade** | Texto em `politicasprivacidade/`; **hospedar em URL pública** (GitHub Pages, seu site, etc.) e colocar o link na ficha do app na Play Store. |
| **Permissão de notificação (Android 13+)** | O app declara `POST_NOTIFICATIONS`; o ideal é **pedir em runtime** quando o usuário for ativar lembretes (ex.: com `permission_handler` ou API do `flutter_local_notifications` para Android 13+). |
| **Data safety** | Na Play Console, preencher quais dados são coletados (e-mail, identificadores para anúncios, dados no Firestore). |
| **cleartextTraffic** | Se tudo for HTTPS, pode setar `android:usesCleartextTraffic="false"` no `AndroidManifest.xml`. |

### iOS

| O que | Onde / como |
|-------|---------------------|
| **Apple Developer + Team no Xcode** | Conta paga; no Xcode (Runner → Signing) selecionar seu **Team**. |
| **Capabilities no App ID** | No developer.apple.com, no App ID do app: ativar **Push Notifications** e **In-App Purchase**. |
| **App Store Connect** | Criar o app, descrição, screenshots (iPhone/iPad), categoria, classificação etária, **link da política de privacidade**. |
| **IAP na App Store** | Criar assinaturas `rotinafit_premium_monthly` e `rotinafit_premium_yearly` no mesmo grupo; preços. |
| **Export compliance** | Na submissão, responder sobre uso de criptografia (com `ITSAppUsesNonExemptEncryption = NO` costuma ser “No” ou criptografia padrão). |

### Nos dois

- **Política de privacidade**: mesma URL nas duas lojas; conteúdo deve citar Firebase (Auth, Firestore), AdMob e, se usar, dados de compra.
- **Testes em release**: rodar `flutter run --release` e testar login, notificações, anúncios, compra/restauração e fluxo de medidas/IMC.

---

## Ordem sugerida

1. **Assinatura Android** (keystore) e **Team iOS** (Xcode).
2. **Produtos IAP** nas duas lojas (para a tela Premium funcionar em produção).
3. **Política de privacidade** redigida e publicada em URL; link na ficha do app em ambas as lojas.
4. (Recomendado) **Pedir permissão de notificação no Android 13+** ao ativar lembretes.
5. Preencher **store listing** (descrição, screenshots, categoria, Data safety / classificação).
6. Enviar para revisão.

Depois de publicado, você pode evoluir com: Cloud Function para validar compras, Real-time Developer Notifications para expiração de assinatura, etc.
