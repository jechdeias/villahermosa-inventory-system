// Villahermosa Inventory System — privileged-sync Edge Function
//
// Runs everything that previously required embedding the Supabase
// service-role key directly in the Flutter client. The service key never
// leaves this function; it's read from an Edge Function secret
// (SERVICE_ROLE_KEY — not SUPABASE_SERVICE_ROLE_KEY, since Supabase
// reserves the SUPABASE_ prefix for its own platform env vars), which is
// only accessible server-side.
//
// Two different trust levels, by design:
//
// - 'sync_user' with role 'customer' (the public self-signup path) needs
//   NO caller authentication at all — signup() in auth_repository.dart
//   calls this BEFORE Supabase Auth's own signUp() runs, so there is
//   usually no session yet (and if email confirmation is required, there
//   may not be one for a while). That's fine: this app's own UI already
//   lets anyone create a customer account with no privilege check, so
//   this endpoint isn't opening anything new. What it must never allow is
//   privilege escalation: `role` is only ever written when the caller is
//   independently verified as an existing admin. For anyone else the role
//   field is stripped from the payload, so an existing user's role is left
//   untouched and a new user is created as 'customer'.
//   Verification is by the caller's Supabase Auth email, looked up
//   against this app's own `users.role` — NOT anything the client sends,
//   and NOT auth.uid(), since this codebase never links a local user's
//   uuid to their Supabase Auth id anywhere.
//
// - 'sync_supplier' is reference/catalog data, not self-service — it
//   requires a genuinely valid, currently-authenticated session.

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
}

function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}

/** Resolves the caller's verified email from their session token, or null
 *  if there's no token / it isn't a valid current session. Never throws. */
async function resolveCallerEmail(
  supabaseUrl: string,
  anonKey: string,
  authHeader: string | null,
): Promise<string | null> {
  if (!authHeader) return null
  const token = authHeader.replace('Bearer ', '')
  const client = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authHeader } },
  })
  const { data, error } = await client.auth.getUser(token)
  if (error || !data?.user?.email) return null
  return data.user.email
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
    const anonKey = Deno.env.get('SUPABASE_ANON_KEY') ?? ''
    const serviceRoleKey = Deno.env.get('SERVICE_ROLE_KEY') ?? ''
    const admin = createClient(supabaseUrl, serviceRoleKey)

    const callerEmail = await resolveCallerEmail(
      supabaseUrl,
      anonKey,
      req.headers.get('Authorization'),
    )

    const { action, data } = await req.json()

    let result
    switch (action) {
      case 'sync_user': {
        // Only a verified admin may set or change `role`. Verification is by
        // the caller's Supabase Auth email against this app's own users.role.
        let callerIsAdmin = false
        if (callerEmail) {
          const { data: callerRow } = await admin
            .from('users')
            .select('role')
            .eq('email', callerEmail)
            .maybeSingle()
          callerIsAdmin = callerRow?.role === 'admin'
        }

        if (callerIsAdmin) {
          result = await admin
            .from('users')
            .upsert(
              { ...data, role: data?.role ?? 'customer' },
              { onConflict: 'uuid', ignoreDuplicates: false },
            )
        } else {
          // Not an admin: never touch `role`. Stripping it (instead of
          // forcing 'customer') means an existing user keeps whatever role
          // they already have — the old force-downgrade silently reset
          // admin/warehouse/sales_rep/delivery accounts to 'customer' on
          // every sync push. A brand-new row has no role to preserve, so
          // it's created as 'customer' (the public self-signup path can
          // never create anything else).
          // deno-lint-ignore no-unused-vars
          const { role: _ignored, ...rest } = data ?? {}
          const { data: existing } = await admin
            .from('users')
            .select('uuid')
            .eq('uuid', rest.uuid)
            .maybeSingle()
          result = await admin
            .from('users')
            .upsert(
              existing ? rest : { ...rest, role: 'customer' },
              { onConflict: 'uuid', ignoreDuplicates: false },
            )
        }
        break
      }
      case 'sync_supplier': {
        if (!callerEmail) {
          return jsonResponse({ error: 'Unauthorized' }, 401)
        }
        result = await admin
          .from('suppliers')
          .upsert(data, { onConflict: 'id', ignoreDuplicates: false })
        break
      }
      default:
        return jsonResponse({ error: 'Unknown action' }, 400)
    }

    if (result.error) throw result.error

    return jsonResponse({ success: true, data: result.data })
  } catch (error) {
    return jsonResponse({ error: (error as Error).message }, 500)
  }
})
