import 'package:flutter/material.dart';

import '../../../core/constants/app_theme.dart';

class RegisterOtpStep extends StatelessWidget {
  final TextEditingController otpController;
  final int secondsRemaining;
  final int resendCountdown;
  final bool isSubmitting;
  final VoidCallback onSubmit;
  final VoidCallback onResend;
  final VoidCallback onBack;
  final String maskedPhone;

  const RegisterOtpStep({
    super.key,
    required this.otpController,
    required this.secondsRemaining,
    required this.resendCountdown,
    required this.isSubmitting,
    required this.onSubmit,
    required this.onResend,
    required this.onBack,
    required this.maskedPhone,
  });

  String get _countdownText {
    if (secondsRemaining <= 0) return 'Mã OTP đã hết hạn. Vui lòng gửi lại mã.';
    final minutes = (secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final secs = (secondsRemaining % 60).toString().padLeft(2, '0');
    return 'OTP sẽ hết hạn sau $minutes:$secs';
  }

  @override
  Widget build(BuildContext context) {
    final resendText = resendCountdown > 0
        ? 'Gửi lại sau ${resendCountdown}s'
        : 'Gửi lại mã';
    final countdownColor =
        secondsRemaining > 0 ? Colors.grey.shade700 : Colors.red;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Xác thực OTP',
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Text(
          'Nhập mã gồm 6 chữ số đã được gửi tới số $maskedPhone.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        TextField(
          controller: otpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: const InputDecoration(
            labelText: 'Mã OTP',
            prefixIcon: Icon(Icons.sms_outlined),
          ),
          onSubmitted: (_) => onSubmit(),
        ),
        const SizedBox(height: 12),
        Text(
          _countdownText,
          textAlign: TextAlign.center,
          style: TextStyle(color: countdownColor),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: isSubmitting ? null : onSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: isSubmitting
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
                    'Xác nhận',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: (isSubmitting || resendCountdown > 0) ? null : onResend,
          child: Text(resendText),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: isSubmitting ? null : onBack,
          icon: const Icon(Icons.arrow_back),
          label: const Text('Quay lại'),
        ),
      ],
    );
  }
}
