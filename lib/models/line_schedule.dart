class LineSchedule {
  final int id;
  final int lineId;
  final String servicePeriod;
  final String? direction;
  final String departureTime;
  final String? note;

  LineSchedule({
    required this.id,
    required this.lineId,
    required this.servicePeriod,
    required this.direction,
    required this.departureTime,
    required this.note,
  });

  factory LineSchedule.fromJson(
    Map<String, dynamic> json,
  ) {
    return LineSchedule(
      id: json['id'] ?? 0,
      lineId: json['line_id'] ?? 0,
      servicePeriod: json['service_period'] ?? '',
      direction: json['direction'],
      departureTime: json['departure_time'] ?? '',
      note: json['note'],
    );
  }
}