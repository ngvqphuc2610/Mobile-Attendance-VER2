import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_theme.dart';
import '../../../../data/services/api_service.dart';
import '../../../../core/constants/api_constants.dart';

class AddFacultyPage extends StatefulWidget {
  const AddFacultyPage({super.key});

  @override
  State<AddFacultyPage> createState() => _AddFacultyPageState();
}

class _AddFacultyPageState extends State<AddFacultyPage> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveFaculty() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      await ApiService.create(ApiConstants.faculties, {
        'code': _codeController.text.trim().toUpperCase(),
        'name': _nameController.text.trim(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thêm khoa thành công!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true); // báo cho màn trước biết để reload
    } catch (e) {
      if (!mounted) return;
      var msg = e.toString();
      if (msg.toLowerCase().contains('duplicate')) {
        msg = 'Mã khoa đã tồn tại!';
      } else {
        msg = 'Lỗi: $msg';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return WillPopScope(
      onWillPop: () async => !_saving, // chặn back khi đang lưu
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Thêm Khoa'),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: TextButton.icon(
                onPressed: _saving ? null : _saveFaculty,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save, color: Colors.white),
                label: const Text('Lưu', style: TextStyle(color: Colors.white)),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  AppSizes.paddingMedium,
                  AppSizes.paddingMedium,
                  AppSizes.paddingMedium,
                  AppSizes.paddingMedium + bottom, // chừa chỗ bàn phím
                ),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // CODE
                      TextFormField(
                        controller: _codeController,
                        autofocus: true,
                        decoration: const InputDecoration(
                          labelText: 'Mã khoa *',
                          hintText: 'VD: CNTT',
                          prefixIcon: Icon(Icons.code),
                          border: OutlineInputBorder(),
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9_-]')),
                          LengthLimitingTextInputFormatter(12),
                          _UpperCaseTextFormatter(),
                        ],
                        validator: (value) {
                          final v = (value ?? '').trim();
                          if (v.isEmpty) return 'Vui lòng nhập mã khoa';
                          if (v.length < 2) return 'Mã khoa phải có ít nhất 2 ký tự';
                          return null;
                        },
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.username],
                      ),
                      const SizedBox(height: AppSizes.paddingMedium),

                      // NAME
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Tên khoa *',
                          hintText: 'VD: Công nghệ thông tin',
                          prefixIcon: Icon(Icons.school),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          final v = (value ?? '').trim();
                          if (v.isEmpty) return 'Vui lòng nhập tên khoa';
                          if (v.length < 3) return 'Tên khoa phải có ít nhất 3 ký tự';
                          return null;
                        },
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _saveFaculty(),
                        autofillHints: const [AutofillHints.organizationName],
                      ),
                      const SizedBox(height: AppSizes.paddingLarge),

                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '* Trường bắt buộc',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),

                      const SizedBox(height: AppSizes.paddingLarge),

                      // Nút Lưu phụ (ngoài AppBar) cho UX tốt hơn trên màn nhỏ
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _saving ? null : _saveFaculty,
                          icon: const Icon(Icons.check),
                          label: const Text('Lưu'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSizes.paddingMedium,
                            ),
                          ),
                        ),
                      ),
                    ],
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

/// Formatter chuyển chữ thường -> HOA ngay khi nhập
class _UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final up = newValue.text.toUpperCase();
    return newValue.copyWith(
      text: up,
      selection: TextSelection.collapsed(offset: up.length),
      composing: TextRange.empty,
    );
    // Giữ nguyên selection cuối chuỗi + xóa composing (tránh lỗi gõ tiếng Việt)
  }
}
