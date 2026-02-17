enum PendingMutationType {
  checkIn('checkin'),
  undoCheckIn('undo_checkin');

  const PendingMutationType(this.value);

  final String value;

  static PendingMutationType fromValue(String value) {
    return PendingMutationType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => PendingMutationType.checkIn,
    );
  }
}

class PendingMutation {
  const PendingMutation({
    required this.id,
    required this.type,
    required this.payload,
    required this.createdAt,
  });

  final String id;
  final PendingMutationType type;
  final Map<String, dynamic> payload;
  final DateTime createdAt;

  factory PendingMutation.fromJson(Map<String, dynamic> json) {
    return PendingMutation(
      id: json['id'] as String,
      type: PendingMutationType.fromValue(json['type'] as String),
      payload: Map<String, dynamic>.from(
        json['payload'] as Map<dynamic, dynamic>,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.value,
      'payload': payload,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
