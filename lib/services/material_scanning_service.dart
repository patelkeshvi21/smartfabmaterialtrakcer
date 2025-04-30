import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/material_model.dart';

class MaterialScanningService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Scan and fetch material details by barcode
  Future<MaterialModel?> scanAndFetchMaterial(Barcode barcode) async {
    try {
      // Search for material with matching barcode
      QuerySnapshot materialQuery = await _firestore
          .collection('materials')
          .where('barcode', isEqualTo: barcode.rawValue)
          .limit(1)
          .get();

      if (materialQuery.docs.isNotEmpty) {
        // Return the first matching material
        return MaterialModel.fromFirestore(materialQuery.docs.first);
      }

      return null;
    } catch (e) {
      print('Material scan error: $e');
      return null;
    }
  }

  // Add new material with barcode
  Future<MaterialModel> addNewMaterial({
    required String name,
    required double unitCost,
    required UnitType unitType,
    String? description,
    double initialStock = 0.0,
    double minStockThreshold = 10.0,
  }) async {
    try {
      // Generate a new material with a unique barcode
      MaterialModel newMaterial = MaterialModel(
        name: name,
        description: description ?? '',
        unitCost: unitCost,
        unitType: unitType,
        currentStock: initialStock,
        minStockThreshold: minStockThreshold,
      );

      // Save to Firestore
      DocumentReference docRef = await _firestore
          .collection('materials')
          .add(newMaterial.toFirestore());

      // Update the material with its Firestore ID
      newMaterial = MaterialModel(
        id: docRef.id,
        name: name,
        description: description ?? '',
        unitCost: unitCost,
        unitType: unitType,
        currentStock: initialStock,
        minStockThreshold: minStockThreshold,
        barcode: newMaterial.barcode,
      );

      return newMaterial;
    } catch (e) {
      print('Add material error: $e');
      rethrow;
    }
  }

  // Update material stock
  Future<void> updateMaterialStock(
    String materialId, 
    double quantity, 
    {bool isAddition = true}
  ) async {
    try {
      await _firestore.runTransaction((transaction) async {
        DocumentReference materialRef = _firestore
            .collection('materials')
            .doc(materialId);

        DocumentSnapshot snapshot = await transaction.get(materialRef);

        if (!snapshot.exists) {
          throw Exception('Material does not exist');
        }

        MaterialModel material = MaterialModel.fromFirestore(snapshot);
        material.updateStock(quantity, isAddition: isAddition);

        transaction.update(materialRef, material.toFirestore());
      });
    } catch (e) {
      print('Update stock error: $e');
      rethrow;
    }
  }

  // Search materials
  Future<List<MaterialModel>> searchMaterials(String query) async {
    try {
      QuerySnapshot materialsQuery = await _firestore
          .collection('materials')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThan: query + 'z')
          .get();

      return materialsQuery.docs
          .map((doc) => MaterialModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Search materials error: $e');
      return [];
    }
  }
}
