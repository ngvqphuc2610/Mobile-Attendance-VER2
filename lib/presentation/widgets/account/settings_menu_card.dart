import 'package:flutter/material.dart';
import '../../../core/constants/app_theme.dart';

class SettingsMenuCard extends StatelessWidget {
  final bool biometricAvailable;
  final bool isLoading;
  final bool biometricEnabled;
  final ValueChanged<bool?> onBiometricToggle;
  final VoidCallback onPersonalInfo;
  final VoidCallback onChangePassword;
  final VoidCallback onHelp;

  const SettingsMenuCard({
    super.key,
    required this.biometricAvailable,
    required this.isLoading,
    required this.biometricEnabled,
    required this.onBiometricToggle,
    required this.onPersonalInfo,
    required this.onChangePassword,
    required this.onHelp,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        side: BorderSide(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Thông tin cá nhân'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: onPersonalInfo,
          ),
          if (biometricAvailable) ...[
            const Divider(height: 1),
            if (isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else
              SwitchListTile(
                secondary: Icon(
                  Icons.fingerprint,
                  color: biometricEnabled ? AppColors.primary : null,
                ),
                title: const Text('Đăng nhập vân tay'),
                subtitle: Text(
                  biometricEnabled
                      ? '✓ Đã bật - Sử dụng vân tay để đăng nhập nhanh'
                      : 'Bật để đăng nhập nhanh hơn',
                  style: TextStyle(
                    color: biometricEnabled
                        ? Colors.green.shade700
                        : Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
                value: biometricEnabled,
                onChanged: onBiometricToggle,
              ),
          ],
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.security),
            title: const Text('Đổi mật khẩu'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: onChangePassword,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Trợ giúp'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: onHelp,
          ),
        ],
      ),
    );
  }
}