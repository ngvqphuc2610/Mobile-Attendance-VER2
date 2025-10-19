class RoomEntity {
  final String id;
  final String code;
  final String name;
  final int? capacity;
  final String? location;

  RoomEntity({
    required this.id,
    required this.code,
    required this.name,
    this.capacity,
    this.location,
  });

  factory RoomEntity.fromJson(Map<String, dynamic> json) {
    return RoomEntity(
      id: json['id'],
      code: json['code'],
      name: json['name'],
      capacity: json['capacity'],
      location: json['location'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'capacity': capacity,
      'location': location,
    };
  }
}
