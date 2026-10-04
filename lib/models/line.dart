class Line {
  final int id;
  final String code;
  final String name;
  final String transportType;

  Line({
    required this.id,
    required this.code,
    required this.name,
    required this.transportType,
  });

  factory Line.fromJson(Map<String, dynamic> json) {
    return Line(
      id: json['id'] ?? 0,
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      transportType: json['transport_type'] ?? '',
    );
  }

  @override
  String toString() => '$code - $name';
}