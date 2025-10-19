
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_theme.dart';
import '../../../data/models/entity/room_entity.dart';
import '../../../presentation/bloc/room/room_bloc.dart';
import '../../../presentation/bloc/room/room_event.dart';
import '../../../presentation/bloc/room/room_state.dart';
import '../../../presentation/widgets/loading_widget.dart';
import '../../../data/repositories/room_repository.dart';
import 'List/AdminRoomList.dart';

class AdminRooms extends StatefulWidget {
  const AdminRooms({super.key});

  @override
  State<AdminRooms> createState() => _AdminRoomsState();
}

class _AdminRoomsState extends State<AdminRooms> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RoomBloc(repository: RoomRepositoryImpl())..add(const LoadRooms()),
      child: const AdminRoomList(),
    );
  }
}
