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

const AUTH_LOOKUP_PER_PAGE = 200
// 50 pages x 200 = 10,000 accounts. Hitting this is an error, not "not found":
// returning null there would make upsert_auth_user try createUser for a user
// that exists, and make ban/unban silently do nothing.
const AUTH_LOOKUP_MAX_PAGES = 50

/** Finds an auth.users row by email, case-insensitively, scanning EVERY page.
 *
 *  listUsers() with no arguments returns only the first 50 users, and a lookup
 *  that only searched that page missed most of this project's ~410 accounts
 *  (upsert_auth_user then fell through to createUser and failed with "already
 *  registered"; ban/unban silently did nothing). auth.users stores emails
 *  lowercased, so both sides are lowercased for the comparison.
 *
 *  Returns null only when the user is genuinely absent (so upsert_auth_user can
 *  still create one). Throws if listUsers errors or the page cap is reached. */
async function findAuthUserByEmail(
  admin: ReturnType<typeof createClient>,
  email: string,
): Promise<{ id: string; email?: string } | null> {
  const wanted = String(email).trim().toLowerCase()
  for (let page = 1; page <= AUTH_LOOKUP_MAX_PAGES; page++) {
    const { data, error } = await admin.auth.admin.listUsers({
      page,
      perPage: AUTH_LOOKUP_PER_PAGE,
    })
    if (error) throw error
    const users = data?.users ?? []
    const hit = users.find(
      (u: { email?: string }) => (u.email ?? '').toLowerCase() === wanted,
    )
    if (hit) {
      console.log(`findAuthUserByEmail: found on page ${page} (scanned ${page} page(s))`)
      return hit
    }
    if (users.length < AUTH_LOOKUP_PER_PAGE) {
      console.log(`findAuthUserByEmail: not found after scanning ${page} page(s)`)
      return null
    }
  }
  const msg =
    `findAuthUserByEmail: scanned the ${AUTH_LOOKUP_MAX_PAGES}-page cap ` +
    `(${AUTH_LOOKUP_MAX_PAGES * AUTH_LOOKUP_PER_PAGE} users) without a result — ` +
    'auth.users has outgrown the lookup; raise AUTH_LOOKUP_MAX_PAGES or switch to a SQL lookup'
  console.error(msg)
  throw new Error(msg)
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

      // ── Supabase Auth management (requires admin caller) ─────────────────
      //
      // upsert_auth_user: create or update a Supabase Auth user.
      //   data: { email, password }
      //   Used when admin creates an account or resets a password so that
      //   fresh-install devices can authenticate via Supabase Auth.
      //
      // ban_auth_user / unban_auth_user: set ban_duration on the Auth user.
      //   data: { email }
      //   Used when admin deactivates / reactivates an account so it also
      //   blocks/allows login via Supabase Auth (not just the local flag).
      case 'upsert_auth_user': {
        if (!callerEmail) {
          return jsonResponse({ error: 'Unauthorized' }, 401)
        }
        // Verify caller is admin
        const { data: callerRow2 } = await admin
          .from('users')
          .select('role')
          .eq('email', callerEmail)
          .maybeSingle()
        if (callerRow2?.role !== 'admin') {
          return jsonResponse({ error: 'Forbidden' }, 403)
        }
        const { email: targetEmail, password: targetPassword } = data ?? {}
        if (!targetEmail || !targetPassword) {
          return jsonResponse({ error: 'email and password required' }, 400)
        }
        // Look up whether this email already exists in auth.users
        const existing = await findAuthUserByEmail(admin, targetEmail)
        if (existing) {
          // Update password (and unban in case they were banned)
          const { error: updErr } = await admin.auth.admin.updateUserById(
            existing.id,
            { password: targetPassword, ban_duration: 'none' },
          )
          if (updErr) throw updErr
        } else {
          // Create new Auth user
          const { error: createErr } = await admin.auth.admin.createUser({
            email: targetEmail,
            password: targetPassword,
            email_confirm: true,
          })
          if (createErr) throw createErr
        }
        return jsonResponse({ success: true })
      }

      case 'ban_auth_user': {
        if (!callerEmail) {
          return jsonResponse({ error: 'Unauthorized' }, 401)
        }
        const { data: callerRow3 } = await admin
          .from('users')
          .select('role')
          .eq('email', callerEmail)
          .maybeSingle()
        if (callerRow3?.role !== 'admin') {
          return jsonResponse({ error: 'Forbidden' }, 403)
        }
        const { email: targetEmail2 } = data ?? {}
        if (!targetEmail2) return jsonResponse({ error: 'email required' }, 400)
        const target = await findAuthUserByEmail(admin, targetEmail2)
        if (target) {
          const { error: banErr } = await admin.auth.admin.updateUserById(
            target.id,
            { ban_duration: '876600h' }, // 100 years ≈ permanent
          )
          if (banErr) throw banErr
        }
        // If no Auth user exists, nothing to ban — that's fine
        return jsonResponse({ success: true })
      }

      case 'unban_auth_user': {
        if (!callerEmail) {
          return jsonResponse({ error: 'Unauthorized' }, 401)
        }
        const { data: callerRow4 } = await admin
          .from('users')
          .select('role')
          .eq('email', callerEmail)
          .maybeSingle()
        if (callerRow4?.role !== 'admin') {
          return jsonResponse({ error: 'Forbidden' }, 403)
        }
        const { email: targetEmail3 } = data ?? {}
        if (!targetEmail3) return jsonResponse({ error: 'email required' }, 400)
        const target2 = await findAuthUserByEmail(admin, targetEmail3)
        if (target2) {
          const { error: unbanErr } = await admin.auth.admin.updateUserById(
            target2.id,
            { ban_duration: 'none' },
          )
          if (unbanErr) throw unbanErr
        }
        return jsonResponse({ success: true })
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
