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

    const { 
      email, 
      password, 
      full_name, 
      code, 
      role, 
      phone,
      // Student specific
      class_id,
      mssv,
      // Teacher specific
      faculty_id,
      title,
      office
    } = await req.json()

    // Validate required fields
    if (!email || !password || !full_name || !code || !role) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // 1. Create auth user
    const { data: authUser, error: authError } = await supabaseAdmin.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
      user_metadata: { role }
    })

    if (authError) {
      return new Response(
        JSON.stringify({ error: authError.message }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const userId = authUser.user.id

    // 2. Create profile
    const profileData = {
      id: userId,
      code: code.toUpperCase(),
      full_name,
      is_active: true,
      email,
      phone: phone || null
    }

    const { error: profileError } = await supabaseAdmin
      .from('profiles')
      .insert(profileData)

    if (profileError) {
      // Rollback auth user if profile creation fails
      await supabaseAdmin.auth.admin.deleteUser(userId)
      return new Response(
        JSON.stringify({ error: profileError.message }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // 3. Create user role
    const { error: roleError } = await supabaseAdmin
      .from('user_roles')
      .insert({
        user_id: userId,
        role
      })

    if (roleError) {
      // Rollback
      await supabaseAdmin.from('profiles').delete().eq('id', userId)
      await supabaseAdmin.auth.admin.deleteUser(userId)
      return new Response(
        JSON.stringify({ error: roleError.message }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // 4. Create role-specific record
    if (role === 'student') {
      const studentData = {
        profile_id: userId,
        class_id: class_id || null,
        mssv: mssv || null
      }

      const { error: studentError } = await supabaseAdmin
        .from('students')
        .insert(studentData)

      if (studentError) {
        // Rollback
        await supabaseAdmin.from('user_roles').delete().eq('user_id', userId)
        await supabaseAdmin.from('profiles').delete().eq('id', userId)
        await supabaseAdmin.auth.admin.deleteUser(userId)
        return new Response(
          JSON.stringify({ error: studentError.message }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }
    } else if (role === 'teacher') {
      const teacherData = {
        profile_id: userId,
        faculty_id: faculty_id || null,
        title: title || null,
        office: office || null
      }

      const { error: teacherError } = await supabaseAdmin
        .from('teachers')
        .insert(teacherData)

      if (teacherError) {
        // Rollback
        await supabaseAdmin.from('user_roles').delete().eq('user_id', userId)
        await supabaseAdmin.from('profiles').delete().eq('id', userId)
        await supabaseAdmin.auth.admin.deleteUser(userId)
        return new Response(
          JSON.stringify({ error: teacherError.message }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }
    }

    return new Response(
      JSON.stringify({ 
        success: true, 
        user_id: userId,
        message: 'Account created successfully' 
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
