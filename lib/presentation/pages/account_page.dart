import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_theme.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _profile;
  bool _biometric = false;
  final _auth = LocalAuthentication();
  final _secure = const FlutterSecureStorage();
  final _aOpts = const AndroidOptions(encryptedSharedPreferences: true);
  final _iOpts = const IOSOptions(
    accessibility: KeychainAccessibility.first_unlock,
  );

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final supa = Supabase.instance.client;
      final user = supa.auth.currentUser;
      if (user == null) {
        setState(() {
          _error = 'Không có người dùng đăng nhập';
          _loading = false;
        });
        return;
      }

      final res = await supa
          .from('profiles')
          .select('id, full_name, code, class_id, is_active')
          .eq('id', user.id)
          .maybeSingle();

      _profile = res ?? <String, dynamic>{};
      try {
        final roleRow = await supa
            .from('user_roles')
            .select('role')
            .eq('user_id', user.id)
            .maybeSingle();
        _profile!['role'] = roleRow?['role'] ?? user.userMetadata?['role'];
      } catch (_) {
        _profile!['role'] = user.userMetadata?['role'];
      }

      final enabled = await _secure.read(
        key: 'biometric_enabled',
        aOptions: _aOpts,
        iOptions: _iOpts,
      );
      _biometric = enabled == 'true';
      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final email = user?.email ?? '—';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tài khoản'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSizes.paddingLarge),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _avatarSection(),
                    const SizedBox(height: AppSizes.paddingLarge),
                    _infoTile(
                      title: _profile?['code']?.toString() ?? '—',
                      subtitle: 'Tài khoản truy cập cổng thông tin HUTECH',
                      leading: const Icon(Icons.badge_outlined),
                    ),
                    _infoTile(
                      title: email,
                      subtitle:
                          'Email dùng để nhận mã xác minh và các thông báo',
                      leading: const Icon(Icons.email_outlined),
                      trailing: const Icon(Icons.verified, color: Colors.green),
                    ),
                    _infoTile(
                      title: _profile?['phone']?.toString() ?? '—',
                      subtitle: 'Số điện thoại liên hệ',
                      leading: const Icon(Icons.phone_outlined),
                      trailing: const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange,
                      ),
                    ),
                    _infoTile(
                      title: _roleLabel(_profile?['role']),
                      subtitle: 'Vai trò tài khoản',
                      leading: const Icon(Icons.verified_user_outlined),
                    ),
                    const SizedBox(height: AppSizes.paddingMedium),
                    _actionTile(
                      title: 'Thay đổi mật khẩu',
                      subtitle: 'Thay đổi mật khẩu cho tài khoản',
                      leading: const Icon(Icons.lock_reset),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('TODO: Thay đổi mật khẩu'),
                          ),
                        );
                      },
                    ),
                    _switchTile(
                      title: 'Sử dụng Vân tay',
                      subtitle: 'Đăng nhập với 1 chạm',
                      value: _biometric,
                      onChanged: (v) async {
                        if (v) {
                          await _enableBiometric();
                        } else {
                          await _disableBiometric();
                        }
                      },
                    ),
                    const SizedBox(height: AppSizes.paddingLarge),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          // Chỉ xóa biometric_last, giữ lại email/password cho lần đăng nhập sau
                          await _secure.delete(key: 'biometric_last', aOptions: _aOpts, iOptions: _iOpts);
                          
                          await Supabase.instance.client.auth.signOut();
                          if (!mounted) return;
                          context.go('/login');
                        },
                        icon: const Icon(Icons.logout, color: Colors.red),
                        label: const Text(
                          'Đăng xuất tài khoản',
                          style: TextStyle(color: Colors.red),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusMedium,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _enableBiometric() async {
    try {
      final supported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      if (!supported || !canCheck) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thiết bị không hỗ trợ sinh trắc học')),
        );
        return;
      }

      final ok = await _auth.authenticate(
        localizedReason: 'Xác thực để bật đăng nhập vân tay',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      if (!ok) return;

      // Hỏi mật khẩu để lưu cho biometric login
      final user = Supabase.instance.client.auth.currentUser;
      final emailCtrl = TextEditingController(text: user?.email ?? '');
      final passCtrl = TextEditingController();
      
      final save = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Liên kết vân tay với tài khoản'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: 'Email'),
                enabled: false,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passCtrl,
                decoration: const InputDecoration(labelText: 'Nhập mật khẩu hiện tại'),
                obscureText: true,
              ),
              const SizedBox(height: 8),
              const Text(
                'Mật khẩu sẽ được mã hóa và lưu an toàn để đăng nhập bằng vân tay.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Lưu')),
          ],
        ),
      );
      
      if (save != true || passCtrl.text.isEmpty) return;

      // Bật cờ + lưu thông tin đăng nhập
      await _secure.write(
        key: 'biometric_enabled',
        value: 'true',
        aOptions: _aOpts,
        iOptions: _iOpts,
      );
      await _secure.write(
        key: 'biometric_email',
        value: emailCtrl.text.trim(),
        aOptions: _aOpts,
        iOptions: _iOpts,
      );
      await _secure.write(
        key: 'biometric_password',
        value: passCtrl.text,
        aOptions: _aOpts,
        iOptions: _iOpts,
      );

      if (!mounted) return;
      setState(() => _biometric = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã bật đăng nhập vân tay')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể bật vân tay: $e')),
      );
    }
  }

  Future<void> _disableBiometric() async {
    await _secure.delete(key: 'biometric_enabled', aOptions: _aOpts, iOptions: _iOpts);
    await _secure.delete(key: 'biometric_email', aOptions: _aOpts, iOptions: _iOpts);
    await _secure.delete(key: 'biometric_password', aOptions: _aOpts, iOptions: _iOpts);
    if (!mounted) return;
    setState(() => _biometric = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã tắt đăng nhập vân tay')),
    );
  }

  Widget _avatarSection() {
    final name = (_profile?['full_name'] ?? '—').toString();
    final initials = name.isNotEmpty
        ? name
              .trim()
              .split(RegExp(r"\s+"))
              .map((w) => w[0])
              .take(2)
              .join()
              .toUpperCase()
        : 'NA';
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 44,
              backgroundColor: AppColors.primary.withOpacity(.15),
              child: Text(
                initials,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(.1), blurRadius: 3),
                ],
              ),
              child: const Padding(
                padding: EdgeInsets.all(4.0),
                child: Icon(Icons.edit, size: 16),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.paddingMedium),
        Text(
          name,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _infoTile({
    required String title,
    required String subtitle,
    Widget? trailing,
    Widget? leading,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.paddingMedium),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        ),
        child: ListTile(
          leading: leading,
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(subtitle),
          trailing: trailing,
          onTap: () {},
        ),
      ),
    );
  }

  Widget _actionTile({
    required String title,
    required String subtitle,
    required Widget leading,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.paddingMedium),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        ),
        child: ListTile(
          leading: leading,
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      ),
    );
  }

  Widget _switchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.paddingMedium),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        ),
        child: ListTile(
          leading: const Icon(Icons.fingerprint),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(subtitle),
          trailing: Switch(value: value, onChanged: onChanged),
        ),
      ),
    );
  }

  String _roleLabel(dynamic roleRaw) {
    final r = (roleRaw ?? '').toString();
    switch (r) {
      case 'teacher':
        return 'Giảng viên';
      case 'admin':
        return 'Quản trị';
      case 'student':
      default:
        return 'Sinh viên';
    }
  }
}



