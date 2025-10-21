// lib/presentation/widgets/BiometricLoginButton.dart
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'package:flutter/material.dart';

class BiometricLoginButton extends StatelessWidget {
  const BiometricLoginButton({
    super.key,
    required this.onPressed,
    this.busy = false,
    this.size = 56, // đường kính nút
    this.tooltip = 'Đăng nhập bằng vân tay',
  });

  final VoidCallback? onPressed;
  final bool busy;
  final double size;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final canPress = onPressed != null && !busy;

    // iOS/web vẫn dùng icon fingerprint để đồng nhất
    final bool isiOS =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
    final iconData = Icons.fingerprint; // luôn là vân tay theo yêu cầu

    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: size,
        height: size,
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: Ink(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: canPress
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color.withOpacity(.20),
                        color.withOpacity(.10),
                      ],
                    )
                  : null,
              color: canPress ? null : Colors.black12,
              border: Border.all(
                color: canPress ? color.withOpacity(.35) : Colors.black26,
              ),
              boxShadow: canPress
                  ? [
                      BoxShadow(
                        color: color.withOpacity(.18),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: canPress ? onPressed : null,
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: busy
                      ? const SizedBox(
                          key: ValueKey('loading'),
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            semanticsLabel: 'Đang xác thực sinh trắc học',
                          ),
                        )
                      : Icon(
                          iconData,
                          key: const ValueKey('icon'),
                          size: 28,
                          color: canPress ? color : Colors.black45,
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
