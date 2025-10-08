import 'package:flutter/material.dart';
import 'package:mobile_attendance/presentation/pages/home_page.dart';

// Tạm thời tái sử dụng HomeContent. Có thể tách UI riêng cho sinh viên sau.
class StudentHomePage extends StatelessWidget {
  const StudentHomePage({super.key});

  @override
  Widget build(BuildContext context) => const HomeContent();
}

