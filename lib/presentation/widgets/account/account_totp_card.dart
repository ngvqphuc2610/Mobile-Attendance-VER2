import 'package:flutter/material.dart';
import '../../../core/constants/app_theme.dart';

class AccountTotpCard extends StatelessWidget {
  final bool totpEnabled;
  final bool totpBusy;
  final bool phoneVerified;
  final String? phone;
  final VoidCallback onToggle;

  const AccountTotpCard({
    super.key,
    required this.totpEnabled,
    required this.totpBusy,
    required this.phoneVerified,
    required this.phone,
    required this.onToggle,
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
          if (totpBusy)
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
                Icons.security,
                color: totpEnabled ? AppColors.primary : null,
              ),
              title: const Text('Xác thực 2 bước'),
              subtitle: Text(
                totpEnabled
                    ? '✓ Đã bật - Bảo mật cao hơn'
                    : 'Bật để tăng cường bảo mật',
                style: TextStyle(
                  color: totpEnabled
                      ? Colors.green.shade700
                      : Colors.grey.shade600,
                  fontSize: 13,
                ),
              ),
              value: totpEnabled,
              onChanged: (_) => onToggle(),
            ),
          if (phone != null && phone!.isNotEmpty) ...[
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.phone_iphone),
              title: const Text('Số điện thoại'),
              subtitle: Text(phone!),
              trailing: Icon(
                phoneVerified
                    ? Icons.verified_outlined
                    : Icons.error_outline,
                color: phoneVerified
                    ? Colors.green
                    : Colors.orange,
              ),
            ),
          ],
        ],
      ),
    );
  }
}