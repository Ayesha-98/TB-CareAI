class PlanItemModel {
  final String name;
  final String quantity;

  const PlanItemModel({required this.name, required this.quantity});

  factory PlanItemModel.fromMap(Map<String, dynamic> map) {
    return PlanItemModel(
      name: map['name'] ?? '',
      quantity: map['quantity'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'quantity': quantity};
  }

  PlanItemModel copyWith({String? name, String? quantity}) {
    return PlanItemModel(
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
    );
  }

  @override
  String toString() => 'PlanItemModel(name: $name, quantity: $quantity)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlanItemModel &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          quantity == other.quantity;

  @override
  int get hashCode => name.hashCode ^ quantity.hashCode;
}
