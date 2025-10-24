import 'package:flutter/material.dart';

class ComingSoonDialog {
  static Future<void> show(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sắp ra mắt'),
        content: const Text('Tính năng này sẽ được cập nhật trong phiên bản tiếp theo.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }
}