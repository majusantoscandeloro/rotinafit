import { onCall, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import * as admin from "firebase-admin";
import { google } from "googleapis";
import * as https from "https";

admin.initializeApp();

// Secrets (configure depois do primeiro deploy):
// firebase functions:secrets:set APPSTORE_SHARED_SECRET
// firebase functions:secrets:set PLAY_SERVICE_ACCOUNT_KEY  (JSON da service account)
const appStoreSharedSecret = defineSecret("APPSTORE_SHARED_SECRET");
const playServiceAccountKey = defineSecret("PLAY_SERVICE_ACCOUNT_KEY");

const FIRESTORE_USERS = "users";
const PACKAGE_NAME = "com.rotinafit.rotinafit"; // mesmo do Android
const PRODUCT_IDS = new Set(["rotinafit_premium_monthly", "rotinafit_premium_yearly"]);

interface VerifyPurchaseData {
  purchaseToken: string;
  productId: string;
  purchaseId: string | null;
  platform: "android" | "ios";
}

/**
 * Valida a compra com a loja (Google Play ou App Store), obtém a data de expiração
 * e grava no Firestore (users/{uid}: isPremium, premiumUntil, productId, etc.).
 * Chamada pelo app Flutter após uma compra ou restauração.
 */
export const verifyPurchase = onCall(
  {
    secrets: [appStoreSharedSecret, playServiceAccountKey],
  },
  async (request): Promise<{ success: boolean; premiumUntil?: string; message?: string }> => {
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "Usuário não autenticado.");
    }
    const uid = request.auth.uid;
    const data = request.data as VerifyPurchaseData | undefined;
    if (!data?.purchaseToken || !data?.productId || !data?.platform) {
      throw new HttpsError(
        "invalid-argument",
        "Envie purchaseToken, productId e platform (android ou ios)."
      );
    }
    if (!PRODUCT_IDS.has(data.productId)) {
      throw new HttpsError("invalid-argument", "productId inválido.");
    }

    let premiumUntil: string | undefined;
    if (data.platform === "android") {
      premiumUntil = await validateAndroidPurchase(data.purchaseToken, data.productId);
    } else if (data.platform === "ios") {
      premiumUntil = await validateIosPurchase(data.purchaseToken, data.productId);
    } else {
      throw new HttpsError("invalid-argument", "platform deve ser android ou ios.");
    }

    const db = admin.firestore();
    const userRef = db.collection(FIRESTORE_USERS).doc(uid);
    await userRef.set(
      {
        isPremium: true,
        premiumUntil: premiumUntil ?? null,
        productId: data.productId,
        purchaseId: data.purchaseId ?? null,
        platform: data.platform,
        premiumUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    // Atualiza também config/preferences para retrocompat
    await userRef.collection("config").doc("preferences").set(
      { premium: true },
      { merge: true }
    );

    return { success: true, premiumUntil: premiumUntil ?? undefined };
  }
);

async function validateAndroidPurchase(purchaseToken: string, subscriptionId: string): Promise<string | undefined> {
  try {
    const keyJson = playServiceAccountKey.value();
    const key = typeof keyJson === "string" ? JSON.parse(keyJson) : keyJson;
    const auth = new google.auth.GoogleAuth({ credentials: key });
    const androidPublisher = google.androidpublisher({ version: "v3", auth });
    const res = await androidPublisher.purchases.subscriptions.get({
      packageName: PACKAGE_NAME,
      subscriptionId,
      token: purchaseToken,
    });
    const expiry = res.data.expiryTimeMillis;
    if (expiry) {
      return new Date(Number(expiry)).toISOString();
    }
    return undefined;
  } catch (e) {
    console.error("Android validation error:", e);
    throw new HttpsError("internal", "Falha ao validar compra Android.");
  }
}

async function validateIosPurchase(receiptData: string, productId: string): Promise<string | undefined> {
  const sharedSecret = appStoreSharedSecret.value();
  const body = JSON.stringify({
    "receipt-data": receiptData,
    password: sharedSecret,
    "exclude-old-transactions": true,
  });

  const url = "https://buy.itunes.apple.com/verifyReceipt";
  const response = await postJson(url, body);
  const data = response as { status: number; latest_receipt_info?: Array<{ expires_date_ms?: string }> };

  if (data.status !== 0) {
    if (data.status === 21007) {
      return validateIosPurchaseSandbox(receiptData, productId);
    }
    console.error("Apple verifyReceipt status:", data.status);
    throw new HttpsError("internal", "Falha ao validar compra iOS.");
  }

  const latest = data.latest_receipt_info;
  if (latest && latest.length > 0) {
    const expiresMs = latest[latest.length - 1].expires_date_ms;
    if (expiresMs) {
      return new Date(Number(expiresMs)).toISOString();
    }
  }
  return undefined;
}

async function validateIosPurchaseSandbox(receiptData: string, productId: string): Promise<string | undefined> {
  const sharedSecret = appStoreSharedSecret.value();
  const body = JSON.stringify({
    "receipt-data": receiptData,
    password: sharedSecret,
    "exclude-old-transactions": true,
  });
  const response = await postJson("https://sandbox.itunes.apple.com/verifyReceipt", body);
  const data = response as { status: number; latest_receipt_info?: Array<{ expires_date_ms?: string }> };
  if (data.status !== 0) {
    throw new HttpsError("internal", "Falha ao validar compra iOS (sandbox).");
  }
  const latest = data.latest_receipt_info;
  if (latest && latest.length > 0) {
    const expiresMs = latest[latest.length - 1].expires_date_ms;
    if (expiresMs) {
      return new Date(Number(expiresMs)).toISOString();
    }
  }
  return undefined;
}

function postJson(url: string, body: string): Promise<unknown> {
  return new Promise((resolve, reject) => {
    const u = new URL(url);
    const req = https.request(
      {
        hostname: u.hostname,
        path: u.pathname,
        method: "POST",
        headers: { "Content-Type": "application/json", "Content-Length": Buffer.byteLength(body) },
      },
      (res) => {
        let data = "";
        res.on("data", (chunk) => (data += chunk));
        res.on("end", () => {
          try {
            resolve(JSON.parse(data));
          } catch {
            reject(new Error("Invalid JSON from Apple"));
          }
        });
      }
    );
    req.on("error", reject);
    req.write(body);
    req.end();
  });
}
