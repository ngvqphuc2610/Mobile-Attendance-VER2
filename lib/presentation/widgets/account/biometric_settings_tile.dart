import 'package:flutter/material.dart';
import '../../../core/constants/app_theme.dart';

class BiometricSettingsTile extends StatelessWidget {
  final bool isLoading;
  final bool biometricEnabled;
  final ValueChanged<bool?> onChanged;

  const BiometricSettingsTile({
    super.key,
    required this.isLoading,
    required this.biometricEnabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return SwitchListTile(
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
      onChanged: onChanged,
    );
  }
}