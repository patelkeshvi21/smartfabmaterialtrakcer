import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart' show Uuid;
import 'material_model.dart';
import 'user_model.dart';

class ConsumptionLogModel {
  final String id;
  final String materialId;
  final String materialName;
  final double quantity;
  final UnitType unitType;
  final String userId;
  final String userName;
  final DateTime consumptionDate;
  final double unitCost;
  final double totalCost;
  final String? productionOrderId;
  final bool isSynced;

  ConsumptionLogModel({
    String? id,
    required this.materialId,
    required this.materialName,
    required this.quantity,
    required this.unitType,
    required this.userId,
    required this.userName,
    DateTime? consumptionDate,
    required this.unitCost,
    double? totalCost,
    this.productionOrderId,
    this.isSynced = false,
  }) : 
    id = id ?? Uuid().v4(),
    consumptionDate = consumptionDate ?? DateTime.now(),
    totalCost = totalCost ?? (quantity * unitCost);

  factory ConsumptionLogModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ConsumptionLogModel(
      id: doc.id,
      materialId: data['materialId'] ?? '',
      materialName: data['materialName'] ?? '',
      quantity: (data['quantity'] ?? 0.0).toDouble(),
      unitType: UnitType.values.firstWhere(
        (e) => e.toString() == 'UnitType.${data['unitType'] ?? 'kg'}',
        orElse: () => UnitType.kg,
      ),
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      consumptionDate: (data['consumptionDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      unitCost: (data['unitCost'] ?? 0.0).toDouble(),
      totalCost: (data['totalCost'] ?? 0.0).toDouble(),
      productionOrderId: data['productionOrderId'],
      isSynced: data['isSynced'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'materialId': materialId,
      'materialName': materialName,
      'quantity': quantity,
      'unitType': unitType.toString().split('.').last,
      'userId': userId,
      'userName': userName,
      'consumptionDate': consumptionDate,
      'unitCost': unitCost,
      'totalCost': totalCost,
      'productionOrderId': productionOrderId,
      'isSynced': isSynced,
    };
  }
}
