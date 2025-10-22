import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_attendance/data/models/entity/session_checkin_token.dart';
import 'package:mobile_attendance/core/constants/app_theme.dart';

class TeacherQrDisplayPage extends StatelessWidget {
  final SessionCheckinToken token;

  const TeacherQrDisplayPage({super.key, required this.token});

  @override
  Widget build(BuildContext context) {
    final payload = jsonEncode({
      'session_id': token.sessionId,
      'token_id': token.id,
      'nonce': token.nonce,
      'v': 1,
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mã QR điểm danh'),
        backgroundColor: AppTheme.adminPrimaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('MÃ 4 SỐ', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SelectableText(
              token.pin4,
              style: const TextStyle(
                fontSize: 40,
                letterSpacing: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            QrImageView(data: payload, size: 260),
            const SizedBox(height: 16),
            Text(
              'Hết hạn lúc: ${token.expiresAt}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
