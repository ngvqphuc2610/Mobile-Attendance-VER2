import 'package:flutter/material.dart';

import '../../../core/constants/app_theme.dart';
import '../BiometricLoginButton.dart';
import '../../../core/services/biometric_auth.dart';

class LoginButtonsSection extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onLogin;
  final bool biometricAvailable;
  final bool biometricBusy;
  final VoidCallback? onBiometricPressed;
  final List<BiometricAccount> biometricAccounts;
  final BiometricAccount? selectedAccount;
  final VoidCallback onPickAccount;

  const LoginButtonsSection({
    super.key,
    required this.isLoading,
    required this.onLogin,
    required this.biometricAvailable,
    required this.biometricBusy,
    required this.onBiometricPressed,
    required this.biometricAccounts,
    required this.selectedAccount,
    required this.onPickAccount,
  });

  @override
  Widget build(BuildContext context) {
    final canUseBiometric =
        biometricAvailable && selectedAccount != null && !biometricBusy;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: isLoading ? null : onLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
              ),
              elevation: 0,
            ),
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  )
                : const Text(
                    'Đăng nhập',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
        if (biometricAccounts.isNotEmpty) ...[
          const SizedBox(height: 18),
          Row(
            children: [
              const Expanded(child: Divider(thickness: 1)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  'hoặc',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
              ),
              const Expanded(child: Divider(thickness: 1)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              BiometricLoginButton(
                busy: biometricBusy,
                onPressed: canUseBiometric ? onBiometricPressed : null,
                tooltip: canUseBiometric
                    ? 'Đăng nhập bằng vân tay'
                    : 'Không khả dụng',
                size: 56,
              ),
              if (biometricAccounts.length > 1) ...[
                const SizedBox(width: 12),
                ActionChip(
                  avatar: const Icon(Icons.expand_more, size: 18),
                  label: Text(
                    selectedAccount?.fullName.isNotEmpty == true
                        ? selectedAccount!.fullName
                        : (selectedAccount?.email ?? 'Chọn tài khoản'),
                    style: const TextStyle(fontSize: 13),
                  ),
                  onPressed: onPickAccount,
                ),
              ],
            ],
          ),
          if (canUseBiometric) ...[
            const SizedBox(height: 12),
            Text(
              'Chạm vào biểu tượng vân tay để đăng nhập nhanh',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ],
    );
  }
}
