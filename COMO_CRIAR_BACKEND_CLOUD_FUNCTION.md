# Como criar o backend (Cloud Function) no Firebase

O backend é uma **Cloud Function** que valida a compra com a Google Play (Android) ou App Store (iOS) e grava no Firestore a data de expiração da assinatura (`premiumUntil`). Assim o app consegue “ver” quando a pessoa não renovou (mês 1 comprou, mês 2 não).

---

## Passo a passo resumido

### 1. Instalar Node.js e Firebase CLI

- Instale **Node.js 18 ou superior**: [nodejs.org](https://nodejs.org).
- Instale o Firebase CLI e faça login:
  ```bash
  npm install -g firebase-tools
  firebase login
  ```

### 2. Inicializar Functions no projeto (se ainda não tiver)

O projeto já tem a pasta `functions/` com a função **verifyPurchase**. Só falta instalar as dependências e configurar os secrets.

Na **raiz do projeto RotinaFit**:

```bash
cd functions
npm install
npm run build
```

### 3. Configurar os “secrets” no Firebase

A função precisa de dois segredos (não vão no código, ficam no Firebase):

**a) Apple – Shared Secret (para iOS)**  
- App Store Connect → seu app → **App Information** → **App-Specific Shared Secret** (gerar ou copiar).  
- No terminal (raiz do projeto):
  ```bash
  firebase functions:secrets:set APPSTORE_SHARED_SECRET
  ```
  Cole o valor quando pedir.

**b) Google Play – Service Account (para Android)**  
- Google Cloud Console (mesmo projeto do Firebase): ative a API **Google Play Android Developer API**.  
- Crie uma **Service Account** e baixe o arquivo JSON da chave.  
- No **Google Play Console** → Users and permissions → convide o e-mail da service account com permissão **“View financial data”**.  
- No terminal:
  ```bash
  firebase functions:secrets:set PLAY_SERVICE_ACCOUNT_KEY
  ```
  Quando pedir o valor, **cole o conteúdo inteiro do arquivo JSON** da chave.

Detalhes completos: **functions/README_SETUP.md**.

### 4. Fazer o deploy da função

Na raiz do projeto:

```bash
firebase deploy --only functions
```

Depois do deploy, a função **verifyPurchase** fica disponível e o app Flutter passa a chamá-la automaticamente após cada compra ou restauração (já está integrado no app).

---

## O que a função faz

1. O **app** chama a função com: `purchaseToken` (Android) ou receipt (iOS), `productId`, `platform`, e o usuário já está autenticado (Firebase Auth).
2. A função **valida** com a Google Play ou com a App Store e obtém a **data de expiração** da assinatura.
3. A função **grava no Firestore** em `users/{uid}`: `isPremium: true`, `premiumUntil` (data em ISO), `productId`, `purchaseId`, `platform`, `premiumUpdatedAt`.
4. Na próxima vez que o usuário abrir o app, ele lê `premiumUntil` do Firestore. Se a data já tiver passado, o app trata como free (sem premium).

---

## Resumo dos arquivos

| Onde | O que |
|------|--------|
| **functions/** | Código da Cloud Function (TypeScript). |
| **functions/README_SETUP.md** | Guia completo: API Google Play, Service Account, Shared Secret Apple, deploy. |
| **lib/services/verify_purchase_service.dart** | No app: chama a função após a compra. |
| **lib/providers/app_provider.dart** | Após conceder premium, chama `VerifyPurchaseService.verifyWithBackend(...)`. |

Se algo falhar no deploy (por exemplo secret não configurado), o Firebase CLI avisa. Configure os dois secrets e rode de novo `firebase deploy --only functions`.
