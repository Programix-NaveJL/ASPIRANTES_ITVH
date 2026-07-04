// supabase/functions/generar-url-subida/index.ts
import { serve } from 'https://deno.land/std@0.224.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { AwsClient } from 'https://esm.sh/aws4fetch@1.0.17'

const R2_ACCOUNT_ID          = Deno.env.get('R2_ACCOUNT_ID')!
const R2_ACCESS_KEY_ID       = Deno.env.get('R2_ACCESS_KEY_ID')!
const R2_SECRET_ACCESS_KEY   = Deno.env.get('R2_SECRET_ACCESS_KEY')!

// Solo estos dos buckets pueden recibir subidas desde esta función.
const BUCKETS_PERMITIDOS = new Set([
  'itvh-aspirantes-perfil',
  'itvh-aspirantes-publicaciones',
])

serve(async (req) => {
  if (req.method !== 'POST') {
    return new Response('Método no permitido', { status: 405 })
  }

  // ── Verificar que quien pide el "boleto" es un usuario real logueado ──
  const authHeader = req.headers.get('Authorization')
  if (!authHeader) return new Response('No autorizado', { status: 401 })

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_ANON_KEY')!,
    { global: { headers: { Authorization: authHeader } } },
  )

  const { data: { user }, error } = await supabase.auth.getUser()
  if (error || !user) return new Response('No autorizado', { status: 401 })

  const { bucket, path, contentType } = await req.json()

  if (!BUCKETS_PERMITIDOS.has(bucket)) {
    return new Response('Bucket no permitido', { status: 400 })
  }

  // El path DEBE empezar con el id del usuario autenticado — así nadie
  // puede usar su propio "boleto" para sobreescribir archivos de otro.
  if (!path.startsWith(`${user.id}/`)) {
    return new Response('Ruta no autorizada para este usuario', { status: 403 })
  }

  const client = new AwsClient({
    accessKeyId:     R2_ACCESS_KEY_ID,
    secretAccessKey: R2_SECRET_ACCESS_KEY,
    service: 's3',
    region:  'auto',
  })

  const endpoint = `https://${R2_ACCOUNT_ID}.r2.cloudflarestorage.com/${bucket}/${path}`

  const firmada = await client.sign(endpoint, {
    method: 'PUT',
    headers: { 'Content-Type': contentType },
    aws: { signQuery: true },
  })

  return new Response(JSON.stringify({ url: firmada.url }), {
    headers: { 'Content-Type': 'application/json' },
  })
})