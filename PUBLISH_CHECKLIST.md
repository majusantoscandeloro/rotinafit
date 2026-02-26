# Checklist de publicação – RotinaFit

Use este checklist antes de publicar na **Google Play** e **App Store**.

---

## ✅ Já configurado no projeto

- **Versão**: `1.0.2+4` no `pubspec.yaml` (atualize antes de cada release)
- **Firebase**: Auth + Firestore com `firebase_options.dart` e `GoogleService-Info.plist` (iOS)
- **AdMob**: Application ID e IDs de Banner/Rewarded em produção
- **Login Google (iOS)**: `REVERSED_CLIENT_ID` no `Info.plist` preenchido com o valor do `GoogleService-Info.plist`
- **Permissões**: INTERNET, POST_NOTIFICATIONS, RECEIVE_BOOT_COMPLETED, SCHEDULE_EXACT_ALARM declaradas
- **Modo desenvolvedor**: visível só em `kDebugMode` (não aparece em release)

---

## 🔴 Obrigatório antes de publicar

### 1. Assinatura de release (Android)

O `android/app/build.gradle.kts` está usando **debug signing** em release. Para a Play Store você precisa de um keystore de release.

1. Crie um keystore (se ainda não tiver):
   ```bash
   keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
2. Crie `android/key.properties` (não commite no git):
   ```properties
   storePassword=SUA_SENHA
   keyPassword=SUA_SENHA
   keyAlias=upload
   storeFile=../upload-keystore.jks
   ```
3. No `android/app/build.gradle.kts`, em `android { }`, adicione antes de `buildTypes`:
   ```kotlin
   val keystoreProperties = java.util.Properties()
   val keystoreFile = rootProject.file("key.properties")
   if (keystoreFile.exists()) keystoreProperties.load(keystoreFile.InputStream())
   ```
   e em `buildTypes { release { } }`:
   ```kotlin
   signingConfig = if (keystoreFile.exists()) {
       signingConfigs.create("release") {
           keyAlias = keystoreProperties["keyAlias"] as String?
           keyPassword = keystoreProperties["keyPassword"] as String?
           storeFile = rootProject.file(keystoreProperties["storeFile"] as String?)
           storePassword = keystoreProperties["storePassword"] as String?
       }
       signingConfigs.getByName("release")
   } else signingConfigs.getByName("debug")
   ```
4. Adicione `key.properties` e `*.jks` ao `.gitignore`.

### 2. In-app purchase (assinatura Premium)

O app já usa **compra in-app real** na tela Premium: assinatura mensal, anual e "Restaurar compras". IDs em `lib/services/iap_service.dart`: `rotinafit_premium_monthly`, `rotinafit_premium_yearly`.

**O que fazer**:

1. **Google Play Console**: Crie assinaturas com IDs `rotinafit_premium_monthly` e `rotinafit_premium_yearly`, defina preços (ex. R$ 5,90/mês e R$ 49,90/ano).
2. **App Store Connect**: Crie as mesmas assinaturas no mesmo grupo.
3. Em emulador ou sem conta de teste a tela mostra que compras não estão disponíveis; "Restaurar compras" funciona para quem já comprou.


### 3. Política de privacidade e termos

- **Google Play** e **App Store** costumam exigir link para **Política de Privacidade** (e, se aplicável, termos de uso).
- O app usa: Firebase Auth (e-mail, Google), Firestore (dados do usuário), AdMob (identificadores para anúncios). É necessário descrever isso na política e hospedar em uma URL pública.
- Inclua o link na ficha do app nas lojas e, se quiser, numa tela “Privacidade” ou “Termos” dentro do app (por exemplo no menu ou na tela de login).

### 4. Permissão de notificação no Android 13+

No Android 13 (API 33) ou superior, a permissão **POST_NOTIFICATIONS** precisa ser **solicitada em tempo de execução**. O app já declara a permissão no `AndroidManifest.xml`, mas é recomendável pedir explicitamente quando o usuário for ativar lembretes (por exemplo na tela de Lembretes).

- Pode usar o pacote `permission_handler` para `Permission.notification.request()`.
- Ou verificar na documentação do `flutter_local_notifications` se já existe API para solicitar permissão no Android 13+.

---

## 📱 iOS – O que falta configurar

### Já feito no projeto (agora)

- **Info.plist**: `ITSAppUsesNonExemptEncryption` = NO (apenas HTTPS; dispensa documentação de export compliance).
- **Info.plist**: lista completa de **SKAdNetworkItems** recomendada pelo Google para AdMob (melhor atribuição de anúncios).
- **Bundle ID**: `com.rotinafit.rotinafit`; **Signing**: Automatic (sem DEVELOPMENT_TEAM no projeto).

### Obrigatório fora do código (você faz no Apple Developer / Xcode / App Store Connect)

**Ordem:** Você pode resolver primeiro código e Xcode (item 2). Os itens 1, 3, 4 e 5 são feitos **quando for cadastrar/publicar o app** na conta Apple (criar o App ID, configurar capabilities e subir para a App Store).

1. **Apple Developer Program**  
   Conta paga e app criado em [developer.apple.com](https://developer.apple.com) com o mesmo Bundle ID: `com.rotinafit.rotinafit`.

2. **Equipe (Team) e assinatura no Xcode**  
   - Abra o projeto no Xcode: **`ios/Runner.xcworkspace`** (use o `.xcworkspace`, não o `.xcodeproj`, por causa do CocoaPods).  
   - No painel esquerdo, clique no projeto **Runner** (ícone azul no topo).  
   - Selecione o **target "Runner"** (não "RunnerTests").  
   - Aba **Signing & Capabilities**:  
     - Marque **"Automatically manage signing"**.  
     - No campo **Team**, escolha sua **Equipe** (conta Apple Developer). Se aparecer "None", clique e selecione; se sua conta não aparecer, vá em **Xcode → Settings → Accounts** e adicione seu Apple ID.  
     - O **Bundle Identifier** deve ser `com.rotinafit.rotinafit` (já está no projeto).  
   - O Xcode vai criar/baixar o **Provisioning Profile** de distribuição quando você fizer **Product → Archive** (ou ao rodar em dispositivo).  
   - *(Opcional)* Para fixar o Team no projeto (útil para CI ou para não precisar escolher de novo), anote seu **Team ID** em [developer.apple.com/account](https://developer.apple.com/account) → Membership → Team ID, e adicione no `project.pbxproj` em cada bloco `XCBuildConfiguration`: `DEVELOPMENT_TEAM = SEU_TEAM_ID;`

3. **Capabilities no App ID (developer.apple.com)** *(quando criar o app na Apple)*  
   O **App ID** é o “cadastro” do seu app na Apple (ligado ao Bundle ID `com.rotinafit.rotinafit`). As **Capabilities** são as funcionalidades que você “liga” para esse App ID (push, compras, etc.). Se não estiverem ativadas lá, push e compras in-app não funcionam em produção.  
   **Onde configurar:**  
   1. Acesse [developer.apple.com]() e entre com sua conta Apple Developer.  
   2. Vá em **Certificates, Identifiers & Profiles** → no menu lateral, **Identifiers**.  
   3. Clique no **App ID** do RotinaFit (Bundle ID `com.rotinafit.rotinafit`). Se não existir, crie um novo (App IDs) e use esse Bundle ID.  
   4. Na tela do App ID, role até **Capabilities**. Confirme que estão **marcados**:  
   - **Push Notifications** (o app usa notificações remotas).  
   - **In-App Purchase** (assinaturas Premium).  
   5. Salve (**Save**).  
   *(Se usar só Google Sign-In, “Sign in with Apple” não é obrigatório para este app.)*

4. **App Store Connect**  
   - Crie o app com o mesmo Bundle ID.  
   - Preencha: descrição, screenshots (iPhone/iPad conforme exigido), categoria, classificação etária.  
   - **Política de privacidade**: URL pública (ex.: a pasta `politicasprivacidade/` hospedada).  
   - **In-App Purchase**: crie as assinaturas `rotinafit_premium_monthly` e `rotinafit_premium_yearly` no mesmo grupo de assinaturas; defina preços (ex. R$ 5,90/mês e R$ 49,90/ano).

5. **Export compliance**  
   Com `ITSAppUsesNonExemptEncryption` = NO, na primeira submissão a App Store Connect normalmente pergunta “Does your app use encryption?” → responda conforme a realidade (geralmente “No” ou que só usa criptografia padrão).

### App Tracking Transparency (ATT) – já implementado

- **Info.plist**: `NSUserTrackingUsageDescription` com texto em português explicando o uso para anúncios.
- **Pacote**: `app_tracking_transparency`; o diálogo é exibido na primeira vez que o usuário abre a Home (após login), apenas no iOS e só se o status for “não determinado”.

---

## 🟡 Recomendações

- **cleartextTraffic**: No `AndroidManifest.xml` está `android:usesCleartextTraffic="true"`. Se todas as APIs usarem HTTPS, altere para `false` em produção.
- **App Store Connect**: Configure certificados, provisioning profiles e o app no App Store Connect; preencha descrição, screenshots, categoria e idade.
- **Google Play Console**: Crie o app, preencha store listing, política de privacidade, classificação de conteúdo e Data safety (dados coletados: e-mail, identificadores para anúncios, etc.).
- **Testes**: Rode `flutter run --release` e teste login (e-mail e Google), notificações, anúncios e fluxo de medidas/IMC em ambos os dispositivos/emuladores.

---

## Resumo rápido

| Item                         | Android | iOS |
|-----------------------------|--------|-----|
| Assinatura release          | ⬜ Fazer (keystore) | ⬜ Selecionar Team no Xcode |
| Configurar produtos IAP nas lojas | ⬜ Fazer | ⬜ Fazer (App Store Connect) |
| Política de privacidade (URL)| ⬜ Criar e colocar link | ⬜ Mesmo link na ficha do app |
| Pedir permissão notificação (Android 13+)| ⬜ Recomendado | — |
| App Store Connect (app, screenshots, categoria) | — | ⬜ Fazer |
| ATT (NSUserTrackingUsageDescription + prompt) | — | ✅ Feito |

Depois disso, o app está em condições de ser enviado para revisão nas lojas.
