import 'package:flutter/material.dart';
import 'dart:convert';

class TotpCodeDialog {
  static Widget _buildQrImage(String qrCodeImage) {
    try {
      // Kiểm tra nếu là data URL (data:image/png;base64,...)
      if (qrCodeImage.startsWith('data:')) {
        final base64String = qrCodeImage.split(',').last;
        final imageBytes = base64Decode(base64String);
        return Image.memory(
          imageBytes,
          width: 200,
          height: 200,
          fit: BoxFit.contain,
        );
      }
      // Nếu là URL thường
      return Image.network(
        qrCodeImage,
        width: 200,
        height: 200,
        fit: BoxFit.contain,
        errorBuilder: (ctx, error, stackTrace) {
          return Container(
            width: 200,
            height: 200,
            color: Colors.grey.shade200,
            child: const Center(child: Text('Không thể tải QR code')),
          );
        },
      );
    } catch (e) {
      return Container(
        width: 200,
        height: 200,
        color: Colors.grey.shade200,
        child: const Center(child: Text('Lỗi hiển thị QR code')),
      );
    }
  }

  static Future<String?> show({
    required BuildContext context,
    required String title,
    required String message,
    String? qrCodeImage,
  }) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (ctx) {
        return AlertDialog(
          title: Text(title),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(message, style: const TextStyle(fontSize: 14)),
                  if (qrCodeImage != null) ...[
                    const SizedBox(height: 16),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _buildQrImage(qrCodeImage),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: const InputDecoration(
                      labelText: 'Mã xác thực (6 số)',
                      prefixIcon: Icon(Icons.shield_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập mã';
                      }
                      if (value.trim().length < 6) {
                        return 'Mã phải có 6 chữ số';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.of(ctx).pop(true);
                }
              },
              child: const Text('Xác nhận'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      return controller.text.trim();
    }
    return null;
  }
}
