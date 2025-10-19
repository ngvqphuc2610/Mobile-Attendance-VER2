import 'package:equatable/equatable.dart';

class FacultyEntity extends Equatable {
  final String id;
  final String code;
  final String name;
  final DateTime createdAt;

  const FacultyEntity({
    required this.id,
    required this.code,
    required this.name,
    required this.createdAt,
  });

  factory FacultyEntity.fromJson(Map<String, dynamic> json) {
    return FacultyEntity(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object> get props => [id, code, name, createdAt];
}