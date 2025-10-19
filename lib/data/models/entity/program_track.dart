import 'package:equatable/equatable.dart';

class ProgramTrack extends Equatable {
  final String id;
  final String code;
  final String name;
  final String? description;

  const ProgramTrack({
    required this.id,
    required this.code,
    required this.name,
    this.description,
  });

  factory ProgramTrack.fromJson(Map<String, dynamic> json) {
    return ProgramTrack(
      id: json['id'] ?? '',
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'description': description,
    };
  }

  @override
  List<Object?> get props => [id, code, name, description];
}
