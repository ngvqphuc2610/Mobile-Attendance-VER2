import 'dart:io' show Platform;
import 'package:flutter/material.dart';

/// Nút đăng nhập sinh trắc kiểu phổ biến (Zalo, banking, ví…)
class BiometricLoginButton extends StatelessWidget {
  const BiometricLoginButton({
    super.key,
    required this.onPressed,
    this.busy = false,
    this.label = 'Đăng nhập bằng sinh trắc học',
  });

  final VoidCallback? onPressed;
  final bool busy;
  final String label;

  @override
  Widget build(BuildContext context) {
    final iconData = Platform.isIOS ? Icons.face_retouching_natural : Icons.fingerprint;
    final canPress = onPressed != null && !busy;
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 52,
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            // Nút pill sáng kiểu modern (giống nhiều app hiện nay)
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: canPress
                  ? [
                      colorScheme.primary.withOpacity(.10),
                      colorScheme.primary.withOpacity(.06),
                    ]
                  : [Colors.black12, Colors.black12],
            ),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: canPress
                  ? colorScheme.primary.withOpacity(.25)
                  : Colors.black12,
            ),
            boxShadow: canPress
                ? [
                    BoxShadow(
                      color: colorScheme.primary.withOpacity(.12),
                      blurRadius: 14,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: canPress ? onPressed : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon/avatar tròn giống nhiều app
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: busy
                        ? const SizedBox(
                            key: ValueKey('loading'),
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Container(
                            key: const ValueKey('icon'),
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withOpacity(.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              iconData,
                              size: 18,
                              color: colorScheme.primary,
                            ),
                          ),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      busy ? 'Đang xác thực...' : label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: canPress ? colorScheme.onSurface : Colors.black54,
                        fontWeight: FontWeight.w700,
                        letterSpacing: .2,
                    )),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
