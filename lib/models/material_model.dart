import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart' show Uuid;

enum UnitType {
  kg,
  liter,
  piece,
  meter
}

class MaterialModel {
  final String id;
  final String name;
  final String description;
  final double unitCost;
  final UnitType unitType;
  double currentStock;
  final double minStockThreshold;
  final DateTime createdAt;
  final String barcode;

  MaterialModel({
    String? id,
    required this.name,
    this.description = '',
    required this.unitCost,
    required this.unitType,
    this.currentStock = 0.0,
    this.minStockThreshold = 10.0,
    DateTime? createdAt,
    String? barcode,
  }) : 
    id = id ?? Uuid().v4(),
    createdAt = createdAt ?? DateTime.now(),
    barcode = barcode ?? Uuid().v4();

  factory MaterialModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return MaterialModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      unitCost: (data['unitCost'] ?? 0.0).toDouble(),
      unitType: UnitType.values.firstWhere(
        (e) => e.toString() == 'UnitType.${data['unitType'] ?? 'kg'}',
        orElse: () => UnitType.kg,
      ),
      currentStock: (data['currentStock'] ?? 0.0).toDouble(),
      minStockThreshold: (data['minStockThreshold'] ?? 10.0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      barcode: data['barcode'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'unitCost': unitCost,
      'unitType': unitType.toString().split('.').last,
      'currentStock': currentStock,
      'minStockThreshold': minStockThreshold,
      'createdAt': createdAt,
      'barcode': barcode,
    };
  }

  bool get isLowStock => currentStock <= minStockThreshold;

  void updateStock(double quantity, {bool isAddition = true}) {
    currentStock += isAddition ? quantity : -quantity;
  }
}
