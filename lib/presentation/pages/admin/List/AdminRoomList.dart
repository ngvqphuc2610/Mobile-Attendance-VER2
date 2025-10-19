
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../data/models/entity/room_entity.dart';
import '../../../bloc/room/room_bloc.dart';
import '../../../bloc/room/room_event.dart';
import '../../../bloc/room/room_state.dart';
import '../../../widgets/loading_widget.dart';
import '../Edit/EditRoomPage.dart';
import '../Add/AddRoomPage.dart';

class AdminRoomList extends StatefulWidget {
  const AdminRoomList({Key? key}) : super(key: key);

  @override
  _AdminRoomListState createState() => _AdminRoomListState();
}

class _AdminRoomListState extends State<AdminRoomList> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<RoomBloc>().add(const LoadRooms());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterRooms(String query) {
    context.read<RoomBloc>().add(FilterRooms(query));
  }

  void _deleteRoom(RoomEntity room) {
    context.read<RoomBloc>().add(DeleteRoom(room.id));
  }

  Future<void> _showEditRoomPage(RoomEntity room) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditRoomPage(room: room.toJson()),
      ),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddRoomPage()),
            ),
          ),
        ],
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
              ),
              onChanged: _filterRooms,
            ),
          ),
          Expanded(child: AdminRoomList()),
        ],
      ),
    );
  }
}
