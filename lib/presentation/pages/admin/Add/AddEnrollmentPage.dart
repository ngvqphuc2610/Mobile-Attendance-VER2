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

  bool _saving = false;
  bool _loadingSections = false;
  bool _loadingStudents = false;
  String? _sectionError;
  String? _studentError;

  // chuẩn hoá: mỗi item là {"id": "123", "label": "..." }
  List<Map<String, String>> _sections = [];
  List<Map<String, String>> _students = [];
  String? _selectedSectionId;
  String? _selectedStudentId;

  @override
  void initState() {
    super.initState();
    _fetchSections();
    _fetchStudents();
  }

  // ---------- helpers chuẩn hoá ----------
  // 1) Helper rõ ràng, KHÔNG cast rườm rà
  List<dynamic> _unwrapList(dynamic resp) {
    if (resp is List) return resp;
    if (resp is Map<String, dynamic>) {
      for (final k in const ['data', 'items', 'results', 'content']) {
        final v = resp[k];
        if (v is List) return v;
      }
    }
    return const [];
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
  // 1) Helper rõ ràng, KHÔNG cast rườm rà

  // ---------- fetch ----------
  Future<void> _fetchSections() async {
    if (!mounted) return;
    setState(() {
      _loadingSections = true;
      _sectionError = null;
    });

    try {
      final resp = await ApiService.getList(ApiConstants.classSections);

      // ✅ dùng helper, có kiểu rõ ràng
      final List<dynamic> list = _unwrapList(resp);

      final items = <Map<String, String>>[];
      for (final raw in list) {
        if (raw is! Map) continue;
        final e = Map<String, dynamic>.from(raw);

        // id
        String id = '';
        for (final k in ['id', 'sectionId', 'section_id']) {
          final v = e[k];
          if (v != null) {
            id = v.toString();
            break;
          }
        }
        if (id.isEmpty) continue;

        // section code / name
        String sectionCode = '';
        for (final k in [
          'section_code',
          'sectionCode',
          'code',
          'name',
          'sectionName',
        ]) {
          final v = e[k]?.toString().trim();
          if (v != null && v.isNotEmpty) {
            sectionCode = v;
            break;
          }
        }

        // subject name
        String subjectName = '';
        final subj = e['subject'];
        if (subj is Map) {
          subjectName =
              (subj['name'] ?? subj['subjectName'] ?? subj['title'] ?? '')
                  .toString();
        }
        if (subjectName.trim().isEmpty) {
          for (final k in ['subject_name', 'subjectName', 'subject_title']) {
            final v = e[k]?.toString().trim();
            if (v != null && v.isNotEmpty) {
              subjectName = v;
              break;
            }
          }
        }

        final label = (sectionCode.isNotEmpty && subjectName.isNotEmpty)
            ? '$sectionCode • $subjectName'
            : (sectionCode.isNotEmpty
                  ? sectionCode
                  : (subjectName.isNotEmpty
                        ? subjectName
                        : 'Lớp học phần $id'));

        items.add({'id': id, 'label': label});
      }

      if (!mounted) return;
      setState(() {
        _sections = items;
        if (!_sections.any((s) => s['id'] == _selectedSectionId)) {
          _selectedSectionId = _sections.isNotEmpty
              ? _sections.first['id']
              : null;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sectionError = 'Lỗi tải lớp học phần: $e';
        _sections = [];
        _selectedSectionId = null;
      });
    } finally {
      if (mounted) setState(() => _loadingSections = false);
    }
  }

  Future<void> _fetchStudents() async {
    if (!mounted) return;
    setState(() {
      _loadingStudents = true;
      _studentError = null;
    });

    try {
      final resp = await ApiService.getList(ApiConstants.students);
      final List<dynamic> list = _unwrapList(resp);

      final items = <Map<String, String>>[];
      for (final raw in list) {
        if (raw is! Map) continue;
        final e = Map<String, dynamic>.from(raw);

        // id
        String id = '';
        for (final k in ['id', 'studentId', 'student_id', 'profileId', 'profile_id']) {
          final v = e[k];
          if (v != null) {
            id = v.toString();
            break;
          }
        }
        if (id.isEmpty) continue;

        // full name
        String fullName = '';
        for (final k in ['fullName', 'full_name', 'name']) {
          final v = e[k]?.toString().trim();
          if (v != null && v.isNotEmpty) {
            fullName = v;
            break;
          }
        }
        if (fullName.isEmpty) {
          final fn = (e['firstName'] ?? e['first_name'] ?? '')
              .toString()
              .trim();
          final ln = (e['lastName'] ?? e['last_name'] ?? '').toString().trim();
          if (fn.isNotEmpty || ln.isNotEmpty) {
            fullName = [ln, fn].where((s) => s.isNotEmpty).join(' ');
          }
        }
        if (fullName.isEmpty && e['profile'] is Map) {
          final p = e['profile'] as Map;
          final direct = (p['fullName'] ?? p['name'] ?? '').toString().trim();
          if (direct.isNotEmpty) {
            fullName = direct;
          } else {
            final fn = (p['firstName'] ?? p['first_name'] ?? '')
                .toString()
                .trim();
            final ln = (p['lastName'] ?? p['last_name'] ?? '')
                .toString()
                .trim();
            if (fn.isNotEmpty || ln.isNotEmpty) {
              fullName = [ln, fn].where((s) => s.isNotEmpty).join(' ');
            }
          }
        }

        // student code
        String stuCode = '';
        for (final k in ['studentCode', 'student_code', 'code', 'mssv']) {
          final v = e[k]?.toString().trim();
          if (v != null && v.isNotEmpty) {
            stuCode = v;
            break;
          }
        }

        final label = (fullName.isNotEmpty && stuCode.isNotEmpty)
            ? '$fullName • $stuCode'
            : (fullName.isNotEmpty
                  ? fullName
                  : (stuCode.isNotEmpty ? stuCode : 'SV $id'));

        items.add({'id': id, 'label': label});
      }

      if (!mounted) return;
      setState(() {
        _students = items;
        if (!_students.any((s) => s['id'] == _selectedStudentId)) {
          _selectedStudentId = _students.isNotEmpty
              ? _students.first['id']
              : null;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _studentError = 'Lỗi tải sinh viên: $e';
        _students = [];
        _selectedStudentId = null;
      });
    } finally {
      if (mounted) setState(() => _loadingStudents = false);
    }
  }

  // ---------- submit ----------
  Future<void> _saveEnrollment() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      // ⚠️ KEY gửi đi: giữ snake_case như trang Edit của bạn
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

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thêm sinh viên vào lớp học phần'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _saving
                ? null
                : () {
                    _fetchSections();
                    _fetchStudents();
                  },
          ),
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
                // ---- dropdown sections ----
                if (_loadingSections)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else
                  DropdownButtonFormField<String>(
                    isExpanded: true, // ✅ cho phép full width và ellipsis
                    value: _sections.any((s) => s['id'] == _selectedSectionId)
                        ? _selectedSectionId
                        : null,
                    decoration: const InputDecoration(
                      isDense: true, // ✅ giảm padding top/bottom
                      labelText: 'Lớp học phần *',
                      prefixIcon: Icon(Icons.class_),
                      border: OutlineInputBorder(),
                    ),
                    items: _sections.map((s) {
                      return DropdownMenuItem<String>(
                        value: s['id'],
                        // item trong menu: hiển thị đủ (không cần ellipsis)
                        child: Text(s['label'] ?? ''),
                      );
                    }).toList(),
                    // item đang được chọn (nằm trên nút): hiển thị ellipsis để khỏi tràn
                    selectedItemBuilder: (context) {
                      return _sections.map((s) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            s['label'] ?? '',
                            overflow: TextOverflow.ellipsis, // ✅ cắt bớt
                            maxLines: 1,
                          ),
                        );
                      }).toList();
                    },
                    onChanged: (v) => setState(() => _selectedSectionId = v),
                    validator: (v) {
                      if (v == null || v.isEmpty)
                        return 'Vui lòng chọn lớp học phần';
                      if (_sectionError != null) return _sectionError;
                      return null;
                    },
                  ),
                if (!_loadingSections &&
                    _sections.isEmpty &&
                    _sectionError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _sectionError!,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _fetchSections,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Thử lại'),
                  ),
                ],

                const SizedBox(height: AppSizes.paddingMedium),

                // ---- dropdown students ----
                if (_loadingStudents)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else
                  DropdownButtonFormField<String>(
                    isExpanded: true, // ✅
                    value: _students.any((s) => s['id'] == _selectedStudentId)
                        ? _selectedStudentId
                        : null,
                    decoration: const InputDecoration(
                      isDense: true, // ✅
                      labelText: 'Sinh viên *',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    items: _students.map((s) {
                      return DropdownMenuItem<String>(
                        value: s['id'],
                        child: Text(s['label'] ?? ''),
                      );
                    }).toList(),
                    selectedItemBuilder: (context) {
                      return _students.map((s) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            s['label'] ?? '',
                            overflow: TextOverflow.ellipsis, // ✅
                            maxLines: 1,
                          ),
                        );
                      }).toList();
                    },
                    onChanged: (v) => setState(() => _selectedStudentId = v),
                    validator: (v) {
                      if (v == null || v.isEmpty)
                        return 'Vui lòng chọn sinh viên';
                      if (_studentError != null) return _studentError;
                      return null;
                    },
                  ),
                if (!_loadingStudents &&
                    _students.isEmpty &&
                    _studentError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _studentError!,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _fetchStudents,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Thử lại'),
                  ),
                ],

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
