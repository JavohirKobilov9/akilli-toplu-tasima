
class Stop {
  final int id;
  final String code;
  final String name;
  final String district;

  final double? latitude;
  final double? longitude;
  final int? stopOrder;

  Stop({
    required this.id,
    required this.code,
    required this.name,
    required this.district,
    this.latitude,
    this.longitude,
    this.stopOrder,
  });

  factory Stop.fromJson(Map<String, dynamic> json) {
    final pivot = json['pivot'];

    return Stop(
      id: int.tryParse(json['id'].toString()) ?? 0,
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      district: json['district']?.toString() ?? '',

      latitude: double.tryParse(
        json['latitude']?.toString() ?? '',
      ),

      longitude: double.tryParse(
        json['longitude']?.toString() ?? '',
      ),

      stopOrder: pivot is Map
          ? int.tryParse(
              pivot['stop_order']?.toString() ?? '',
            )
          : null,
    );
  }

  @override
  String toString() => name;
}
