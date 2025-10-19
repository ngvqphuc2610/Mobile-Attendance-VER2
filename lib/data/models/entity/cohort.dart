import 'package:equatable/equatable.dart';

class Cohort extends Equatable {
  final String id;
  final int year;
  final String? name;

  const Cohort({
    required this.id,
    required this.year,
    this.name,
  });

  factory Cohort.fromJson(Map<String, dynamic> json) {
    return Cohort(
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

  @override
  List<Object?> get props => [id, year, name];
}
