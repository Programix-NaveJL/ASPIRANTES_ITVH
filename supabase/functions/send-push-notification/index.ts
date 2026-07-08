// ═════════════════════════════════════════════════════════════════
// send-push-notification — Aspirantes ITVH
//
// Se dispara vía Database Webhook cada vez que se inserta una fila
// en `notificaciones`. Busca los tokens FCM del destinatario y les
// manda un push usando la API HTTP v1 de Firebase Cloud Messaging.
// ═════════════════════════════════════════════════════════════════

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { GoogleAuth } from "https://esm.sh/google-auth-library@9";

const PROJECT_ID = Deno.env.get("FCM_PROJECT_ID")!;
const SERVICE_ACCOUNT_JSON = Deno.env.get("FCM_SERVICE_ACCOUNT")!;

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
);

function _mensajeDe(tipo: string): [string, string] {
  const mapa: Record<string, [string, string]> = {
    like: ["Nueva reacción", "Alguien reaccionó a tu publicación"],
    comentario: ["Nuevo comentario", "Alguien comentó tu publicación"],
    respuesta: ["Nueva respuesta", "Alguien respondió a tu comentario"],
    seguidor: ["Nuevo seguidor", "Alguien comenzó a seguirte"],
    like_historia: ["Nueva reacción", "Alguien reaccionó a tu historia"],
    comentario_historia: ["Nuevo comentario", "Alguien comentó tu historia"],
    like_comentario: ["Nueva reacción", "A alguien le gustó tu comentario"],
  };
  return mapa[tipo] ?? ["Aspirantes ITVH", "Tienes una nueva actualización"];
}

Deno.serve(async (req) => {
  try {
    const payload = await req.json();
    const notif = payload.record; // fila insertada en `notificaciones`

    if (!notif?.destinatario_id) {
      return new Response("sin destinatario_id", { status: 200 });
    }

    const { data: tokens, error: tokensError } = await supabase
      .from("push_tokens")
      .select("token")
      .eq("usuario_id", notif.destinatario_id);

    if (tokensError) {
      console.error("Error leyendo push_tokens:", tokensError);
      return new Response("error leyendo tokens", { status: 500 });
    }

    if (!tokens?.length) {
      return new Response("sin tokens registrados", { status: 200 });
    }

    const auth = new GoogleAuth({
      credentials: JSON.parse(SERVICE_ACCOUNT_JSON),
      scopes: ["https://www.googleapis.com/auth/firebase.messaging"],
    });
    const accessToken = await auth.getAccessToken();

    const [titulo, cuerpo] = _mensajeDe(notif.tipo);

    const resultados = await Promise.all(
      tokens.map(({ token }) =>
        fetch(
          `https://fcm.googleapis.com/v1/projects/${PROJECT_ID}/messages:send`,
          {
            method: "POST",
            headers: {
              Authorization: `Bearer ${accessToken}`,
              "Content-Type": "application/json",
            },
            body: JSON.stringify({
              message: {
                token,
                notification: { title: titulo, body: cuerpo },
                data: {
                  tipo: notif.tipo ?? "",
                  publicacion_id: notif.publicacion_id ?? "",
                  origen_id: notif.origen_id ?? "",
                },
                android: { priority: "high" },
              },
            }),
          }
        )
      )
    );

    const fallidos = resultados.filter((r) => !r.ok).length;
    return new Response(
      JSON.stringify({ enviados: tokens.length - fallidos, fallidos }),
      { status: 200, headers: { "Content-Type": "application/json" } }
    );
  } catch (err) {
    console.error("Error en send-push-notification:", err);
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500,
    });
  }
});