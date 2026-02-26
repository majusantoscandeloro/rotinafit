# Configuração das Cloud Functions – RotinaFit

Esta pasta contém a função **verifyPurchase**, que valida a compra com a Google Play (Android) ou com a App Store (iOS), obtém a data de expiração da assinatura e grava no Firestore (`users/{uid}`: `isPremium`, `premiumUntil`, etc.).

---

## 1. Pré-requisitos

- **Node.js 18+** instalado.
- **Firebase CLI**: `npm install -g firebase-tools` e `firebase login`.
- Projeto Firebase já usado no app (Firestore, Auth).

---

## 2. Instalar dependências das Functions

Na pasta do projeto (raiz do RotinaFit):

```bash
cd functions
npm install
npm run build
```

---

## 3. Secrets (obrigatório para a função funcionar)

A função usa dois **secrets** do Firebase. Configure depois do primeiro deploy.

### 3.1 Apple – Shared Secret (iOS)

1. Acesse [App Store Connect](https://appstoreconnect.apple.com) → seu app → **App Information** (ou **In-App Purchases**).
2. Em **App-Specific Shared Secret**, gere ou copie o **Shared Secret**.
3. No terminal (na raiz do projeto):

```bash
firebase functions:secrets:set APPSTORE_SHARED_SECRET
```

Quando pedir, cole o valor do Shared Secret e confirme.

### 3.2 Google Play – Service Account (Android)

1. **Google Cloud Console** (mesmo projeto do Firebase): [console.cloud.google.com](https://console.cloud.google.com).
2. Ative a API **Google Play Android Developer API** (APIs & Services → Enable APIs → procure por “Google Play Android Developer API”).
3. Crie uma **Service Account**:
   - IAM & Admin → Service Accounts → Create Service Account.
   - Nome: ex. `play-api-rotinafit`.
   - Crie e baixe uma **chave JSON** (Keys → Add Key → Create new key → JSON).
4. **Google Play Console** ([play.google.com/console](https://play.google.com/console)):
   - Configurações do app → **Users and permissions** → Convidar o e-mail da service account (ex. `play-api-rotinafit@rotinafit-69e71.iam.gserviceaccount.com`).
   - Conceda permissão **“View financial data”** (e, se existir, acesso a assinaturas).
5. Salve o arquivo JSON da chave em um lugar seguro. O conteúdo é um JSON (começa com `{ "type": "service_account", ... }`).
6. Defina o secret no Firebase. No terminal, na **raiz do projeto**:

```bash
firebase functions:secrets:set PLAY_SERVICE_ACCOUNT_KEY
```

Quando pedir o valor, **cole o conteúdo inteiro do arquivo JSON** (uma única linha ou múltiplas; o Firebase aceita). Confirme.

---

## 4. Package name (Android)

A função usa o package name `com.rotinafit.rotinafit`. Se o seu app Android tiver outro package name, edite em `functions/src/index.ts`:

```ts
const PACKAGE_NAME = "com.rotinafit.rotinafit"; // troque pelo seu
```

Depois faça `npm run build` dentro de `functions`.

---

## 5. Deploy

Na raiz do projeto:

```bash
firebase deploy --only functions
```

Ou, estando dentro de `functions`:

```bash
npm run build
cd ..
firebase deploy --only functions
```

Após o deploy, a função **verifyPurchase** ficará disponível como **Callable** e o app Flutter poderá chamá-la (veja no app: `VerifyPurchaseService.verifyWithBackend` e chamada após a compra).

---

## 6. Regras do Firestore (segurança)

A função usa **Admin SDK** e ignora as regras do Firestore. Garanta que **apenas a função** (e o backend) possam escrever em `users/{uid}` com dados de premium. Não exponha escrita direta nesses campos para o client. As regras atuais do Firestore devem permitir que o **usuário autenticado** leia/escreva seu próprio documento em `users/{uid}`; a função usa credenciais de admin e escreve por cima. Isso é seguro desde que o client não possa chamar nenhuma API que altere `isPremium`/`premiumUntil` diretamente — apenas a Cloud Function e o próprio fluxo de “expirar” no app (que pode escrever `false`) devem fazer isso. Opcional: em Firestore Rules, você pode restringir para que apenas o backend (via Admin) altere certos campos; para simplicidade, muitos apps confiam na chamada callable (que exige Auth).

---

## 7. Resumo dos comandos

```bash
# Na raiz do projeto RotinaFit
cd functions
npm install
npm run build

# Configurar secrets (uma vez)
firebase functions:secrets:set APPSTORE_SHARED_SECRET
firebase functions:secrets:set PLAY_SERVICE_ACCOUNT_KEY

# Deploy
cd ..
firebase deploy --only functions
```

Depois disso, o app já pode chamar a função após cada compra/restauração para preencher `premiumUntil` no Firestore.
