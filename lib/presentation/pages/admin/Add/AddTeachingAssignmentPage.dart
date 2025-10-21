import 'package:flutter/material.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../data/services/api_service.dart';

class AddTeachingAssignmentPage extends StatefulWidget {
  const AddTeachingAssignmentPage({super.key});

  @override
  State<AddTeachingAssignmentPage> createState() =>
      _AddTeachingAssignmentPageState();
}

class _AddTeachingAssignmentPageState extends State<AddTeachingAssignmentPage> {
  final _formKey = GlobalKey<FormState>();

  bool _loading = true;
  bool _saving = false;

  // raw data
  List<Map<String, dynamic>> _sections = [];
  List<Map<String, dynamic>> _teachers = [];

  // selected ids
  String? _selectedSectionId;
  String? _selectedTeacherId;

  final _roleController = TextEditingController(text: 'lecturer');

  @override
  void initState() {
    super.initState();
    _loadDropdownData();
  }

  @override
  void dispose() {
    _roleController.dispose();
    super.dispose();
  }

  // ---------- Helpers ----------
  String _sectionIdOf(Map<String, dynamic> s) =>
      (s['id'] ?? '').toString();

  String _sectionLabelOf(Map<String, dynamic> s) {
    final subject = (s['subject_name'] ?? s['subject'] ?? '').toString();
    final code = (s['section_code'] ?? s['code'] ?? '').toString();
    final sem = (s['semester']?.toString() ?? '').trim();
    final year = (s['year']?.toString() ?? '').trim();

    if (subject.isNotEmpty && code.isNotEmpty && sem.isNotEmpty && year.isNotEmpty) {
      return '$subject — $code (HK $sem/$year)';
    }
    if (subject.isNotEmpty && code.isNotEmpty) return '$subject — $code';
    if (subject.isNotEmpty) return subject;
    if (code.isNotEmpty) return code;
    return _sectionIdOf(s);
  }

  String _teacherIdOf(Map<String, dynamic> t) =>
      (t['profile_id'] ?? t['id'] ?? '').toString();

  String _teacherLabelOf(Map<String, dynamic> t) {
    final name = (t['full_name'] ?? t['name'] ?? '').toString();
    final email = (t['email'] ?? '').toString();
    if (name.isNotEmpty && email.isNotEmpty) return '$name — $email';
    if (name.isNotEmpty) return name;
    if (email.isNotEmpty) return email;
    return _teacherIdOf(t);
  }

  List<Map<String, dynamic>> _uniqueById(
    List data,
    String Function(Map<String, dynamic>) idOf,
  ) {
    final seen = <String>{};
    final out = <Map<String, dynamic>>[];
    for (final raw in data) {
      final m = Map<String, dynamic>.from(raw as Map);
      final id = idOf(m);
      if (id.isEmpty || seen.contains(id)) continue;
      seen.add(id);
      out.add(m);
    }
    return out;
  }

  // ---------- Load data ----------
  Future<void> _loadDropdownData() async {
    try {
      // đổi endpoint theo project của bạn
      final sectionsJson = await ApiService.getList(ApiConstants.classSections);
      final teachersJson = await ApiService.getList(ApiConstants.teachers);

      final sections = _uniqueById(
        List<Map<String, dynamic>>.from(sectionsJson),
        _sectionIdOf,
      );
      final teachers = _uniqueById(
        List<Map<String, dynamic>>.from(teachersJson),
        _teacherIdOf,
      );

      setState(() {
        _sections = sections;
        _teachers = teachers;
        _loading = false;

        // đảm bảo selected value hợp lệ
        if (_selectedSectionId != null &&
            !_sections.any((e) => _sectionIdOf(e) == _selectedSectionId)) {
          _selectedSectionId = null;
        }
        if (_selectedTeacherId != null &&
            !_teachers.any((e) => _teacherIdOf(e) == _selectedTeacherId)) {
          _selectedTeacherId = null;
        }
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải danh sách: $e')),
        );
      }
    }
  }

  // ---------- Save ----------
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ApiService.create(ApiConstants.teachingAssignments, {
        'section_id': _selectedSectionId,
        'teacher_id': _selectedTeacherId,
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi thêm phân công: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thêm phân công giảng dạy'),
        backgroundColor: AppTheme.adminPrimaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saving ? null : _save,
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    // SECTION
                    DropdownButtonFormField<String>(
                      value: (_selectedSectionId != null &&
                              _sections.any((e) => _sectionIdOf(e) == _selectedSectionId))
                          ? _selectedSectionId
                          : null,
                      decoration: const InputDecoration(
                        labelText: 'Chọn lớp học phần',
                        border: OutlineInputBorder(),
                      ),
                      isExpanded: true,
                      items: _sections.map((s) {
                        final id = _sectionIdOf(s);
                        final label = _sectionLabelOf(s);
                        return DropdownMenuItem<String>(
                          value: id,
                          child: Text(label, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedSectionId = val),
                      validator: (val) =>
                          val == null || val.isEmpty ? 'Hãy chọn lớp học phần' : null,
                    ),
                    const SizedBox(height: 16),

                    // TEACHER
                    DropdownButtonFormField<String>(
                      value: (_selectedTeacherId != null &&
                              _teachers.any((e) => _teacherIdOf(e) == _selectedTeacherId))
                          ? _selectedTeacherId
                          : null,
                      decoration: const InputDecoration(
                        labelText: 'Chọn giảng viên',
                        border: OutlineInputBorder(),
                      ),
                      isExpanded: true,
                      items: _teachers.map((t) {
                        final id = _teacherIdOf(t);          // <-- profile_id/id
                        final label = _teacherLabelOf(t);    // <-- full_name/email
                        return DropdownMenuItem<String>(
                          value: id,
                          child: Text(label, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedTeacherId = val),
                      validator: (val) =>
                          val == null || val.isEmpty ? 'Hãy chọn giảng viên' : null,
                    ),
                    const SizedBox(height: 16),

                    // ROLE
                    TextFormField(
                      controller: _roleController,
                      decoration: const InputDecoration(
                        labelText: 'Vai trò',
                        helperText: 'Ví dụ: lecturer, assistant...',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Nhập vai trò' : null,
                    ),
                    const SizedBox(height: 24),

                    ElevatedButton.icon(
                      icon: const Icon(Icons.check),
                      label: _saving
                          ? const Text('Đang lưu...')
                          : const Text('Lưu phân công'),
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.adminPrimaryColor,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
