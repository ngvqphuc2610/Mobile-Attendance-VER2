import 'package:flutter/material.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../data/services/api_service.dart';
import '../../../../core/constants/api_constants.dart';

class AddClassSectionPage extends StatefulWidget {
  const AddClassSectionPage({super.key});

  @override
  State<AddClassSectionPage> createState() => _AddClassSectionPageState();
}

class _AddClassSectionPageState extends State<AddClassSectionPage> {
  final _formKey = GlobalKey<FormState>();

  final _subjectIdController = TextEditingController();
  final _semesterController = TextEditingController();
  final _yearController = TextEditingController();
  final _sectionCodeController = TextEditingController();
  final _capacityController = TextEditingController();

  bool _saving = false;
  bool _loadingSubjects = false;
  String? _subjectError;

  List<Map<String, String>> _subjects = [];
  String? _selectedSubjectId;

  @override
  void initState() {
    super.initState();
    _fetchSubjects();
  }

  @override
  void dispose() {
    _subjectIdController.dispose();
    _semesterController.dispose();
    _yearController.dispose();
    _sectionCodeController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _fetchSubjects() async {
    setState(() {
      _loadingSubjects = true;
      _subjectError = null;
    });

    try {
      final resp = await ApiService.getList(ApiConstants.subjects);
      final list = _unwrapList(resp);

      final items = <Map<String, String>>[];
      for (final e in list) {
        if (e is! Map) continue;
        final id = _extractId(e, ['id', 'subjectId', 'subject_id']);
        if (id.isEmpty) continue;

        final name = _extractFirstNonEmpty(e, ['name', 'code']);
        items.add({'id': id, 'label': name.isNotEmpty ? name : 'Môn $id'});
      }

      if (!mounted) return;
      setState(() {
        _subjects = items;
        _selectedSubjectId = _subjects.isNotEmpty
            ? _subjects.first['id']
            : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _subjectError = 'Lỗi tải môn học: $e';
        _subjects = [];
        _selectedSubjectId = null;
      });
    } finally {
      if (mounted) setState(() => _loadingSubjects = false);
    }
  }

  List<dynamic> _unwrapList(dynamic resp) {
    if (resp == null) return [];
    if (resp is List) return resp;
    if (resp is Map) {
      // các trường hay gặp: data / items / results
      for (final key in ['data', 'items', 'results']) {
        final v = resp[key];
        if (v is List) return v;
      }
    }
    return [];
  }

  String _extractId(Map m, List<String> candidates) {
    for (final k in candidates) {
      final v = m[k];
      if (v != null) return v.toString();
    }
    return '';
  }

  String _extractFirstNonEmpty(Map m, List<String> keys) {
    for (final k in keys) {
      final v = m[k];
      if (v != null && v.toString().trim().isNotEmpty) {
        return v.toString();
      }
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return WillPopScope(
      onWillPop: () async => !_saving, // chặn back khi đang lưu
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Thêm Lớp học phần'),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: TextButton.icon(
                onPressed: _saving ? null : _saveClassSection,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save, color: Colors.white),
                label: const Text('Lưu', style: TextStyle(color: Colors.white)),
                style: TextButton.styleFrom(foregroundColor: Colors.white),
              ),
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.paddingMedium),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                0,
                0,
                0,
                AppSizes.paddingMedium + bottom,
              ),
              child: Column(
                children: [
                  if (_loadingSubjects) ...[
                    const Center(child: CircularProgressIndicator()),
                  ] else ...[
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: _subjects.any((s) => s['id'] == _selectedSubjectId)
                          ? _selectedSubjectId
                          : null,
                      decoration: const InputDecoration(
                        labelText: 'Môn học *',
                        prefixIcon: Icon(Icons.book),
                        border: OutlineInputBorder(),
                      ),
                      items: _subjects.map((s) {
                        return DropdownMenuItem<String>(
                          value: s['id'],
                          child: Text(s['label'] ?? ''),
                        );
                      }).toList(),
                      selectedItemBuilder: (_) => _subjects.map((s) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            s['label'] ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => _selectedSubjectId = v),
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Vui lòng chọn môn học'
                          : null,
                    ),
                  ],
                  const SizedBox(height: AppSizes.paddingMedium),
                  TextFormField(
                    controller: _semesterController,
                    decoration: const InputDecoration(
                      labelText: 'Học kỳ *',
                      hintText: 'VD: 1, 2, 3...',
                      prefixIcon: Icon(Icons.numbers),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final v = (value ?? '').trim();
                      if (v.isEmpty) return 'Vui lòng nhập học kỳ';
                      final parsed = int.tryParse(v);
                      if (parsed == null) return 'Học kỳ phải là số nguyên';
                      if (parsed <= 0) return 'Học kỳ phải lớn hơn 0';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSizes.paddingMedium),
                  TextFormField(
                    controller: _yearController,
                    decoration: const InputDecoration(
                      labelText: 'Năm học *',
                      hintText: 'VD: 2021, 2022...',
                      prefixIcon: Icon(Icons.numbers),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final v = (value ?? '').trim();
                      if (v.isEmpty) return 'Vui lòng nhập năm học';
                      final parsed = int.tryParse(v);
                      if (parsed == null) return 'Năm học phải là số nguyên';
                      if (parsed <= 0) return 'Năm học phải lớn hơn 0';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSizes.paddingMedium),
                  TextFormField(
                    controller: _sectionCodeController,
                    decoration: const InputDecoration(
                      labelText: 'Mã lớp học phần *',
                      hintText: 'VD: CNTT1',
                      prefixIcon: Icon(Icons.code),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final v = (value ?? '').trim();
                      if (v.isEmpty) return 'Vui lòng nhập mã lớp học phần';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSizes.paddingMedium),
                  TextFormField(
                    controller: _capacityController,
                    decoration: const InputDecoration(
                      labelText: 'Sức chứa',
                      hintText: 'VD: 50',
                      prefixIcon: Icon(Icons.people),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _saveClassSection() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

    // Bảo vệ: phải chọn môn học
    if (_selectedSubjectId == null || _selectedSubjectId!.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vui lòng chọn môn học')));
      return;
    }

    // Parse số an toàn (validator đã kiểm tra, nhưng vẫn phòng hờ)
    final semester = int.tryParse(_semesterController.text.trim());
    final year = int.tryParse(_yearController.text.trim());
    final capacity = _capacityController.text.trim().isEmpty
        ? null
        : int.tryParse(_capacityController.text.trim());

    if (semester == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Học kỳ phải là số nguyên hợp lệ')),
      );
      return;
    }
    if (year == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Năm học phải là số nguyên hợp lệ')),
      );
      return;
    }
    if (_capacityController.text.trim().isNotEmpty && capacity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sức chứa phải là số nguyên')),
      );
      return;
    }

    final payload = <String, dynamic>{
      'subject_id': _selectedSubjectId,
      'semester': semester,
      'year': year,
      'section_code': _sectionCodeController.text.trim(),
      if (capacity != null) 'capacity': capacity, // chỉ gửi nếu có
    };

    setState(() => _saving = true);
    try {
      await ApiService.create(ApiConstants.classSections, payload);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thêm lớp học phần thành công!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true); // trả về true để list reload
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi tạo lớp học phần: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
