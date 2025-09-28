import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_theme.dart';

class DetailAccountPage extends StatefulWidget {
  const DetailAccountPage({super.key});

  @override
  State<DetailAccountPage> createState() => _DetailAccountPageState();
}

class _DetailAccountPageState extends State<DetailAccountPage> {
  Map<String, dynamic>? _profile;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) {
        setState(() {
          _error = 'Không tìm thấy thông tin tài khoản';
          _loading = false;
        });
        return;
      }
      final res = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();
      if (res == null) {
        setState(() {
          _error = 'Không tìm thấy thông tin tài khoản';
          _loading = false;
        });
        return;
      }
      setState(() {
        _profile = res;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thông tin tài khoản')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            )
          : Padding(
              padding: const EdgeInsets.all(AppSizes.paddingMedium),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.paddingMedium),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          (_profile?['full_name'] ?? 'A')[0].toUpperCase(),
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      const SizedBox(height: AppSizes.paddingMedium),
                      _buildInfoRow(
                        context,
                        'Tên:',
                        _profile?['full_name'] ?? '',
                      ),
                      _buildInfoRow(
                        context,
                        'Mã sinh viên:',
                        _profile?['code'] ?? '',
                      ),
                      _buildInfoRow(
                        context,
                        'Email:',
                        _profile?['email'] ?? '',
                      ),
                      _buildInfoRow(
                        context,
                        'Lớp:',
                        _profile?['class_id'] ?? '',
                      ),
                      _buildInfoRow(
                        context,
                        'Trạng thái:',
                        (_profile?['is_active'] ?? true)
                            ? 'Hoạt động'
                            : 'Không hoạt động',
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingSmall),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
