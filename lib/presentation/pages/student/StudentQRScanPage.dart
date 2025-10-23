import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScanResult {
  final String sessionId;
  final String tokenId;
  final String nonce;

  const QrScanResult({
    required this.sessionId,
    required this.tokenId,
    required this.nonce,
  });
}

class QrScanPage extends StatefulWidget {
  const QrScanPage({super.key});

  @override
  State<QrScanPage> createState() => _QrScanPageState();
}

class _QrScanPageState extends State<QrScanPage> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [BarcodeFormat.qrCode],
    facing: CameraFacing.back,
  );

  bool _handled = false;
  bool _torchOn = false;
  CameraFacing _facing = CameraFacing.back;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDetection(BarcodeCapture capture) {
    if (_handled) return;
    final Barcode? b = capture.barcodes.isNotEmpty
        ? capture.barcodes.first
        : null;
    final raw = b?.rawValue;
    if (raw == null || raw.isEmpty) return;

    try {
      final map = jsonDecode(raw);
      final sessionId = map['session_id']?.toString();
      final tokenId = map['token_id']?.toString();
      final nonce = map['nonce']?.toString();

      if (sessionId == null || tokenId == null || nonce == null) {
        _showInvalid();
        return;
      }

      _handled = true;
      Navigator.of(
        context,
      ).pop(QrScanResult(sessionId: sessionId, tokenId: tokenId, nonce: nonce));
    } catch (_) {
      _showInvalid();
    }
  }

  void _showInvalid() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mã QR không hợp lệ. Hãy quét lại.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Quét mã QR'),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            tooltip: _torchOn ? 'Tắt đèn' : 'Bật đèn',
            onPressed: () async {
              await _controller.toggleTorch();
              if (!mounted) return;
              setState(() => _torchOn = !_torchOn);
            },
            icon: Icon(_torchOn ? Icons.flash_on : Icons.flash_off),
          ),
          IconButton(
            tooltip: 'Đổi camera',
            onPressed: () async {
              await _controller.switchCamera();
              if (!mounted) return;
              setState(() {
                _facing = (_facing == CameraFacing.back)
                    ? CameraFacing.front
                    : CameraFacing.back;
              });
            },
            icon: Icon(
              _facing == CameraFacing.back
                  ? Icons.camera_rear
                  : Icons.camera_front,
            ),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(controller: _controller, onDetect: _handleDetection),
          const _ScanOverlay(),
          const Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Text(
              'Đưa mã QR vào giữa khung để quét',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanOverlay extends StatelessWidget {
  const _ScanOverlay();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final h = c.maxHeight;
        final size = w * 0.7;
        final left = (w - size) / 2;
        final top = (h - size) / 2;

        return Stack(
          children: [
            Container(color: Colors.black.withOpacity(0.45)),
            Positioned(
              left: left,
              top: top,
              width: size,
              height: size,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _HolePainter(
                    Rect.fromLTWH(left, top, size, size),
                    16,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HolePainter extends CustomPainter {
  final Rect rect;
  final double radius;
  _HolePainter(this.rect, this.radius);

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = Colors.black.withOpacity(0.45);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    final path = Path()..addRect(Offset.zero & size);
    final cut = Path()..addRRect(rrect);
    final finalPath = Path.combine(PathOperation.difference, path, cut);
    canvas.drawPath(finalPath, bg);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
