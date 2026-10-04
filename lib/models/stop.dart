class Stop {
  final int id;
  final String code;
  final String name;
  final String district;

  Stop({
    required this.id,
    required this.code,
    required this.name,
    required this.district,
  });

  factory Stop.fromJson(Map<String, dynamic> json) {
    return Stop(
      id: json['id'] ?? 0,
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      district: json['district'] ?? '',
    );
  }

  @override
  String toString() => name;
}