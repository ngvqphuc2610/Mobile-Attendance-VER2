import 'package:equatable/equatable.dart';

class ClassModel extends Equatable {
  final String id;
  final String code;
  final String name;
  final String? facultyId;
  final DateTime createdAt;

  const ClassModel({
    required this.id,
    required this.code,
    required this.name,
    this.facultyId,
    required this.createdAt,
  });

  factory ClassModel.fromJson(Map<String, dynamic> json) {
    return ClassModel(
      id: json['id'],
      code: json['code'],
      name: json['name'],
      facultyId: json['faculty_id'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'faculty_id': facultyId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, code, name, facultyId, createdAt];
}
