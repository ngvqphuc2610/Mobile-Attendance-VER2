import 'package:flutter/material.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../data/services/api_service.dart';

class AddSesstionInstancePage extends StatefulWidget {
  const AddSesstionInstancePage({super.key});

  @override
  State<AddSesstionInstancePage> createState() => _AddSesstionInstancePageState();
}

class _AddSesstionInstancePageState extends State<AddSesstionInstancePage> {
  final _formKey = GlobalKey<FormState>();

  final _startsAtController = TextEditingController();
  final _endsAtController = TextEditingController();
  final _statusController = TextEditingController(text: 'planned');

  bool _saving = false;
  bool _loadingSections = false;
  bool _loadingRooms = false;
  String? _sectionError;
  String? _roomError;

  // Mỗi item: {"id": "...", "label": "..."}
  List<Map<String, String>> _sections = [];
  List<Map<String, String>> _rooms = [];
  String? _selectedSectionId;
  String? _selectedRoomId;

  @override
  void initState() {
    super.initState();
    _loadSections();
    _loadRooms();
  }

  Future<void> _loadSections() async {
    setState(() {
      _loadingSections = true;
      _sectionError = null;
    });
    try {
      final list = await ApiService.getList(ApiConstants.classSections);
      // build label dễ đọc: [Mã lớp] Tên môn - HK/Năm
      _sections = List<Map<String, String>>.from(
        (list as List).map((e) {
          final m = Map<String, dynamic>.from(e);
          final id = m['id']?.toString() ?? '';
          final sectionCode = m['section_code']?.toString() ?? '';
          final semester = m['semester']?.toString() ?? '';
          final year = m['year']?.toString() ?? '';
          final subjectName = (m['subject']?['name'])?.toString() ?? '';
          final label = [
            if (sectionCode.isNotEmpty) '[$sectionCode]',
            if (subjectName.isNotEmpty) subjectName,
            if (semester.isNotEmpty && year.isNotEmpty) ' - $semester/$year',
          ].join(' ');
          return {'id': id, 'label': label.isEmpty ? id : label};
        }),
      );
      setState(() {});
    } catch (e) {
      _sectionError = 'Không tải được danh sách lớp học phần: $e';
    } finally {
      setState(() => _loadingSections = false);
    }
  }

  Future<void> _loadRooms() async {
    setState(() {
      _loadingRooms = true;
      _roomError = null;
    });
    try {
      final list = await ApiService.getList(ApiConstants.rooms);
      _rooms = List<Map<String, String>>.from(
        (list as List).map((e) {
          final m = Map<String, dynamic>.from(e);
          final id = m['id']?.toString() ?? '';
          // Tên hiển thị: name (hoặc code nếu bạn dùng code)
          final name = m['name']?.toString() ?? (m['code']?.toString() ?? id);
          return {'id': id, 'label': name};
        }),
      );
      setState(() {});
    } catch (e) {
      _roomError = 'Không tải được danh sách phòng: $e';
    } finally {
      setState(() => _loadingRooms = false);
    }
  }

  @override
  void dispose() {
    _startsAtController.dispose();
    _endsAtController.dispose();
    _statusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sectionItems = _sections
        .map((e) => DropdownMenuItem<String>(
              value: e['id'],
              child: Text(e['label'] ?? e['id']!),
            ))
        .toList();

    final roomItems = _rooms
        .map((e) => DropdownMenuItem<String>(
              value: e['id'],
              child: Text(e['label'] ?? e['id']!),
            ))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thêm phiên học'),
        backgroundColor: AppTheme.adminPrimaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saving ? null : _save,
          )
        ],
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              // ------ SECTION DROPDOWN ------
              DropdownButtonFormField<String>(
                value: _selectedSectionId,
                decoration: InputDecoration(
                  labelText: 'Lớp học phần (Section)',
                  border: const OutlineInputBorder(),
                  helperText: _sectionError,
                  helperStyle: const TextStyle(color: Colors.red),
                ),
                isExpanded: true,
                items: sectionItems,
                onChanged: _loadingSections ? null : (v) => setState(() => _selectedSectionId = v),
                validator: (_) {
                  if (_selectedSectionId == null || _selectedSectionId!.isEmpty) {
                    return 'Chọn lớp học phần';
                  }
                  return null;
                },
              ),
              if (_loadingSections) const Padding(
                padding: EdgeInsets.only(top: 8),
                child: LinearProgressIndicator(),
              ),
              const SizedBox(height: 16),

              // ------ STARTS_AT ------
              TextFormField(
                controller: _startsAtController,
                decoration: const InputDecoration(
                  labelText: 'Thời gian bắt đầu',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Nhập thời gian bắt đầu'
                    : null,
              ),
              const SizedBox(height: 16),

              // ------ ENDS_AT ------
              TextFormField(
                controller: _endsAtController,
                decoration: const InputDecoration(
                  labelText: 'Thời gian kết thúc',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Nhập thời gian kết thúc'
                    : null,
              ),
              const SizedBox(height: 16),

              // ------ STATUS ------
              DropdownButtonFormField<String>(
                value: _statusController.text.isNotEmpty ? _statusController.text : null,
                decoration: const InputDecoration(
                  labelText: 'Trạng thái',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'planned', child: Text('Đã lên kế hoạch')),
                  DropdownMenuItem(value: 'ongoing', child: Text('Đang diễn ra')),
                  DropdownMenuItem(value: 'completed', child: Text('Hoàn thành')),
                  DropdownMenuItem(value: 'cancelled', child: Text('Đã hủy')),
                ],
                onChanged: (value) => setState(() => _statusController.text = value ?? 'planned'),
                validator: (_) => (_statusController.text.isEmpty) ? 'Chọn trạng thái' : null,
              ),
              const SizedBox(height: 16),

              // ------ ROOM DROPDOWN (optional) ------
              DropdownButtonFormField<String>(
                value: _selectedRoomId,
                decoration: InputDecoration(
                  labelText: 'Phòng học (tùy chọn)',
                  border: const OutlineInputBorder(),
                  helperText: _roomError,
                  helperStyle: const TextStyle(color: Colors.red),
                ),
                isExpanded: true,
                items: roomItems,
                onChanged: _loadingRooms ? null : (v) => setState(() => _selectedRoomId = v),
              ),
              if (_loadingRooms) const Padding(
                padding: EdgeInsets.only(top: 8),
                child: LinearProgressIndicator(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      await ApiService.create(ApiConstants.sessionInstances, {
        'section_id': _selectedSectionId,
        'starts_at': _startsAtController.text.trim(),
        'ends_at': _endsAtController.text.trim(),
        'status': _statusController.text.trim(),
        // room_id optional
        'room_id': (_selectedRoomId == null || _selectedRoomId!.isEmpty) ? null : _selectedRoomId,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thêm phiên học thành công!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi thêm phiên học: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
