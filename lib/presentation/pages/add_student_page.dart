import 'package:flutter/material.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddStudentPage extends StatefulWidget {
  const AddStudentPage({super.key});

  @override
  State<AddStudentPage> createState() => _AddStudentPageState();
}

class _AddStudentPageState extends State<AddStudentPage> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();

  String? _selectedClassId;
  List<Map<String, dynamic>> _classes = [];
  bool _loadingClasses = true;
  String? _classError;

  @override
  void initState() {
    super.initState();
    _fetchClasses();
  }

  Future<void> _fetchClasses() async {
    setState(() {
      _loadingClasses = true;
      _classError = null;
    });
    try {
      final supabase = Supabase.instance.client;
      final res = await supabase.from('classes').select('id, name');
      if (res.isEmpty) {
        setState(() {
          _classError = 'Không tìm thấy lớp học';
          _loadingClasses = false;
        });
        return;
      }
      setState(() {
        _classes = List<Map<String, dynamic>>.from(res);
        _loadingClasses = false;
      });
    } catch (e) {
      setState(() {
        _classError = 'Lỗi tải lớp học: $e';
        _loadingClasses = false;
      });
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.addStudent),
        actions: [
          TextButton(
            onPressed: _saveStudent,
            child: const Text(
              AppStrings.save,
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingMedium),
          child: Column(
            children: [
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: AppStrings.studentCode,
                  prefixIcon: Icon(Icons.badge),
                ),
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
                  labelText: AppStrings.studentName,
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập tên sinh viên';
                  }
                  return null;
                },
              ),

              const SizedBox(height: AppSizes.paddingMedium),

              _loadingClasses
                  ? const Center(child: CircularProgressIndicator())
                  : _classError != null
                  ? Text(
                      _classError!,
                      style: const TextStyle(color: Colors.red),
                    )
                  : DropdownButtonFormField<String>(
                      value: _selectedClassId,
                      decoration: const InputDecoration(
                        labelText: AppStrings.className,
                        prefixIcon: Icon(Icons.class_),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Chọn lớp học'),
                        ),
                        ..._classes.map(
                          (cls) => DropdownMenuItem(
                            value: cls['id'].toString(),
                            child: Text(cls['name'] ?? ''),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedClassId = value;
                        });
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveStudent() {
    if (_formKey.currentState!.validate()) {
      if (_selectedClassId == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Vui lòng chọn lớp học')));
        return;
      }
      final supabase = Supabase.instance.client;
      final code = _codeController.text.trim();
      final name = _nameController.text.trim();
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator()),
      );
      supabase
          .from('profiles')
          .insert({
            'code': code,
            'full_name': name,
            'class_id': _selectedClassId,
            'is_active': true,
          })
          .then((_) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Thêm sinh viên thành công!')),
            );
            Navigator.of(context).pop(); // Quay lại trang trước
          })
          .catchError((e) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
          });
    }
  }
}
