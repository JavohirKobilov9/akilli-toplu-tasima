import 'dart:convert';

/// GeoJSON uses longitude first. Reject invalid data before drawing or saving.
class RouteGeometry {
  static Map<String, dynamic> parse(Object? value) {
    final data = value is String ? jsonDecode(value) : value;
    if (data is! Map || data['type'] != 'LineString') {
      throw const FormatException('Güzergâh türü LineString olmalıdır.');
    }
    final coordinates = data['coordinates'];
    if (coordinates is! List ||
        coordinates.length < 2 ||
        coordinates.length > 5000) {
      throw const FormatException('2–5000 koordinat gereklidir.');
    }
    final points = <List<double>>[];
    for (final point in coordinates) {
      if (point is! List ||
          point.length != 2 ||
          point[0] is! num ||
          point[1] is! num) {
        throw const FormatException(
          'Her nokta [boylam, enlem] biçiminde iki sayı olmalıdır.',
        );
      }
      final lon = (point[0] as num).toDouble();
      final lat = (point[1] as num).toDouble();
      if (!lon.isFinite || !lat.isFinite || lon.abs() > 180 || lat.abs() > 90) {
        throw const FormatException(
          'Boylam ±180, enlem ±90 aralığında olmalıdır.',
        );
      }
      points.add([lon, lat]);
    }
    return {'type': 'LineString', 'coordinates': points};
  }
}
