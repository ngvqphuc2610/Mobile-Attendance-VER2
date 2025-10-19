import 'package:flutter/material.dart';

import 'AdminSectionSchedules.dart';
import 'AdminSessionInstances.dart';
import 'AdminTeachingAssignments.dart';

class AdminSchedules extends StatelessWidget {
  const AdminSchedules({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Quản lý lịch học'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.schedule), text: 'Buổi học'),
              Tab(icon: Icon(Icons.event_repeat), text: 'Phiên học'),
              Tab(icon: Icon(Icons.groups_2), text: 'Phân công GV'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            AdminSectionSchedules(),
            AdminSessionInstances(),
            AdminTeachingAssignments(),
          ],
        ),
      ),
    );
  }
}
