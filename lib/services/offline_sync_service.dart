import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';
import '../models/consumption_log_model.dart';
import '../models/material_model.dart';

class OfflineSyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Connectivity _connectivity = Connectivity();

  // Save consumption log locally
  Future<void> saveConsumptionLogLocally(ConsumptionLogModel log) async {
    var box = await Hive.openBox<ConsumptionLogModel>('consumption_logs');
    await box.add(log);
  }

  // Sync local logs to Firestore
  Future<void> syncConsumptionLogs() async {
    var connectivityResult = await _connectivity.checkConnectivity();
    if (connectivityResult != ConnectivityResult.none) {
      var box = await Hive.openBox<ConsumptionLogModel>('consumption_logs');
      
      for (var i = 0; i < box.length; i++) {
        var log = box.getAt(i);
        if (log != null && !log.isSynced) {
          try {
            // Update material stock in Firestore
            await _updateMaterialStock(log);

            // Save log to Firestore
            await _firestore
                .collection('consumption_logs')
                .add(log.toFirestore());

            // Mark as synced
            log.isSynced = true;
            await box.putAt(i, log);
          } catch (e) {
            print('Sync error: $e');
          }
        }
      }
    }
  }

  // Update material stock when consumption log is created
  Future<void> _updateMaterialStock(ConsumptionLogModel log) async {
    var materialRef = _firestore.collection('materials').doc(log.materialId);
    
    await _firestore.runTransaction((transaction) async {
      DocumentSnapshot materialSnapshot = await transaction.get(materialRef);
      
      if (!materialSnapshot.exists) {
        throw Exception("Material does not exist!");
      }

      MaterialModel material = MaterialModel.fromFirestore(materialSnapshot);
      material.updateStock(log.quantity, isAddition: false);

      transaction.update(materialRef, material.toFirestore());
    });
  }

  // Check for low stock and send notifications
  Future<List<MaterialModel>> checkLowStockMaterials() async {
    QuerySnapshot materialsSnapshot = await _firestore
        .collection('materials')
        .where('currentStock', isLessThanOrEqualTo: 'minStockThreshold')
        .get();

    return materialsSnapshot.docs
        .map((doc) => MaterialModel.fromFirestore(doc))
        .toList();
  }
}
