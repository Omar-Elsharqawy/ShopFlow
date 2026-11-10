
import { GoogleAuth } from "google-auth-library";

import {
  Auth,
  WorkersKVStoreSingle,
} from "firebase-auth-cloudflare-workers";

import { createOrder } from "./services/createOrder.js";

function getServiceAccount(env) {
  if (!env.FIREBASE_SERVICE_ACCOUNT_B64) {
    throw new Error("Missing Firebase service account");
  }

  const bytes = Uint8Array.from(
    atob(env.FIREBASE_SERVICE_ACCOUNT_B64),
    (char) => char.charCodeAt(0)
  );

  const account = JSON.parse(new TextDecoder().decode(bytes));

  if (
    account.type !== "service_account" ||
    !account.client_email ||
    !account.private_key
  ) {
    throw new Error("Invalid Firebase service account");
  }

  return account;
}

async function verifyFirebaseToken(request, env) {
  const authorization = request.headers.get("Authorization");

  if (!authorization?.startsWith("Bearer ")) {
    return null;
  }

  const token = authorization.slice(7);

  const keyStore = WorkersKVStoreSingle.getOrInitialize(
    env.PUBLIC_JWK_CACHE_KEY,
    env.PUBLIC_JWK_CACHE_KV
  );

  const auth = Auth.getOrInitialize(
    env.FIREBASE_PROJECT_ID,
    keyStore
  );

  return await auth.verifyIdToken(token);
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    // Home
    if (request.method === "GET" && url.pathname === "/") {
      return Response.json({
        success: true,
        message: "ShopFlow API is running",
      });
    }

    // Health check
    if (
      request.method === "GET" &&
      url.pathname === "/health"
    ) {
      return Response.json({
        success: true,
        firebaseConfigured: Boolean(env.FIREBASE_PROJECT_ID),
        cacheConfigured: Boolean(
          env.PUBLIC_JWK_CACHE_KEY &&
          env.PUBLIC_JWK_CACHE_KV
        ),
      });
    }

    // TEMPORARY: Local authentication test.
    // MUST remove before production deployment.
    if (
      request.method === "GET" &&
      url.pathname === "/google-auth-test"
    ) {
      if (
        url.hostname !== "localhost" &&
        url.hostname !== "127.0.0.1"
      ) {
        return Response.json(
          { success: false, message: "Not Found" },
          { status: 404 }
        );
      }

      let stage = "checking-secret";

      try {
        stage = "loading-credentials";
        const serviceAccount = getServiceAccount(env);

        stage = "creating-google-auth";
        const googleAuth = new GoogleAuth({
          credentials: serviceAccount,
          scopes: [
            "https://www.googleapis.com/auth/datastore",
          ],
        });

        stage = "getting-google-client";
        const client = await googleAuth.getClient();

        stage = "getting-access-token";
        const result = await client.getAccessToken();

        return Response.json({
          success: true,
          googleAuthWorking: Boolean(result.token),
        });
      } catch (error) {
        console.error("Google auth test failed:", {
          stage,
          errorName: error?.name || "UnknownError",
        });

        return Response.json(
          {
            success: false,
            stage,
            errorName: error?.name || "UnknownError",
          },
          { status: 500 }
        );
      }
    }

    // Firebase ID token verification
    if (
      request.method === "GET" &&
      url.pathname === "/auth-check"
    ) {
      try {
        const decodedToken = await verifyFirebaseToken(
          request,
          env
        );

        if (!decodedToken) {
          return Response.json(
            {
              success: false,
              message: "Missing Firebase ID token",
            },
            { status: 401 }
          );
        }

        return Response.json({
          success: true,
          uid: decodedToken.uid,
          message: "User authenticated",
        });
      } catch (error) {
        console.error(
          "Firebase token verification failed:",
          error?.name
        );

        return Response.json(
          {
            success: false,
            message: "Invalid Firebase ID token",
          },
          { status: 401 }
        );
      }
    }

    // Create order
    if (
      request.method === "POST" &&
      url.pathname === "/create-order"
    ) {
      let decodedToken;

      try {
        decodedToken = await verifyFirebaseToken(
          request,
          env
        );
      } catch {
        return Response.json(
          {
            success: false,
            message: "Invalid Firebase ID token",
          },
          { status: 401 }
        );
      }

      if (!decodedToken) {
        return Response.json(
          {
            success: false,
            message: "Unauthorized",
          },
          { status: 401 }
        );
      }

      let body;

      try {
        body = await request.json();
      } catch {
        return Response.json(
          {
            success: false,
            message: "Invalid JSON body",
          },
          { status: 400 }
        );
      }

      try {
        const serviceAccount = getServiceAccount(env);

        const googleAuth = new GoogleAuth({
          credentials: serviceAccount,
          scopes: [
            "https://www.googleapis.com/auth/datastore",
          ],
        });

        const client = await googleAuth.getClient();
        const result = await client.getAccessToken();

        if (!result.token) {
          throw new Error("Google access token unavailable");
        }

        return await createOrder({
          env,
          uid: decodedToken.uid,
          body,
          accessToken: result.token,
        });
      } catch (error) {
        console.error(
          "Create order request failed:",
          error?.name || "UnknownError"
        );

        return Response.json(
          {
            success: false,
            message: "Unable to process order request",
          },
          { status: 500 }
        );
      }
    }

    return Response.json(
      {
        success: false,
        message: "Not Found",
      },
      { status: 404 }
    );
  },
};
