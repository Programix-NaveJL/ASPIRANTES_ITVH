const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY");
const CORREO_DESTINO = Deno.env.get("CORREO_DESTINO");
const CORREO_ORIGEN = Deno.env.get("CORREO_ORIGEN");

const MOTIVOS_LEGIBLES: Record<string, string> = {
  spam: "Spam o publicidad",
  acoso_bullying: "Acoso o bullying",
  contenido_inapropiado: "Contenido inapropiado u ofensivo",
  desinformacion: "Información falsa",
  violencia: "Violencia",
  otro: "Otro",
};

Deno.serve(async (req: Request) => {
  try {
    const payload = await req.json();
    const reporte = payload.record;

    if (!reporte) {
      return new Response(JSON.stringify({ error: "Sin registro en el payload" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }

    const motivoLegible = MOTIVOS_LEGIBLES[reporte.motivo] ?? reporte.motivo;

    const html = `
      <h2>Nuevo reporte en Comunidad ITVH</h2>
      <p><b>Motivo:</b> ${motivoLegible}</p>
      <p><b>Detalle:</b> ${reporte.detalle ?? "— sin detalle —"}</p>
      <p><b>Publicación ID:</b> ${reporte.publicacion_id}</p>
      <p><b>Autor de la publicación (ID):</b> ${reporte.autor_id}</p>
      <p><b>Reportado por (ID):</b> ${reporte.reportado_por}</p>
      <p><b>Fecha:</b> ${reporte.creado_en}</p>
    `;

    const res = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${RESEND_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        from: CORREO_ORIGEN,
        to: CORREO_DESTINO,
        subject: `Nuevo reporte: ${motivoLegible}`,
        html,
      }),
    });

    if (!res.ok) {
      const errorBody = await res.text();
      console.error("Resend rechazó el envío:", res.status, errorBody);
      return new Response(JSON.stringify({ ok: false, error: errorBody }), {
        status: 502,
        headers: { "Content-Type": "application/json" },
      });
    }

    return new Response(JSON.stringify({ ok: true }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  } catch (e) {
    console.error("Error en notificar-reporte:", e);
    return new Response(JSON.stringify({ ok: false, error: String(e) }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});