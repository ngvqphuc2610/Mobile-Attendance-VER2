import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_theme.dart';
import '../../../bloc/subject/subject_bloc.dart';
import '../../../bloc/subject/subject_event.dart';
import '../../../bloc/subject/subject_state.dart';
import '../../../../data/models/entity/subject_entity.dart';

class EditSubjectPage extends StatefulWidget {
  final SubjectEntity subject;

  const EditSubjectPage({super.key, required this.subject});

  @override
  State<EditSubjectPage> createState() => _EditSubjectPageState();
}

class _EditSubjectPageState extends State<EditSubjectPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codeController;
  late final TextEditingController _nameController;
  late final TextEditingController _creditsController;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(text: widget.subject.code);
    _nameController = TextEditingController(text: widget.subject.name);
    _creditsController =
        TextEditingController(text: (widget.subject.credits ?? '').toString());
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _creditsController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

    final code = _codeController.text.trim().toUpperCase();
    final name = _nameController.text.trim();
    final credits = int.tryParse(_creditsController.text.trim());

    if (credits == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Số tín chỉ phải là số nguyên')),
      );
      return;
    }

    setState(() => _saving = true);

    // LƯU Ý: Sự kiện UpdateSubject theo mẫu đã dùng trong AdminSubjects:
    // UpdateSubject(widget.subject!.id, code, name, credits)
    context.read<SubjectBloc>().add(
          UpdateSubject(widget.subject.id, code, name, credits),
        );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return WillPopScope(
      onWillPop: () async => !_saving, // chặn thoát khi đang lưu
      child: BlocListener<SubjectBloc, SubjectState>(
        listener: (context, state) {
          if (state is SubjectOperationSuccess) {
            // Thành công: báo và quay lại, yêu cầu reload ở màn trước
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message), backgroundColor: Colors.green),
              );
              Navigator.pop(context, true);
            }
          } else if (state is SubjectError) {
            // Lỗi: hiển thị và mở khóa nút
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message), backgroundColor: Colors.red),
              );
              setState(() => _saving = false);
            }
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Sửa môn học'),
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: TextButton.icon(
                  onPressed: _saving ? null : _submit,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save, color: Colors.white),
                  label: const Text('Cập nhật', style: TextStyle(color: Colors.black)),
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
                        // MÃ MÔN HỌC
                        TextFormField(
                          controller: _codeController,
                          decoration: const InputDecoration(
                            labelText: 'Mã môn học *',
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
                        ),
                        const SizedBox(height: AppSizes.paddingMedium),

                        // TÊN MÔN HỌC
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Tên môn học *',
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
                        ),
                        const SizedBox(height: AppSizes.paddingMedium),

                        // SỐ TÍN CHỈ
                        TextFormField(
                          controller: _creditsController,
                          decoration: const InputDecoration(
                            labelText: 'Số tín chỉ *',
                            prefixIcon: Icon(Icons.numbers),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            final v = (value ?? '').trim();
                            if (v.isEmpty) return 'Vui lòng nhập số tín chỉ';
                            final parsed = int.tryParse(v);
                            if (parsed == null) return 'Số tín chỉ phải là số nguyên';
                            if (parsed <= 0) return 'Số tín chỉ phải lớn hơn 0';
                            if (parsed > 30) return 'Số tín chỉ quá lớn (<= 30)';
                            return null;
                          },
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(2),
                          ],
                          onFieldSubmitted: (_) => _submit(),
                          textInputAction: TextInputAction.done,
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

                        // Nút cập nhật lớn (ngoài AppBar) cho UX tốt trên màn nhỏ
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _saving ? null : _submit,
                            icon: const Icon(Icons.check),
                            label: const Text('Cập nhật'),
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
