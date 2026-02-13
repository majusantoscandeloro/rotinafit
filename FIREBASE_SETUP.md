# Configuração do Firebase no RotinaFit

Este guia explica como configurar o Firebase (Auth + Firestore) no projeto para login e banco de dados.

---

## 1. Criar projeto no Firebase Console

1. Acesse [Firebase Console](https://console.firebase.google.com/).
2. Clique em **Adicionar projeto** (ou use um existente).
3. Siga o assistente (nome do projeto, Google Analytics opcional).
4. Anote o **ID do projeto** (ex.: `rotinafit-xxxxx`).

---

## 2. Registrar o app Android

1. No projeto Firebase, clique no ícone **Android**.
2. **ID do pacote Android:** use exatamente `com.rotinafit.rotinafit` (igual ao `applicationId` em `android/app/build.gradle.kts`).
3. **SHA-1 (importante para login com Google):** para o "Entrar com Google" funcionar no Android, adicione a impressão digital SHA-1 do seu keystore. No terminal: `cd android && ./gradlew signingReport` (ou no Windows: `gradlew.bat signingReport`) e copie o SHA-1 da variante **debug** (ou **release**, se for testar build de release). No Firebase Console → Configurações do projeto → Seus apps → Android → Adicionar impressão digital → cole o SHA-1.
4. Clique em **Registrar app**.
5. **Baixe o arquivo `google-services.json`** e coloque em:
   ```
   android/app/google-services.json
   ```
   (na pasta `app`, ao lado de `build.gradle.kts`.)

6. O plugin do Google Services já está configurado no projeto; não é preciso copiar trechos de código do assistente.

---

## 3. Registrar o app iOS

1. No projeto Firebase, clique no ícone **iOS**.
2. **ID do pacote iOS:** use o mesmo do Xcode (ex.: `com.rotinafit.rotinafit`). Confira em `ios/Runner.xcodeproj` ou no Xcode.
3. Clique em **Registrar app**.
4. **Baixe o arquivo `GoogleService-Info.plist`** e adicione ao Xcode:
   - Abra `ios/Runner.xcworkspace` no Xcode.
   - Arraste `GoogleService-Info.plist` para o grupo **Runner** (marque “Copy items if needed”).
   - Ou copie o arquivo manualmente para `ios/Runner/GoogleService-Info.plist`.

---

## 4. Ativar Authentication (login)

1. No menu lateral do Firebase, vá em **Build** → **Authentication**.
2. Clique em **Começar**.
3. Na aba **Sign-in method**, ative:
   - **E-mail/senha** (primeira opção).
   - **Google** (segunda opção): clique em Google → Ativar → escolha o e-mail de suporte do projeto → Salvar.
4. Salve.

O app usa **Firebase Auth** com e-mail/senha e **Google** em `lib/services/auth_service.dart` e na tela `lib/screens/login_screen.dart`.

### Login com Google no iOS

Para o botão "Entrar com Google" funcionar no iPhone/iPad, é preciso configurar o **URL scheme** no Xcode:

1. Abra o arquivo **`ios/Runner/GoogleService-Info.plist`** (baixado do Firebase).
2. Copie o valor da chave **`REVERSED_CLIENT_ID`** (ex.: `com.googleusercontent.apps.123456789-xxxxxxxx`).
3. Abra **`ios/Runner/Info.plist`** no Xcode ou em um editor de texto.
4. Localize a linha `<string>REVERSED_CLIENT_ID</string>` dentro de `CFBundleURLTypes`.
5. Substitua **`REVERSED_CLIENT_ID`** pelo valor copiado (ex.: `com.googleusercontent.apps.123456789-xxxxxxxx`).
6. Salve e rode o app no simulador ou dispositivo iOS.

Se não fizer essa troca, o login com Google no iOS pode falhar ou não retornar ao app após a tela do Google.

---

## 5. Ativar Firestore (banco de dados)

1. No menu lateral, vá em **Build** → **Firestore Database**.
2. Clique em **Criar banco de dados**.
3. Escolha **modo de produção** (ou modo de teste temporário para desenvolvimento).
4. Selecione a região (ex.: `southamerica-east1` para Brasil).
5. Após criar, anote a URL do banco (ex.: `https://firestore.googleapis.com/...`).

### Regras de segurança (exemplo para desenvolvimento)

Na aba **Regras**, você pode usar temporariamente (apenas para testar):

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

Isso permite que cada usuário leia/escreva apenas em `/users/{userId}/...`. Para produção, ajuste as regras conforme sua política.

### Estrutura sugerida no Firestore

Quando migrar os dados do app para o Firestore, uma estrutura por usuário pode ser:

```
users / {uid} /
  measurements   (array ou subcoleção de check-ins)
  reminders      (config de lembretes)
  customReminders
  waterProgress  (mapa data -> progresso)
  settings       (premium, adsRemoved, imcFreeViewedMonth, etc.)
```

O `StorageService` hoje usa `SharedPreferences`; você pode criar um `FirestoreStorageService` que lê/escreve nessas coleções usando `FirebaseAuth.instance.currentUser?.uid`.

---

## 6. Inicialização no app

O app chama `Firebase.initializeApp()` no `main()` **sem** parâmetros. Nesse caso, o Flutter usa:

- **Android:** `android/app/google-services.json`
- **iOS:** `ios/Runner/GoogleService-Info.plist`

Não é obrigatório usar o arquivo `firebase_options.dart` gerado pelo FlutterFire CLI, desde que os dois arquivos acima estejam no lugar certo.

---

## 7. (Opcional) FlutterFire CLI

Para gerar `lib/firebase_options.dart` e configurar vários apps (ex.: dev/prod):

1. Instale o CLI:
   ```bash
   dart pub global activate flutterfire_cli
   ```
2. No diretório do projeto:
   ```bash
   flutterfire configure
   ```
3. Faça login no Firebase e escolha o projeto. O CLI baixa os arquivos e gera `firebase_options.dart`.
4. Se quiser usar esse arquivo no código, altere o `main.dart` para:
   ```dart
   import 'firebase_options.dart';
   // ...
   await Firebase.initializeApp(
     options: DefaultFirebaseOptions.currentPlatform,
   );
   ```

---

## 8. Resumo rápido

| Etapa | Onde |
|-------|------|
| Criar projeto | [Firebase Console](https://console.firebase.google.com/) |
| Android: colocar config | `android/app/google-services.json` |
| iOS: colocar config | `ios/Runner/GoogleService-Info.plist` (via Xcode ou cópia manual) |
| Ativar login e-mail/senha | Console → Authentication → Sign-in method |
| Ativar Firestore | Console → Firestore Database → Criar banco |
| Código de login | `lib/services/auth_service.dart`, `lib/screens/login_screen.dart` |
| Provider de auth | `lib/providers/auth_provider.dart` |
| Porta de entrada (login vs home) | `lib/main.dart` → `_AuthGate` |

Depois de colocar os dois arquivos de config e ativar Auth + Firestore, rode o app: a tela de login deve aparecer e o login/registro devem funcionar. O banco Firestore pode ser usado em seguida para migrar os dados do `StorageService` para a nuvem por usuário.
