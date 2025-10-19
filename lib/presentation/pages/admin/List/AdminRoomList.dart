import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_theme.dart';
import '../../../../data/models/entity/room_entity.dart';

// ⚠️ Đảm bảo đường dẫn import BLoC thống nhất với file trên
import '../../../bloc/room/room_bloc.dart';
import '../../../bloc/room/room_event.dart';
import '../../../bloc/room/room_state.dart';

import '../Add/AddRoomPage.dart';
import '../Edit/EditRoomPage.dart';

class AdminRoomList extends StatefulWidget {
  const AdminRoomList({super.key});

  @override
  State<AdminRoomList> createState() => _AdminRoomListState();
}

class _AdminRoomListState extends State<AdminRoomList> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterRooms(String q) {
    context.read<RoomBloc>().add(FilterRooms(q));
  }

  void _delete(RoomEntity room) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa phòng'),
        content: Text('Bạn muốn xóa phòng "${room.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<RoomBloc>().add(DeleteRoom(room.id));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  Future<void> _openAdd() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddRoomPage()),
    );
    if (created == true && mounted) {
      context.read<RoomBloc>().add(const LoadRooms());
    }
  }

  Future<void> _openEdit(RoomEntity room) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EditRoomPage(room: room.toJson())),
    );
    if (updated == true && mounted) {
      context.read<RoomBloc>().add(const LoadRooms());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý phòng học'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(onPressed: _openAdd, icon: const Icon(Icons.add)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAdd,
        icon: const Icon(Icons.add),
        label: const Text('Thêm phòng'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSizes.paddingMedium),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Tìm theo tên, sức chứa...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                ),
                filled: true,
              ),
              onChanged: _filterRooms,
            ),
          ),
          Expanded(
            // ✅ KHÔNG gọi lại AdminRoomList ở đây nữa
            child: BlocBuilder<RoomBloc, RoomState>(
              builder: (context, state) {
                if (state is RoomLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is RoomError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(state.message, style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: () => context.read<RoomBloc>().add(const LoadRooms()),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  );
                }

                if (state is RoomsLoaded) {
                  final items = state.filteredRooms;
                  if (items.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(state.rooms.isEmpty ? Icons.meeting_room_outlined : Icons.search_off,
                              size: 64, color: Colors.grey),
                          const SizedBox(height: 12),
                          Text(
                            state.rooms.isEmpty ? 'Chưa có phòng nào' : 'Không tìm thấy kết quả',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 12),
                          if (state.rooms.isEmpty)
                            ElevatedButton.icon(
                              onPressed: _openAdd,
                              icon: const Icon(Icons.add),
                              label: const Text('Thêm phòng đầu tiên'),
                            ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.paddingMedium,
                      vertical: AppSizes.paddingSmall,
                    ),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final r = items[i];
                      return Card(
                        child: ListTile(
                          onTap: () => _openEdit(r),
                          title: Text(r.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (r.code?.isNotEmpty == true) Text('Mã: ${r.code}'),
                              if (r.capacity != null) Text('Sức chứa: ${r.capacity}'),
                              if (r.location?.isNotEmpty == true) Text('Khu: ${r.location}'),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (v) {
                              switch (v) {
                                case 'edit':
                                  _openEdit(r);
                                  break;
                                case 'delete':
                                  _delete(r);
                                  break;
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: 'edit',
                                child: ListTile(
                                  leading: Icon(Icons.edit),
                                  title: Text('Sửa'),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: ListTile(
                                  leading: Icon(Icons.delete, color: Colors.red),
                                  title: Text('Xóa', style: TextStyle(color: Colors.red)),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }

                // Trạng thái khởi tạo
                return Center(
                  child: ElevatedButton.icon(
                    onPressed: () => context.read<RoomBloc>().add(const LoadRooms()),
                    icon: const Icon(Icons.download),
                    label: const Text('Tải danh sách phòng'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
