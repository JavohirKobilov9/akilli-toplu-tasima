class Line {
  final Object? routeGeometry;
  final int id;
  final String code;
  final String name;
  final String transportType;

  Line({
    this.routeGeometry,
    required this.id,
    required this.code,
    required this.name,
    required this.transportType,
  });

  factory Line.fromJson(Map<String, dynamic> json) {
    return Line(
      routeGeometry: json['route_geometry'],
      id: json['id'] ?? 0,
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      transportType: json['transport_type'] ?? '',
    );
  }

  @override
  String toString() => '$code - $name';
}
