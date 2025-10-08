import 'package:supabase_flutter/supabase_flutter.dart';

enum AppRole { student, teacher, admin }

Future<AppRole?> fetchUserRole() async {
  final supa = Supabase.instance.client;
  final user = supa.auth.currentUser;
  if (user == null) return null;

  // 1) Ưu tiên lấy role từ bảng user_roles
  try {
    final roleRow = await supa
        .from('user_roles')
        .select('role')
        .eq('user_id', user.id)
        .maybeSingle();
    final tableRole = roleRow?['role'] as String?;
    if (tableRole != null) {
      switch (tableRole) {
        case 'teacher':
          return AppRole.teacher;
        case 'admin':
          return AppRole.admin;
        default:
          return AppRole.student;
      }
    }
  } catch (_) {
    // Ignore errors and fallback
  }

  // 2) Fallback: user metadata (nếu có set role trong auth)
  final metaRole = user.userMetadata?['role'] as String?;
  if (metaRole != null) {
    switch (metaRole) {
      case 'teacher':
        return AppRole.teacher;
      case 'admin':
        return AppRole.admin;
      default:
        return AppRole.student;
    }
  }

  // 3) Mặc định student
  return AppRole.student;
}

