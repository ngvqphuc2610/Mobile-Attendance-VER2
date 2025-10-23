import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_attendance/data/models/entity/session_checkin_token.dart';
import 'package:mobile_attendance/core/constants/app_theme.dart';
import '../../../core/helpers/location_helper.dart';

class StudentCheckinPage extends StatefulWidget {
  final String studentId;

  const StudentCheckinPage({
    super.key,
    required this.studentId,
  });

  @override
  State<StudentCheckinPage> createState() => _StudentCheckinPageState();
}

class _StudentCheckinPageState extends State<StudentCheckinPage> {
  final TextEditingController _codeController = TextEditingController();
  bool _submitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submitCode() async {
    FocusScope.of(context).unfocus();
    final code = _codeController.text.trim();

    if (code.length != 4) {
      setState(() {
        _errorMessage = 'Ma diem danh gom 4 ky tu.';
      });
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;

    setState(() {
      _submitting = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Da gui ma $code. Tinh nang se som hoan thien.'),
      ),
    );
  }

  void _openScanner() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tinh nang quet QR se som hoan thien.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diem danh'),
        actions: [
          IconButton(
            onPressed: _submitting ? null : _openScanner,
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Quet QR',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.paddingLarge),
        children: [
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
                    'Nhap ma 4 so do giang vien cung cap trong buoi hoc.',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AppColors.textSecondary),
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
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.error),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: AppSizes.paddingLarge),
                  FilledButton(
                    onPressed: _submitting ? null : _submitCode,
                    child: _submitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Xac nhan'),
                  ),
                  const SizedBox(height: AppSizes.paddingSmall),
                  TextButton(
                    onPressed: _submitting
                        ? null
                        : () {
                            _codeController.clear();
                            Navigator.maybePop(context);
                          },
                    child: const Text('Thoat'),
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
