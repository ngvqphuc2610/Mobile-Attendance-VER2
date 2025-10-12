import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // ✅ Import dotenv

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
  DateTime? _biometricTimeout; // ✅ Thêm timeout tracking
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

      // Check biometric cho user hiện tại
      final enabled = await _secure.read(
        key: 'biometric_enabled_${user.id}',
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
                          await _secure.delete(
                            key: 'biometric_last',
                            aOptions: _aOpts,
                            iOptions: _iOpts,
                          );
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
      // ✅ Kiểm tra timeout trước
      if (_biometricTimeout != null) {
        final remaining = _biometricTimeout!.difference(DateTime.now());
        if (remaining.inSeconds > 0) {
          final minutes = remaining.inMinutes;
          final seconds = remaining.inSeconds % 60;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Vui lòng đợi ${minutes}:${seconds.toString().padLeft(2, '0')} để thử lại',
              ),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        } else {
          // Timeout hết, reset
          _biometricTimeout = null;
        }
      }

      // Kiểm tra thiết bị hỗ trợ
      final supported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      if (!supported || !canCheck) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thiết bị không hỗ trợ sinh trắc học')),
        );
        return;
      }

      // Yêu cầu quyền và xác thực lần đầu
      final ok = await _auth.authenticate(
        localizedReason: 'Xác thực để bật đăng nhập vân tay',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      if (!ok) return;

      // ✅ Hiển thị dialog với retry logic
      await _showPasswordDialog();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể bật vân tay: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showPasswordDialog() async {
    final passwordController = TextEditingController();
    int attemptCount = 0;
    const maxAttempts = 3;

    while (attemptCount < maxAttempts) {
      final result = await showDialog<String?>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Bật đăng nhập vân tay'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                attemptCount > 0 
                  ? 'Mật khẩu không đúng! Còn ${maxAttempts - attemptCount} lần thử.'
                  : 'Nhập mật khẩu hiện tại để xác nhận bật tính năng đăng nhập vân tay.',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_outline),
                  errorText: attemptCount > 0 ? 'Mật khẩu không đúng' : null,
                ),
                obscureText: true,
                autofocus: true,
                onSubmitted: (value) => Navigator.pop(ctx, value),
              ),
              const SizedBox(height: 12),
              const Text(
                'Thông tin sẽ được mã hóa và lưu an toàn trên thiết bị.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, passwordController.text),
              child: const Text('Xác nhận'),
            ),
          ],
        ),
      );

      // User hủy
      if (result == null) return;

      // Password rỗng
      if (result.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng nhập mật khẩu!'),
            backgroundColor: Colors.orange,
          ),
        );
        continue;
      }

      // ✅ Hiển thị loading khi kiểm tra password
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Lấy user hiện tại
      final user = Supabase.instance.client.auth.currentUser;
      final userId = user?.id;
      final email = user?.email;

      if (userId == null || email == null) {
        Navigator.pop(context); // Đóng loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không tìm thấy thông tin người dùng'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Kiểm tra mật khẩu
      final isValid = await _verifyPassword(email, result);
      
      // Đóng loading
      if (!mounted) return;
      Navigator.pop(context);

      if (isValid) {
        // ✅ Password đúng - lưu biometric
        await _saveBiometricData(userId, email, result);

        setState(() => _biometric = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã bật đăng nhập vân tay thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        return;
      } else {
        // ❌ Password sai
        attemptCount++;
        
        // ✅ Xóa text trong form
        passwordController.clear();
        
        if (attemptCount >= maxAttempts) {
          // ✅ Hết lần thử - set timeout 3 phút
          _biometricTimeout = DateTime.now().add(const Duration(minutes: 3));
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Đã nhập sai 3 lần! Vui lòng đợi 3 phút để thử lại.',
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
          return;
        }
        
        // Còn lần thử - hiển thị thông báo và tiếp tục loop
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Mật khẩu không đúng! Còn ${maxAttempts - attemptCount} lần thử.',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
        
        // Đợi 1 giây trước khi hiện dialog tiếp theo
        await Future.delayed(const Duration(seconds: 1));
      }
    }
  }

  Future<bool> _verifyPassword(String email, String password) async {
    try {
      // ✅ Lấy từ dotenv (nếu bạn dùng flutter_dotenv)
      final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
      final supabaseKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

      // Kiểm tra xem có load được env không
      if (supabaseUrl.isEmpty || supabaseKey.isEmpty) {
        debugPrint('⚠️ Supabase credentials not found in .env file');
        return false;
      }

      // Tạo client test hoàn toàn riêng biệt
      final testClient = SupabaseClient(supabaseUrl, supabaseKey);

      final testResponse = await testClient.auth.signInWithPassword(
        email: email,
        password: password,
      );

      // Đăng xuất test session ngay
      await testClient.auth.signOut();
      
      // Giải phóng resources
      testClient.dispose();

      return testResponse.user != null;
    } catch (e) {
      debugPrint('Password verification error: $e');
      return false;
    }
  }

  Future<void> _saveBiometricData(
    String userId,
    String email,
    String password,
  ) async {
    final session = Supabase.instance.client.auth.currentSession;

    await _secure.write(
      key: 'biometric_enabled_$userId',
      value: 'true',
      aOptions: _aOpts,
      iOptions: _iOpts,
    );
    await _secure.write(
      key: 'refresh_token_$userId',
      value: session?.refreshToken ?? '',
      aOptions: _aOpts,
      iOptions: _iOpts,
    );
    await _secure.write(
      key: 'biometric_email_$userId',
      value: email,
      aOptions: _aOpts,
      iOptions: _iOpts,
    );
    await _secure.write(
      key: 'biometric_password_$userId',
      value: password,
      aOptions: _aOpts,
      iOptions: _iOpts,
    );
  }

  Future<void> _disableBiometric() async {
    final user = Supabase.instance.client.auth.currentUser;
    final userId = user?.id;
    if (userId == null) return;

    // Xóa data của user hiện tại
    await _secure.delete(
      key: 'biometric_enabled_$userId',
      aOptions: _aOpts,
      iOptions: _iOpts,
    );
    await _secure.delete(
      key: 'refresh_token_$userId',
      aOptions: _aOpts,
      iOptions: _iOpts,
    );
    await _secure.delete(
      key: 'biometric_email_$userId',
      aOptions: _aOpts,
      iOptions: _iOpts,
    );
    await _secure.delete(
      key: 'biometric_password_$userId',
      aOptions: _aOpts,
      iOptions: _iOpts,
    );

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



