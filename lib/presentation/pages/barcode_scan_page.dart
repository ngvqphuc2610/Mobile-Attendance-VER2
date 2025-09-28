import 'package:flutter/material.dart';

class BarcodeScanPage extends StatelessWidget {
  const BarcodeScanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quét mã vạch')),
      body: const Center(
        child: Text('Chức năng quét mã vạch sẽ được phát triển ở đây.'),
      ),
    );
  }
}
