class CohortModel {
  final String id;
  final int year;
  final String? name;

  CohortModel({
    required this.id,
    required this.year,
    this.name,
  });

  factory CohortModel.fromJson(Map<String, dynamic> json) {
    return CohortModel(
      id: json['id'] ?? '',
      year: json['year'] != null ? (json['year'] as num).toInt() : 0,
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'year': year,
      'name': name,
    };
  }
}
