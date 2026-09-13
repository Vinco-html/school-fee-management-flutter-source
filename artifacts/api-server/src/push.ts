import { cert, getApps, initializeApp } from "firebase-admin/app";
import { getMessaging } from "firebase-admin/messaging";
import { inArray } from "drizzle-orm";
import { db, deviceTokensTable } from "@workspace/db";

function firebaseApp() {
  const serviceAccount = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  if (!serviceAccount) return null;
  if (getApps().length > 0) return getApps()[0];

  const credentials = JSON.parse(serviceAccount) as {
    project_id: string;
    client_email: string;
    private_key: string;
  };
  return initializeApp({
    credential: cert({
      projectId: credentials.project_id,
      clientEmail: credentials.client_email,
      privateKey: credentials.private_key.replace(/\\n/g, "\n"),
    }),
  });
}

export async function sendPushNotification(
  title: string,
  body: string,
  data: Record<string, string> = {},
) {
  const tokens = await db.select({ token: deviceTokensTable.token }).from(deviceTokensTable);
  if (tokens.length === 0) return;

  const app = firebaseApp();
  if (!app) {
    console.warn("Push notification skipped: FIREBASE_SERVICE_ACCOUNT_JSON is not configured");
    return;
  }

  const response = await getMessaging(app).sendEachForMulticast({
    tokens: tokens.map((item) => item.token),
    notification: { title, body },
    data,
    android: {
      notification: {
        channelId: "school-fee-alerts",
      },
    },
  });

  const invalidTokens = response.responses
    .map((result, index) => result.success ? null : tokens[index].token)
    .filter((token): token is string => token !== null);
  if (invalidTokens.length > 0) {
    await db.delete(deviceTokensTable).where(inArray(deviceTokensTable.token, invalidTokens));
  }
}
