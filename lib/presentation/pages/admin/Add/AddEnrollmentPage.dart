
import 'package:flutter/material.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../data/services/api_service.dart';
import '../../../../core/constants/api_constants.dart';

class AddEnrollmentPage extends StatefulWidget {
  const AddEnrollmentPage({super.key});

  @override
  State<AddEnrollmentPage> createState() => _AddEnrollmentPageState();
}

class _AddEnrollmentPageState extends State<AddEnrollmentPage> {
  final _formKey = GlobalKey<FormState>();

  final _sectionIdController = TextEditingController();
  final _studentIdController = TextEditingController();

  bool _saving = false;
  bool _loadingSections = false;
  bool _loadingStudents = false;
  String? _sectionError;
  String? _studentError;

  List<Map<String, dynamic>> _sections = [];
  List<Map<String, dynamic>> _students = [];
  String? _selectedSectionId;
  String? _selectedStudentId;

  @override
  void initState() {
    super.initState();
    _fetchSections();
    _fetchStudents();
  }

  @override
  void dispose() {
    _sectionIdController.dispose();
    _studentIdController.dispose();
    super.dispose();
  }

  Future<void> _fetchSections() async {
    setState(() {
      _loadingSections = true;
      _sectionError = null;
    });

    try {
      final response = await ApiService.getList(ApiConstants.classSections);
      setState(() {
        _sections = List<Map<String, dynamic>>.from(response);
        if (_sections.isNotEmpty) {
          _selectedSectionId = _sections.first['id']?.toString();
        }
      });
    } catch (e) {
      setState(() {
        _sectionError = 'Lỗi tải danh sách lớp học phần: $e';
      });
    } finally {
      setState(() => _loadingSections = false);
    }
  }

  Future<void> _fetchStudents() async {
    setState(() {
      _loadingStudents = true;
      _studentError = null;
    });

    try {
      final response = await ApiService.getList(ApiConstants.students);
      setState(() {
        _students = List<Map<String, dynamic>>.from(response);
        if (_students.isNotEmpty) {
          _selectedStudentId = _students.first['id']?.toString();
        }
      });
    } catch (e) {
      setState(() {
        _studentError = 'Lỗi tải danh sách sinh viên: $e';
      });
    } finally {
      setState(() => _loadingStudents = false);
    }
  }

  Future<void> _saveEnrollment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      await ApiService.create(ApiConstants.enrollments, {
        'section_id': _selectedSectionId,
        'student_id': _selectedStudentId,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thêm sinh viên vào lớp học phần thành công!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi thêm sinh viên vào lớp học phần: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thêm sinh viên vào lớp học phần'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _saveEnrollment,
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
            child: Column(
              children: [
                _loadingSections
                    ? const Center(child: CircularProgressIndicator())
                    : DropdownButtonFormField<String>(
                        value: _selectedSectionId,
                        decoration: const InputDecoration(
                          labelText: 'Lớp học phần *',
                          prefixIcon: Icon(Icons.class_),
                          border: OutlineInputBorder(),
                        ),
                        items: _sections
                            .map(
                              (section) => DropdownMenuItem(
                                value: section['id']?.toString(),
                                child: Text(section['name']?.toString() ?? ''),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _selectedSectionId = value),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng chọn lớp học phần';
                          }
                          if (_sectionError != null) return _sectionError;
                          return null;
                        },
                      ),
                const SizedBox(height: AppSizes.paddingMedium),
                _loadingStudents
                    ? const Center(child: CircularProgressIndicator())
                    : DropdownButtonFormField<String>(
                        value: _selectedStudentId,
                        decoration: const InputDecoration(
                          labelText: 'Sinh viên *',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                        items: _students
                            .map(
                              (student) => DropdownMenuItem(
                                value: student['id']?.toString(),
                                child: Text(student['name']?.toString() ?? ''),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _selectedStudentId = value),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng chọn sinh viên';
                          }
                          if (_studentError != null) return _studentError;
                          return null;
                        },
                      ),
                const SizedBox(height: AppSizes.paddingLarge),
                const Text(
                  '* Trường bắt buộc',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
