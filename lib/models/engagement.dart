class Engagement {
  final String id;
  final String serviceName;
  final String itemName;
  final double amount;
  final int dayOfMonth;
  final String periodicity;
  final String? reason;
  final DateTime createdAt;
  final DateTime updatedAt;

  Engagement({
    required this.id,
    required this.serviceName,
    required this.itemName,
    required this.amount,
    required this.dayOfMonth,
    required this.periodicity,
    this.reason,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Engagement.fromJson(Map<String, dynamic> json) {
    return Engagement(
      id: json['id'],
      serviceName: json['service_name'],
      itemName: json['item_name'],
      amount: double.parse(json['amount'].toString()),
      dayOfMonth: json['day_of_month'],
      periodicity: json['periodicity'],
      reason: json['reason'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'service_name': serviceName,
      'item_name': itemName,
      'amount': amount,
      'day_of_month': dayOfMonth,
      'periodicity': periodicity,
      'reason': reason,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}