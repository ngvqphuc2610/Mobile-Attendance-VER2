import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/constants/app_theme.dart';
import '../../../core/helpers/location_helper.dart';
import '../../../core/constants/api_constants.dart';
import '../../../data/services/api_service.dart';
import 'StudentQRScanPage.dart';
class StudentCheckinPage extends StatefulWidget {
  final String studentId;
  // Nếu biết trước sessionId (đi từ lịch), có thể truyền vào để backend dùng:
  // final String? sessionId;

  const StudentCheckinPage({
    super.key,
    required this.studentId,
    // this.sessionId,
  });

  @override
  State<StudentCheckinPage> createState() => _StudentCheckinPageState();
}

class _StudentCheckinPageState extends State<StudentCheckinPage> {
  final TextEditingController _codeController = TextEditingController();

  bool _submitting = false;
  String? _errorMessage;

  // Vị trí
  bool _locLoading = true;
  String? _locError;
  LocationResult? _location;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _fetchLocation() async {
    setState(() {
      _locLoading = true;
      _locError = null;
    });
    try {
      final loc = await LocationHelper.getCurrentLocation(
        accuracy: LocationAccuracy.high,
        timeout: const Duration(seconds: 12),
        needAddress: true,
      );
      if (!mounted) return;
      setState(() {
        _location = loc;
        _locLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _locError = e.toString();
        _locLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_locError!)),
      );
    }
  }

  Future<void> _submitPin() async {
    FocusScope.of(context).unfocus();
    final code = _codeController.text.trim();

    if (code.length != 4) {
      setState(() => _errorMessage = 'Mã điểm danh gồm 4 ký tự.');
      return;
    }
    if (_location == null) {
      setState(() => _errorMessage = 'Chưa lấy được vị trí. Vui lòng thử lại.');
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      // Payload tuỳ backend. Gợi ý khớp schema "attendance":
      // method: 'barcode' (vì dùng PIN/QR), session_id nếu có,
      // kèm toạ độ & địa chỉ để lưu audit.
      final payload = <String, dynamic>{
        'student_id': widget.studentId,
        // 'session_id': widget.sessionId, // nếu có
        'pin_4': code,
        'latitude': _location!.latitude,
        'longitude': _location!.longitude,
        'accuracy_m': _location!.accuracyMeters,
        'address': _location!.address,
      };

      await ApiService.postExpectOk(ApiConstants.checkinPin, payload);

      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Điểm danh (PIN) thành công.')),
      );
      Navigator.maybePop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _errorMessage = e.toString();
      });
    }
  }

  /// Quét xong tự check-in luôn
  Future<void> _openScannerAndCheckin() async {
    if (_submitting) return;

    // (1) Mở trang quét
    final result = await Navigator.of(context).push<QrScanResult>(
      MaterialPageRoute(builder: (_) => const QrScanPage()),
    );
    if (!mounted || result == null) return;

    // (2) Bắt buộc có location
    if (_location == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa lấy được vị trí. Vui lòng thử lại.')),
      );
      await _fetchLocation();
      if (_location == null) return;
    }

    // (3) Gọi API check-in QR
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      final payload = <String, dynamic>{
        'student_id': widget.studentId,
        'session_id': result.sessionId, // có từ QR payload
        'token_id': result.tokenId,
        'nonce': result.nonce,
        'latitude': _location!.latitude,
        'longitude': _location!.longitude,
        'accuracy_m': _location!.accuracyMeters,
        'address': _location!.address,
      };

      await ApiService.postExpectOk(ApiConstants.checkinQr, payload);

      if (!mounted) return;
      setState(() => _submitting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Điểm danh (QR) thành công.')),
      );

      Navigator.maybePop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _errorMessage = e.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi điểm danh: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSubmitPin = !_submitting && _location != null && !_locLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Điểm danh'),
        actions: [
          IconButton(
            onPressed: _submitting ? null : _openScannerAndCheckin,
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Quét QR',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.paddingLarge),
        children: [
          // Thẻ trạng thái vị trí
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
            ),
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.my_location,
                    color: _location != null ? Colors.green : (_locError != null ? Colors.red : Colors.grey),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _locLoading
                        ? const Text('Đang lấy vị trí...')
                        : _location != null
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Đã lấy vị trí',
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Lat: ${_location!.latitude.toStringAsFixed(5)}, '
                                    'Lng: ${_location!.longitude.toStringAsFixed(5)}'
                                    '${_location!.accuracyMeters != null ? ' • ±${_location!.accuracyMeters!.toStringAsFixed(0)}m' : ''}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                  if (_location!.address != null) ...[
                                    const SizedBox(height: 2),
                                    Text(_location!.address!, style: Theme.of(context).textTheme.bodySmall),
                                  ],
                                ],
                              )
                            : Text(
                                _locError ?? 'Không lấy được vị trí.',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.red),
                              ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Lấy lại vị trí',
                    onPressed: _submitting ? null : _fetchLocation,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSizes.paddingLarge),

          // Nhập PIN 4 số
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
            ),
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Nhập mã 4 số do giảng viên cung cấp trong buổi học hoặc dùng biểu tượng QR trên thanh AppBar để quét và tự điểm danh.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSizes.paddingLarge),
                  _PinInput(
                    controller: _codeController,
                    enabled: !_submitting,
                    onChanged: (value) {
                      if (_errorMessage != null && value.length <= 4) {
                        setState(() => _errorMessage = null);
                      }
                    },
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: AppSizes.paddingSmall),
                    Text(
                      _errorMessage!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.error),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: AppSizes.paddingLarge),
                  FilledButton(
                    onPressed: canSubmitPin ? _submitPin : null,
                    child: _submitting
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Xác nhận PIN'),
                  ),
                  const SizedBox(height: AppSizes.paddingSmall),
                  TextButton(
                    onPressed: _submitting
                        ? null
                        : () {
                            _codeController.clear();
                            Navigator.maybePop(context);
                          },
                    child: const Text('Thoát'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PinInput extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String>? onChanged;

  const _PinInput({
    required this.controller,
    required this.enabled,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: TextField(
        controller: controller,
        maxLength: 4,
        enabled: enabled,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        style: const TextStyle(
          letterSpacing: 12,
          fontSize: 28,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: Colors.grey.shade100,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
          ),
        ),
        onChanged: (value) {
          if (value.length > 4) {
            controller.text = value.substring(0, 4);
            controller.selection = TextSelection.fromPosition(
              TextPosition(offset: controller.text.length),
            );
          }
          onChanged?.call(controller.text);
        },
      ),
    );
  }
}
