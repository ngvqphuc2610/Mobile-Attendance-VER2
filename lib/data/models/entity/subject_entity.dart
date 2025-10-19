class SubjectEntity {
  final String id;
  final String code;
  final String name;
  final int? credits;

  SubjectEntity({
    required this.id,
    required this.code,
    required this.name,
    this.credits,
  });

  factory SubjectEntity.fromJson(Map<String, dynamic> json) {
    return SubjectEntity(
      id: json['id'],
      code: json['code'],
      name: json['name'],
      credits: json['credits'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'credits': credits,
    };
  }
}
