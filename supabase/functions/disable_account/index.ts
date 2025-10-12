import { serve } from "std/http/server.ts";
import { createClient } from "@supabase/supabase-js";
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    const { user_id, action } = await req.json()

    if (!user_id || !action) {
      return new Response(
        JSON.stringify({ error: 'user_id and action are required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    if (action === 'disable') {
      // Soft delete - just disable the account
      const { error: profileError } = await supabaseAdmin
        .from('profiles')
        .update({ is_active: false })
        .eq('id', user_id)

      if (profileError) {
        return new Response(
          JSON.stringify({ error: profileError.message }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }

      return new Response(
        JSON.stringify({ 
          success: true,
          message: 'Account disabled successfully' 
        }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )

    } else if (action === 'enable') {
      // Re-enable account
      const { error: profileError } = await supabaseAdmin
        .from('profiles')
        .update({ is_active: true })
        .eq('id', user_id)

      if (profileError) {
        return new Response(
          JSON.stringify({ error: profileError.message }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }

      return new Response(
        JSON.stringify({ 
          success: true,
          message: 'Account enabled successfully' 
        }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )

    } else if (action === 'delete') {
      // Hard delete - remove everything
      
      // Delete in reverse order of creation
      // 1. Delete role-specific records
      await supabaseAdmin.from('students').delete().eq('profile_id', user_id)
      await supabaseAdmin.from('teachers').delete().eq('profile_id', user_id)
      
      // 2. Delete user role
      await supabaseAdmin.from('user_roles').delete().eq('user_id', user_id)
      
      // 3. Delete profile
      const { error: profileError } = await supabaseAdmin
        .from('profiles')
        .delete()
        .eq('id', user_id)

      if (profileError) {
        return new Response(
          JSON.stringify({ error: profileError.message }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }

      // 4. Delete auth user
      const { error: authError } = await supabaseAdmin.auth.admin.deleteUser(user_id)

      if (authError) {
        return new Response(
          JSON.stringify({ error: authError.message }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }

      return new Response(
        JSON.stringify({ 
          success: true,
          message: 'Account deleted successfully' 
        }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )

    } else {
      return new Response(
        JSON.stringify({ error: 'Invalid action. Use: disable, enable, or delete' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})