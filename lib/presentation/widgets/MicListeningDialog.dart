import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class MicListeningDialog extends StatefulWidget {
  /// Text được truyền từ cha vào liên tục
  final ValueListenable<String> recognizedTextListenable;

  /// Callback khi user bấm "Dừng lại"
  final VoidCallback onStop;

  const MicListeningDialog({
    super.key,
    required this.recognizedTextListenable,
    required this.onStop,
  });

  @override
  State<MicListeningDialog> createState() => _MicListeningDialogState();
}

class _MicListeningDialogState extends State<MicListeningDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      elevation: 0,
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(32),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.8),
                  Colors.black.withOpacity(0.55),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white24, width: 1),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // mic hiệu ứng pulse
                ScaleTransition(
                  scale: Tween(begin: 0.85, end: 1.05).animate(
                    CurvedAnimation(
                      parent: _pulseController,
                      curve: Curves.easeInOut,
                    ),
                  ),
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.12),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.redAccent, width: 2),
                    ),
                    child: const Icon(
                      Icons.mic,
                      size: 70,
                      color: Colors.redAccent,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'Đang nghe bạn nói...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 12),

                // 👇 phần này sẽ update realtime
                ValueListenableBuilder<String>(
                  valueListenable: widget.recognizedTextListenable,
                  builder: (context, value, _) {
                    if (value.isEmpty) {
                      return Text(
                        'Hãy nói tên / mã / nội dung cần tìm',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.75),
                          fontSize: 13.5,
                        ),
                      );
                    }
                    return Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        '“$value”',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 28),

                // nút dừng
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: () {
                    widget.onStop(); // báo cho cha dừng mic
                    Navigator.of(context).pop(); // đóng dialog
                  },
                  icon: const Icon(Icons.stop_circle_rounded),
                  label: const Text(
                    'Dừng lại',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
