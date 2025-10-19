import 'package:equatable/equatable.dart';

class FaceEmbedding extends Equatable {
  final String userId;
  final List<List<double>> vectors;
  final int samplesCount;
  final DateTime updatedAt;

  const FaceEmbedding({
    required this.userId,
    required this.vectors,
    required this.samplesCount,
    required this.updatedAt,
  });

  factory FaceEmbedding.fromJson(Map<String, dynamic> json) {
    final vectorsJson = json['vectors'] as List? ?? const [];
    final vectors = vectorsJson.map((vector) {
      final vectorList = vector as List? ?? const [];
      return vectorList.map((v) => (v as num).toDouble()).toList();
    }).toList();

    return FaceEmbedding(
      userId: json['user_id'] ?? '',
      vectors: List<List<double>>.from(vectors),
      samplesCount: json['samples_count'] ?? vectors.length,
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'vectors': vectors,
      'samples_count': samplesCount,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [userId, vectors, samplesCount, updatedAt];
}
