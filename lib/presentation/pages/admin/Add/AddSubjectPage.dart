import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_theme.dart';
import '../../../../data/services/api_service.dart';
import '../../../../core/constants/api_constants.dart';

class AddSubjectPage extends StatefulWidget {
  const AddSubjectPage({super.key});

  @override
  State<AddSubjectPage> createState() => _AddSubjectPageState();
}

class _AddSubjectPageState extends State<AddSubjectPage> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _creditsController = TextEditingController();

  bool _saving = false;

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _creditsController.dispose();
    super.dispose();
  }

  Future<void> _saveSubject() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      await ApiService.create(ApiConstants.subjects, {
        'code': _codeController.text.trim().toUpperCase(),
        'name': _nameController.text.trim(),
        'credits': int.parse(_creditsController.text.trim()),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thêm môn học thành công!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true); // báo màn trước reload
    } catch (e) {
      if (!mounted) return;
      var msg = e.toString();
      if (msg.toLowerCase().contains('duplicate')) {
        msg = 'Mã môn học đã tồn tại!';
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
          title: const Text('Thêm Môn học'),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: TextButton.icon(
                onPressed: _saving ? null : _saveSubject,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save, color: Colors.white),
                label: const Text('Lưu', style: TextStyle(color: Colors.white)),
                style: TextButton.styleFrom(foregroundColor: Colors.white),
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
                          labelText: 'Mã môn học *',
                          hintText: 'VD: CTDL',
                          prefixIcon: Icon(Icons.code),
                          border: OutlineInputBorder(),
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9_-]')),
                          LengthLimitingTextInputFormatter(16),
                          _UpperCaseTextFormatter(),
                        ],
                        validator: (value) {
                          final v = (value ?? '').trim();
                          if (v.isEmpty) return 'Vui lòng nhập mã môn học';
                          if (v.length < 2) return 'Mã môn học phải có ít nhất 2 ký tự';
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
                          labelText: 'Tên môn học *',
                          hintText: 'VD: Cấu trúc dữ liệu & Giải thuật',
                          prefixIcon: Icon(Icons.menu_book),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          final v = (value ?? '').trim();
                          if (v.isEmpty) return 'Vui lòng nhập tên môn học';
                          if (v.length < 3) return 'Tên môn học phải có ít nhất 3 ký tự';
                          return null;
                        },
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.organizationName],
                      ),
                      const SizedBox(height: AppSizes.paddingMedium),

                      // CREDITS
                      TextFormField(
                        controller: _creditsController,
                        decoration: const InputDecoration(
                          labelText: 'Số tín chỉ *',
                          hintText: 'VD: 3',
                          prefixIcon: Icon(Icons.numbers),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          final v = (value ?? '').trim();
                          if (v.isEmpty) return 'Vui lòng nhập số tín chỉ';
                          final parsed = int.tryParse(v);
                          if (parsed == null) return 'Số tín chỉ phải là số nguyên';
                          if (parsed <= 0) return 'Số tín chỉ phải > 0';
                          if (parsed > 30) return 'Số tín chỉ quá lớn (<= 30)';
                          return null;
                        },
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(2),
                        ],
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _saveSubject(),
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

                      // Nút Lưu phụ (ngoài AppBar) cho UX màn nhỏ
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _saving ? null : _saveSubject,
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
  }
}
