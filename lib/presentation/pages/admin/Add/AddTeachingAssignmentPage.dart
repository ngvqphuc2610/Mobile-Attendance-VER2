
import 'package:flutter/material.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../data/services/api_service.dart';
import '../../../../core/constants/api_constants.dart';

class AddTeachingAssignmentPage extends StatefulWidget {
  const AddTeachingAssignmentPage({super.key});

  @override
  State<AddTeachingAssignmentPage> createState() => _AddTeachingAssignmentPageState();
}

class _AddTeachingAssignmentPageState extends State<AddTeachingAssignmentPage> {
  final _formKey = GlobalKey<FormState>();
  final _sectionIdController = TextEditingController();
  final _teacherIdController = TextEditingController();
  final _roleController = TextEditingController(text: 'lecturer');

  bool _saving = false;

  @override
  void dispose() {
    _sectionIdController.dispose();
    _teacherIdController.dispose();
    _roleController.dispose();
    super.dispose();
  }

  void _saveAssignment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      await ApiService.create(ApiConstants.teachingAssignments, {
        'section_id': _sectionIdController.text.trim(),
        'teacher_id': _teacherIdController.text.trim(),
        'role': _roleController.text.trim(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thêm phân công thành công!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi thêm phân công: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Thêm phân công giảng dạy'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _sectionIdController,
                decoration: const InputDecoration(
                  labelText: 'Section ID',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nhập Section ID';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _teacherIdController,
                decoration: const InputDecoration(
                  labelText: 'Teacher ID',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nhập Teacher ID';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _roleController,
                decoration: const InputDecoration(
                  labelText: 'Vai trò',
                  helperText: 'Ví dụ: lecturer, assistant...',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nhập vai trò';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _saveAssignment,
          child: const Text('Lưu'),
        ),
      ],
    );
  }
}
