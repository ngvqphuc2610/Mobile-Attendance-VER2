import 'package:flutter/material.dart';

import '../../../../core/constants/app_theme.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../data/models/dto/teacher_dto.dart';
import '../../../../data/services/api_service.dart';
import '../../../../data/services/teacher_service.dart';

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

  bool _saving = false;
  bool _loadingFaculties = false;
  bool _loadingRooms = false;
  String? _facultyError;
  String? _roomsError;

  List<Map<String, dynamic>> _faculties = [];
  List<Map<String, dynamic>> _rooms = [];
  String? _selectedFacultyId;
  String? _selectedRoomId;

  @override
  void initState() {
    super.initState();
    _fetchFaculties();
    _fetchRooms();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _titleController.dispose();
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
        }
      });
    } catch (e) {
      setState(() => _facultyError = 'Lỗi tải danh sách khoa: $e');
    } finally {
      setState(() => _loadingFaculties = false);
    }
  }

  Future<void> _fetchRooms() async {
    setState(() {
      _loadingRooms = true;
      _roomsError = null;
    });
    try {
      final response = await ApiService.getList(ApiConstants.rooms);
      setState(() {
        _rooms = List<Map<String, dynamic>>.from(response);
        if (_rooms.isNotEmpty) {
          _selectedRoomId = _rooms.first['id']?.toString();
        }
      });
    } catch (e) {
      setState(() => _roomsError = 'Không thể tải danh sách phòng: $e');
    } finally {
      setState(() => _loadingRooms = false);
    }
  }

  String? _resolveOfficeValue() {
    if (_selectedRoomId == null) return null;
    Map<String, dynamic>? selectedRoom;
    for (final room in _rooms) {
      if (room['id']?.toString() == _selectedRoomId) {
        selectedRoom = room;
        break;
      }
    }
    if (selectedRoom == null) return null;

    final name = selectedRoom['name']?.toString();
    if (name != null && name.trim().isNotEmpty) return name.trim();

    final code = selectedRoom['code']?.toString();
    if (code != null && code.trim().isNotEmpty) return code.trim();

    return null;
  }

  Future<void> _saveTeacher() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final dto = TeacherDto(
        code: _codeController.text.trim(),
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        facultyId: _selectedFacultyId,
        title: _titleController.text.trim().isEmpty
            ? null
            : _titleController.text.trim(),
        office: _resolveOfficeValue(), // lấy từ phòng đã chọn
        isActive: true,
      );

      await TeacherService.createTeacher(dto);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thêm giảng viên thành công'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      String message = 'Lỗi: $e';
      if (e.toString().contains('duplicate')) {
        message = 'Mã hoặc email giảng viên đã tồn tại';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thêm giảng viên'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _saveTeacher,
            child: _saving
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Lưu', style: TextStyle(color: Colors.white)),
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
                    labelText: 'Mã giảng viên *',
                    prefixIcon: Icon(Icons.badge),
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.characters,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Vui lòng nhập mã giảng viên' : null,
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
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Vui lòng nhập họ tên' : null,
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
                      final emailReg = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$');
                      if (!emailReg.hasMatch(value)) return 'Email không hợp lệ';
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
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Chức danh',
                    prefixIcon: Icon(Icons.work_outline),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSizes.paddingMedium),

                // --- Dropdown phòng làm việc thay vì TextFormField ---
                _loadingRooms
                    ? const Center(child: CircularProgressIndicator())
                    : DropdownButtonFormField<String>(
                        value: _selectedRoomId,
                        decoration: const InputDecoration(
                          labelText: 'Phòng làm việc',
                          prefixIcon: Icon(Icons.location_on_outlined),
                          border: OutlineInputBorder(),
                        ),
                        items: _rooms
                            .map((room) => DropdownMenuItem<String>(
                                  value: room['id']?.toString(),
                                  child: Text(
                                    room['name']?.toString() ??
                                        room['code']?.toString() ??
                                        'Phòng',
                                  ),
                                ))
                            .toList(),
                        onChanged: (value) => setState(() => _selectedRoomId = value),
                      ),
                if (_roomsError != null && !_loadingRooms)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(_roomsError!, style: const TextStyle(color: Colors.red)),
                  ),
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
                            .map((faculty) => DropdownMenuItem<String>(
                                  value: faculty['id']?.toString(),
                                  child: Text(faculty['name']?.toString() ?? ''),
                                ))
                            .toList(),
                        onChanged: (value) => setState(() => _selectedFacultyId = value),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Vui lòng chọn khoa';
                          if (_facultyError != null) return _facultyError;
                          return null;
                        },
                      ),
                if (_facultyError != null && !_loadingFaculties)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(_facultyError!, style: const TextStyle(color: Colors.red)),
                  ),

                const SizedBox(height: AppSizes.paddingLarge),
                const Text('* Trường bắt buộc',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
