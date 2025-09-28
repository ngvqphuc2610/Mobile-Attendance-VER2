import 'package:flutter/material.dart';

class FaceScanPage extends StatelessWidget {
  const FaceScanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quét khuôn mặt')),
      body: const Center(
        child: Text('Chức năng quét khuôn mặt sẽ được phát triển ở đây.'),
      ),
    );
  }
}
