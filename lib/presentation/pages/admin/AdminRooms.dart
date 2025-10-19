import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_theme.dart';
import '../../../data/repositories/room_repository.dart';
import '../../../data/models/entity/room_entity.dart';

// ⚠️ Đảm bảo đường dẫn import BLoC thống nhất
import '../../bloc/room/room_bloc.dart';
import '../../bloc/room/room_event.dart';
import 'List/AdminRoomList.dart';

class AdminRooms extends StatelessWidget {
  const AdminRooms({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => RoomBloc(repository: RoomRepositoryImpl())..add(const LoadRooms()),
      child: const AdminRoomList(),
    );
  }
}
