
import 'package:flutter/material.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../data/services/api_service.dart';
import '../../../../core/constants/api_constants.dart';

class EditAttendancePage extends StatefulWidget {
  final Map<String, dynamic> attendance;

  const EditAttendancePage({super.key, required this.attendance});

  @override
  State<EditAttendancePage> createState() => _EditAttendancePageState();
}

class _EditAttendancePageState extends State<EditAttendancePage> {
  final _formKey = GlobalKey<FormState>();
  final _userIdController = TextEditingController();
  final _methodController = TextEditingController();
  final _confidenceScoreController = TextEditingController();
  final _noteController = TextEditingController();
  final _sectionIdController = TextEditingController();
  final _sessionIdController = TextEditingController();

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _userIdController.text = widget.attendance['user_id'] ?? '';
    _methodController.text = widget.attendance['method'] ?? '';
    _confidenceScoreController.text = widget.attendance['confidence_score'] ?? '';
    _noteController.text = widget.attendance['note'] ?? '';
    _sectionIdController.text = widget.attendance['section_id'] ?? '';
    _sessionIdController.text = widget.attendance['session_id'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sửa điểm danh'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _updateAttendance,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Lưu', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingMedium),
          child: SingleChildScrollView(
            child: Column(  children: [
                TextFormField(
                  controller: _userIdController,
                  decoration: const InputDecoration(
                    labelText: 'User ID',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nhập User ID';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _methodController,
                  decoration: const InputDecoration(
                    labelText: 'Phương thức',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nhập phương thức';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confidenceScoreController,
                  decoration: const InputDecoration(
                    labelText: 'Điểm tin cậy',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    labelText: 'Ghi chú',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _sectionIdController,
                  decoration: const InputDecoration(
                    labelText: 'Section ID',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _sessionIdController,
                  decoration: const InputDecoration(
                    labelText: 'Session ID',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _updateAttendance() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      await ApiService.update(ApiConstants.attendance, widget.attendance['id'].toString(), {
        'user_id': _userIdController.text.trim(),
        'method': _methodController.text.trim(),  
        if (_confidenceScoreController.text.trim().isNotEmpty)
          'confidence_score': double.parse(_confidenceScoreController.text.trim()),
        if (_noteController.text.trim().isNotEmpty) 'note': _noteController.text.trim(),
        if (_sectionIdController.text.trim().isNotEmpty) 'section_id': _sectionIdController.text.trim(),
        if (_sessionIdController.text.trim().isNotEmpty) 'session_id': _sessionIdController.text.trim(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cập nhật điểm danh thành công!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      setState(() => _saving = false);
    }
  }
}
