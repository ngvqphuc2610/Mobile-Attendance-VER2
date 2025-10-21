
import 'package:flutter/material.dart';

import '../../../../core/constants/app_theme.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../data/models/dto/student_dto.dart';
import '../../../../data/services/api_service.dart';
import '../../../../data/services/student_service.dart';

class EditStudentPage extends StatefulWidget {
  final Map<String, dynamic> student;

  const EditStudentPage({super.key, required this.student});

  @override
  State<EditStudentPage> createState() => _EditStudentPageState();
}

class _EditStudentPageState extends State<EditStudentPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _codeController;
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _mssvController;

  bool _saving = false;
  bool _loadingClasses = false;

  List<Map<String, dynamic>> _classes = [];
  String? _selectedClassId;
  Map<String, dynamic>? _mssvInfo;
  String? _classError;

  @override
  void initState() {
    super.initState();
    _initialiseControllers();
    _fetchClasses();
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

  void _initialiseControllers() {
    _codeController =
        TextEditingController(text: widget.student['code']?.toString() ?? '');
    _nameController = TextEditingController(
      text: widget.student['full_name']?.toString() ?? '',
    );
    _emailController = TextEditingController(
      text: widget.student['email']?.toString() ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.student['phone']?.toString() ?? '',
    );
    _mssvController = TextEditingController(
      text: widget.student['mssv']?.toString() ?? '',
    );

    _selectedClassId = widget.student['class_id']?.toString();
    if (widget.student['mssv'] != null) {
      _onMssvChanged(widget.student['mssv'].toString());
    }
  }

  Future<void> _fetchClasses() async {
    setState(() {
      _loadingClasses = true;
      _classError = null;
    });

    try {
      final response = await ApiService.getList(ApiConstants.classes);
      setState(() {
        _classes = List<Map<String, dynamic>>.from(response);
        if (_selectedClassId == null && _classes.isNotEmpty) {
          _selectedClassId = _classes.first['id']?.toString();
        }
      });
    } catch (e) {
      setState(() {
        _classError = 'Lỗi tải lớp học: $e';
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

  Future<void> _updateStudent() async {
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
      );

      await StudentService.updateStudent(
        widget.student['profile_id'].toString(),
        dto,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật sinh viên thành công')),
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
        title: const Text('Chỉnh sửa sinh viên'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _updateStudent,
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
                      final emailReg =
                          RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
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
                            return 'Vui lòng chọn lớp học';
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


