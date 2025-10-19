
import 'package:flutter/material.dart';

import '../../../../core/constants/app_theme.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../data/models/dto/student_dto.dart';
import '../../../../data/services/api_service.dart';
import '../../../../data/services/student_service.dart';

class AddStudentPage extends StatefulWidget {
  const AddStudentPage({super.key});

  @override
  State<AddStudentPage> createState() => _AddStudentPageState();
}

class _AddStudentPageState extends State<AddStudentPage> {
  final _formKey = GlobalKey<FormState>();

  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _mssvController = TextEditingController();

  bool _saving = false;
  bool _loadingFaculties = false;
  bool _loadingClasses = false;

  List<Map<String, dynamic>> _faculties = [];
  List<Map<String, dynamic>> _classes = [];
  String? _selectedFacultyId;
  String? _selectedClassId;
  Map<String, dynamic>? _mssvInfo;

  String? _facultyError;
  String? _classError;

  @override
  void initState() {
    super.initState();
    _fetchFaculties();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _mssvController.dispose();
    super.dispose();
  }

  Future<void> _fetchFaculties() async {
    setState(() {
      _loadingFaculties = true;
      _facultyError = null;
    });

    try {
      final response = await ApiService.getList(ApiConstants.faculties);
      setState(() {
        _faculties = List<Map<String, dynamic>>.from(response);
        if (_faculties.isNotEmpty) {
          _selectedFacultyId = _faculties.first['id']?.toString();
          _fetchClasses();
        }
      });
    } catch (e) {
      setState(() {
        _facultyError = 'Lỗi tải danh sách khoa: $e';
      });
    } finally {
      setState(() => _loadingFaculties = false);
    }
  }

  Future<void> _fetchClasses() async {
    if (_selectedFacultyId == null) {
      setState(() {
        _classes = [];
        _selectedClassId = null;
      });
      return;
    }

    setState(() {
      _loadingClasses = true;
      _classError = null;
    });

    try {
      final response = await ApiService.getList(
        ApiConstants.classes,
        queryParams: {'faculty_id': _selectedFacultyId!},
      );
      setState(() {
        _classes = List<Map<String, dynamic>>.from(response);
        _selectedClassId =
            _classes.isNotEmpty ? _classes.first['id']?.toString() : null;
      });
    } catch (e) {
      setState(() {
        _classError = 'Lỗi tải danh sách lớp: $e';
      });
    } finally {
      setState(() => _loadingClasses = false);
    }
  }

  void _onMssvChanged(String value) {
    if (value.length == 10 && RegExp(r'^\d+$').hasMatch(value)) {
      final cohort = 2000 + int.parse(value.substring(0, 2));
      final trackCode = value.substring(2, 6);
      final serial = int.parse(value.substring(6, 10));

      setState(() {
        _mssvInfo = {
          'cohort': cohort,
          'track_code': trackCode,
          'serial': serial,
        };
      });
    } else {
      setState(() => _mssvInfo = null);
    }
  }

  Future<void> _saveStudent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final dto = StudentDto(
        code: _codeController.text.trim(),
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        classId: _selectedClassId,
        mssv: _mssvController.text.trim().isEmpty
            ? null
            : _mssvController.text.trim(),
        mssvCohort: _mssvInfo?['cohort'] as int?,
        mssvTrackCode: _mssvInfo?['track_code'] as String?,
        mssvSerial: _mssvInfo?['serial'] as int?,
        isActive: true,
      );

      await StudentService.createStudent(dto);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thêm sinh viên thành công')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thêm sinh viên'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _saveStudent,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Lưu',
                    style: TextStyle(color: Colors.black),
                  ),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              AppSizes.paddingMedium,
              AppSizes.paddingMedium,
              AppSizes.paddingMedium,
              AppSizes.paddingMedium + viewInsets,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _codeController,
                  decoration: const InputDecoration(
                    labelText: 'Mã sinh viên *',
                    prefixIcon: Icon(Icons.badge),
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.characters,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập mã sinh viên';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSizes.paddingMedium),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Họ và tên *',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập họ tên';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSizes.paddingMedium),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final emailReg = RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                      );
                      if (!emailReg.hasMatch(value)) {
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
                    prefixIcon: Icon(Icons.phone),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      if (!RegExp(r'^[0-9]{9,11}$').hasMatch(value)) {
                        return 'Số điện thoại không hợp lệ';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSizes.paddingMedium),
                TextFormField(
                  controller: _mssvController,
                  maxLength: 10,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'MSSV (10 chữ số)',
                    prefixIcon: Icon(Icons.numbers),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: _onMssvChanged,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      if (value.length != 10) {
                        return 'MSSV phải đủ 10 chữ số';
                      }
                      if (!RegExp(r'^\d+$').hasMatch(value)) {
                        return 'MSSV chỉ gồm chữ số';
                      }
                    }
                    return null;
                  },
                ),
                if (_mssvInfo != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Khóa: ${_mssvInfo!['cohort']}'),
                        Text('Mã ngành: ${_mssvInfo!['track_code']}'),
                        Text('Số thứ tự: ${_mssvInfo!['serial']}'),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppSizes.paddingMedium),
                _loadingFaculties
                    ? const Center(child: CircularProgressIndicator())
                    : DropdownButtonFormField<String>(
                        value: _selectedFacultyId,
                        decoration: const InputDecoration(
                          labelText: 'Khoa *',
                          prefixIcon: Icon(Icons.school),
                          border: OutlineInputBorder(),
                        ),
                        items: _faculties
                            .map(
                              (faculty) => DropdownMenuItem(
                                value: faculty['id']?.toString(),
                                child: Text(faculty['name']?.toString() ?? ''),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedFacultyId = value;
                            _selectedClassId = null;
                          });
                          _fetchClasses();
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng chọn khoa';
                          }
                          if (_facultyError != null) return _facultyError;
                          return null;
                        },
                      ),
                if (_facultyError != null && !_loadingFaculties)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _facultyError!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                const SizedBox(height: AppSizes.paddingMedium),
                _loadingClasses
                    ? const Center(child: CircularProgressIndicator())
                    : DropdownButtonFormField<String>(
                        value: _selectedClassId,
                        decoration: const InputDecoration(
                          labelText: 'Lớp học *',
                          prefixIcon: Icon(Icons.class_),
                          border: OutlineInputBorder(),
                        ),
                        items: _classes
                            .map(
                              (cls) => DropdownMenuItem(
                                value: cls['id']?.toString(),
                                child: Text(cls['name']?.toString() ?? ''),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _selectedClassId = value),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng chọn lớp';
                          }
                          if (_classError != null) return _classError;
                          return null;
                        },
                      ),
                if (_classError != null && !_loadingClasses)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _classError!,
                      style: const TextStyle(color: Colors.red),
                    ),
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


