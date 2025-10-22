import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_attendance/data/models/entity/session_checkin_token.dart';
import 'package:mobile_attendance/core/constants/app_theme.dart';

class TeacherQrDisplayPage extends StatefulWidget {
  final SessionCheckinToken token;

  const TeacherQrDisplayPage({super.key, required this.token});

  @override
  State<TeacherQrDisplayPage> createState() => _TeacherQrDisplayPageState();
}

class _TeacherQrDisplayPageState extends State<TeacherQrDisplayPage> {
  Timer? _timer;
  Duration _remain = Duration.zero;

  @override
  void initState() {
    super.initState();
    _remain = _safeRemain(widget.token.expiresAt);
    // Cập nhật đếm ngược mỗi giây
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final r = _safeRemain(widget.token.expiresAt);
      if (!mounted) return;
      setState(() => _remain = r);
      if (r == Duration.zero) {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Duration _safeRemain(DateTime expiresAt) {
    final diff = expiresAt.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  String _mmss(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  String _formatDate(DateTime dt) {
    final l = dt.toLocal();
    final day = '${l.day.toString().padLeft(2, '0')}/${l.month.toString().padLeft(2, '0')}/${l.year}';
    final time = '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
    return '$day $time';
  }

  @override
  Widget build(BuildContext context) {
    final payload = jsonEncode({
      'session_id': widget.token.sessionId,
      'token_id': widget.token.id,
      'nonce': widget.token.nonce,
      'v': 1,
    });

    final isExpired = _remain == Duration.zero;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mã QR điểm danh'),
        backgroundColor: AppTheme.adminPrimaryColor,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Thẻ thông tin nhanh
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.qr_code_2, size: 32, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Trạng thái',
                                style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.grey[700])),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                if (!isExpired)
                                  const Icon(Icons.check_circle, size: 18, color: Colors.green)
                                else
                                  const Icon(Icons.error_outline, size: 18, color: Colors.red),
                                const SizedBox(width: 6),
                                Text(
                                  isExpired ? 'ĐÃ HẾT HẠN' : 'ĐANG HOẠT ĐỘNG',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: isExpired ? Colors.red : Colors.green[700],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (isExpired)
                        FilledButton.tonalIcon(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Quay lại'),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // PIN & QR
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                  child: Column(
                    children: [
                      Text('MÃ 4 SỐ', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      SelectableText(
                        widget.token.pin4,
                        style: const TextStyle(
                          fontSize: 42,
                          letterSpacing: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.black12),
                        ),
                        child: QrImageView(data: payload, size: 260, backgroundColor: Colors.white),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isExpired
                            ? 'Mã đã hết hạn.'
                            : 'Hết hạn lúc: ${_formatDate(widget.token.expiresAt)}',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: isExpired ? Colors.red[700] : Colors.grey[700]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Đồng hồ đếm ngược
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.timer_outlined, size: 20),
                          const SizedBox(width: 8),
                          Text('Thời gian còn lại', style: Theme.of(context).textTheme.titleMedium),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isExpired ? Colors.red[50] : Colors.green[50],
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              isExpired ? '00:00' : _mmss(_remain),
                              style: TextStyle(
                                fontFeatures: const [FontFeature.tabularFigures()],
                                fontWeight: FontWeight.w700,
                                color: isExpired ? Colors.red : Colors.green[800],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Do không biết tổng TTL, hiển thị progress indeterminate nếu còn hạn
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: isExpired
                            ? const LinearProgressIndicator(value: 1.0, minHeight: 6)
                            : const LinearProgressIndicator(minHeight: 6),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),
              if (!isExpired)
                Text(
                  'Hãy để màn hình sáng cho sinh viên quét mã.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
