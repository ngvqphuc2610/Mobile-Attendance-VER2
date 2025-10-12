import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_theme.dart';
import '../../../../data/models/faculty.dart';

class AddTeacherPage extends StatefulWidget {
  const AddTeacherPage({super.key});

  @override
  State<AddTeacherPage> createState() => _AddTeacherPageState();
}

class _AddTeacherPageState extends State<AddTeacherPage> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _titleController = TextEditingController();
  final _officeController = TextEditingController();

  String? _selectedFacultyId;
  List<Faculty> _faculties = [];
  bool _loadingFaculties = true;
  bool _saving = false;
  String? _facultyError;

  @override
  void initState() {
    super.initState();
    _loadFaculties();
  }

  Future<void> _loadFaculties() async {
    try {
      final response = await Supabase.instance.client
          .from('faculties')
          .select()
          .order('name');

      _faculties = (response as List<dynamic>)
          .map((json) => Faculty.fromJson(json))
          .toList();
      _facultyError = null;
    } catch (e) {
      _facultyError = e.toString();
    } finally {
      if (mounted) {
        setState(() => _loadingFaculties = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thêm giáo viên'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _saveTeacher,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Lưu',
                    style: TextStyle(color: Colors.white),
                  ),
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
                TextFormField(
                  controller: _codeController,
                  decoration: const InputDecoration(
                    labelText: 'Mã giáo viên *',
                    hintText: 'Ví dụ: GV001',
                    prefixIcon: Icon(Icons.badge),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập mã giáo viên';
                    }
                    return null;
                  },
                  textCapitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: AppSizes.paddingMedium),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Họ tên *',
                    hintText: 'Ví dụ: TS. Nguyễn Văn A',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập họ tên';
                    }
                    return null;
                  },
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: AppSizes.paddingMedium),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'Ví dụ: giaovien@hutech.edu.vn',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                          .hasMatch(value)) {
                        return 'Email không hợp lệ';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSizes.paddingMedium),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Số điện thoại',
                    hintText: 'Ví dụ: 0901234567',
                    prefixIcon: Icon(Icons.phone),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      if (!RegExp(r'^[0-9]{10,11}$').hasMatch(value)) {
                        return 'Số điện thoại không hợp lệ (10-11 chữ số)';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSizes.paddingMedium),
                _loadingFaculties
                    ? const Center(child: CircularProgressIndicator())
                    : _facultyError != null
                        ? Text(
                            _facultyError!,
                            style: const TextStyle(color: Colors.red),
                          )
                        : DropdownButtonFormField<String?>(
                            value: _selectedFacultyId,
                            decoration: const InputDecoration(
                              labelText: 'Khoa',
                              prefixIcon: Icon(Icons.school),
                              border: OutlineInputBorder(),
                            ),
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text('Chọn khoa'),
                              ),
                              ..._faculties.map(
                                (faculty) => DropdownMenuItem<String?>(
                                  value: faculty.id,
                                  child: Text(faculty.name),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() => _selectedFacultyId = value);
                            },
                          ),
                const SizedBox(height: AppSizes.paddingLarge),
                const Text(
                  '* Trường bắt buộc',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveTeacher() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final supabase = Supabase.instance.client;
      
      // 1. Insert vào bảng profiles trước
      final profileData = {
        'code': _codeController.text.trim().toUpperCase(),
        'full_name': _nameController.text.trim(),
        'is_active': true,
      };

      if (_emailController.text.trim().isNotEmpty) {
        profileData['email'] = _emailController.text.trim().toLowerCase();
      }
      if (_phoneController.text.trim().isNotEmpty) {
        profileData['phone'] = _phoneController.text.trim();
      }

      final profileResponse = await supabase
          .from('profiles')
          .insert(profileData)
          .select('id')
          .single();

      final profileId = profileResponse['id'];

      // 2. Insert vào bảng teachers
      final teacherData = {
        'profile_id': profileId,
        'faculty_id': _selectedFacultyId,
      };

      if (_titleController.text.trim().isNotEmpty) {
        teacherData['title'] = _titleController.text.trim();
      }
      if (_officeController.text.trim().isNotEmpty) {
        teacherData['office'] = _officeController.text.trim();
      }

      await supabase.from('teachers').insert(teacherData);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thêm giáo viên thành công!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      String errorMessage = 'Lỗi: $e';
      if (e.toString().contains('duplicate key')) {
        if (e.toString().contains('code')) {
          errorMessage = 'Mã giáo viên đã tồn tại!';
        } else if (e.toString().contains('email')) {
          errorMessage = 'Email đã tồn tại!';
        }
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}


