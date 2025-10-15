class FacultyModel {
  final String id;
  final String code;
  final String name;
  final DateTime? createdAt;

  FacultyModel({
    required this.id,
    required this.code,
    required this.name,
    this.createdAt,
  });

  factory FacultyModel.fromJson(Map<String, dynamic> json) {
    return FacultyModel(
      id: json['id'] ?? '',
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      createdAt: json['created_at'] != null 
        ? DateTime.parse(json['created_at']) 
        : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}