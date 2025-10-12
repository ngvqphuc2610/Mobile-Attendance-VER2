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
      user_id,
      email,
      password,
      full_name,
      code,
      phone,
      role,
      // Student specific
      class_id,
      mssv,
      // Teacher specific
      faculty_id,
      title,
      office,
      // Actions
      reset_password,
      new_email
    } = await req.json()

    if (!user_id) {
      return new Response(
        JSON.stringify({ error: 'user_id is required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // 1. Update auth user if needed
    const authUpdates: any = {}
    
    if (new_email && new_email !== email) {
      authUpdates.email = new_email
    }
    
    if (reset_password && password) {
      authUpdates.password = password
    }

    if (Object.keys(authUpdates).length > 0) {
      const { error: authError } = await supabaseAdmin.auth.admin.updateUserById(
        user_id,
        authUpdates
      )

      if (authError) {
        return new Response(
          JSON.stringify({ error: authError.message }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }
    }

    // 2. Update profile
    const profileUpdates: any = {}
    
    if (full_name) profileUpdates.full_name = full_name
    if (code) profileUpdates.code = code.toUpperCase()
    if (phone !== undefined) profileUpdates.phone = phone || null
    if (new_email) profileUpdates.email = new_email

    if (Object.keys(profileUpdates).length > 0) {
      const { error: profileError } = await supabaseAdmin
        .from('profiles')
        .update(profileUpdates)
        .eq('id', user_id)

      if (profileError) {
        return new Response(
          JSON.stringify({ error: profileError.message }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }
    }

    // 3. Update role if changed
    if (role) {
      const { error: roleError } = await supabaseAdmin
        .from('user_roles')
        .upsert({
          user_id,
          role
        })

      if (roleError) {
        return new Response(
          JSON.stringify({ error: roleError.message }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }
    }

    // 4. Update role-specific data
    if (role === 'student') {
      const studentUpdates: any = {}
      if (class_id !== undefined) studentUpdates.class_id = class_id
      if (mssv !== undefined) studentUpdates.mssv = mssv || null

      if (Object.keys(studentUpdates).length > 0) {
        const { error: studentError } = await supabaseAdmin
          .from('students')
          .upsert({
            profile_id: user_id,
            ...studentUpdates
          })

        if (studentError) {
          return new Response(
            JSON.stringify({ error: studentError.message }),
            { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
          )
        }
      }
    } else if (role === 'teacher') {
      const teacherUpdates: any = {}
      if (faculty_id !== undefined) teacherUpdates.faculty_id = faculty_id
      if (title !== undefined) teacherUpdates.title = title || null
      if (office !== undefined) teacherUpdates.office = office || null

      if (Object.keys(teacherUpdates).length > 0) {
        const { error: teacherError } = await supabaseAdmin
          .from('teachers')
          .upsert({
            profile_id: user_id,
            ...teacherUpdates
          })

        if (teacherError) {
          return new Response(
            JSON.stringify({ error: teacherError.message }),
            { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
          )
        }
      }
    }

    return new Response(
      JSON.stringify({ 
        success: true,
        message: 'Account updated successfully' 
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
