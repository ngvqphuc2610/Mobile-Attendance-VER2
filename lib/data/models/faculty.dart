import 'package:equatable/equatable.dart';

class Faculty extends Equatable {
  final String id;
  final String code;
  final String name;
  final DateTime createdAt;

  const Faculty({
    required this.id,
    required this.code,
    required this.name,
    required this.createdAt,
  });

  factory Faculty.fromJson(Map<String, dynamic> json) {
    return Faculty(
      id: json['id'],
      code: json['code'],
      name: json['name'],
      createdAt: DateTime.parse(json['created_at']),
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
  List<Object?> get props => [id, code, name, createdAt];
}
