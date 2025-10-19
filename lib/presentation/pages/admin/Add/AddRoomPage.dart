
import 'package:flutter/material.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../data/services/api_service.dart';
import '../../../../core/constants/api_constants.dart';

class AddRoomPage extends StatefulWidget {
  const AddRoomPage({super.key});

  @override
  State<AddRoomPage> createState() => _AddRoomPageState();
}

class _AddRoomPageState extends State<AddRoomPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _capacityController = TextEditingController();

  bool _saving = false;
  String? _capacityError;

  @override
  void dispose() {
    _nameController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thêm phòng học'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _saveRoom,
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
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên phòng học *',
                  hintText: 'VD: A101',
                  prefixIcon: Icon(Icons.meeting_room),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập tên phòng học';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSizes.paddingMedium),
              TextFormField(
                controller: _capacityController,
                decoration: const InputDecoration(
                  labelText: 'Sức chứa *',
                  hintText: 'VD: 50',
                  prefixIcon: Icon(Icons.people),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập sức chứa';
                  }
                  if (!RegExp(r'^\d+$').hasMatch(value)) {
                    return 'Sức chứa phải là số nguyên';
                  }
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
    );
  }

  void _saveRoom() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      await ApiService.create(ApiConstants.rooms, {
        'name': _nameController.text.trim(),
        'capacity': int.parse(_capacityController.text.trim()),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thêm phòng học thành công!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
