import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/consumption_log_model.dart';
import '../models/material_model.dart';
import 'cost_calculation_service.dart';

class ReportingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Generate comprehensive cost report
  Future<List<CostReportEntry>> generateCostReport({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    startDate ??= DateTime.now().subtract(const Duration(days: 30));
    endDate ??= DateTime.now();

    QuerySnapshot logsSnapshot = await _firestore
        .collection('consumption_logs')
        .where('consumptionDate', isGreaterThanOrEqualTo: startDate)
        .where('consumptionDate', isLessThanOrEqualTo: endDate)
        .get();

    // Group logs by material
    Map<String, List<ConsumptionLogModel>> materialLogs = {};
    for (var doc in logsSnapshot.docs) {
      ConsumptionLogModel log = ConsumptionLogModel.fromFirestore(doc);
      materialLogs.putIfAbsent(log.materialId, () => []).add(log);
    }

    // Calculate cost details for each material
    List<CostReportEntry> reportEntries = [];
    for (var entry in materialLogs.entries) {
      // Fetch material details
      DocumentSnapshot materialDoc = await _firestore
          .collection('materials')
          .doc(entry.key)
          .get();
      
      MaterialModel material = MaterialModel.fromFirestore(materialDoc);

      // Aggregate consumption details
      double totalQuantity = entry.value.fold(0, (sum, log) => sum + log.quantity);
      double totalCost = entry.value.fold(0, (sum, log) => sum + log.totalCost);

      // Calculate product pricing
      ProductPriceDetails priceDetails = CostCalculationService.calculateProductPrice(
        manufacturingCost: totalCost,
      );

      reportEntries.add(CostReportEntry(
        materialName: material.name,
        totalQuantityUsed: totalQuantity,
        unitType: material.unitType,
        unitCost: material.unitCost,
        totalMaterialCost: totalCost,
        suggestedSellingPrice: priceDetails.sellingPrice,
        profitMargin: priceDetails.profitMargin,
      ));
    }

    return reportEntries;
  }

  // Export report to PDF
  Future<void> exportCostReportToPDF(List<CostReportEntry> reportEntries) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        header: (context) => pw.Text(
          'SmartFab Material Cost Report',
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        build: (context) => [
          pw.Table.fromTextArray(
            context: context,
            data: [
              // Table headers
              ['Material', 'Qty Used', 'Unit', 'Unit Cost', 'Total Cost', 'Selling Price', 'Profit Margin'],
              // Table rows
              ...reportEntries.map((entry) => [
                entry.materialName,
                entry.totalQuantityUsed.toStringAsFixed(2),
                entry.unitType.toString().split('.').last,
                '\$${entry.unitCost.toStringAsFixed(2)}',
                '\$${entry.totalMaterialCost.toStringAsFixed(2)}',
                '\$${entry.suggestedSellingPrice.toStringAsFixed(2)}',
                '${entry.profitMargin.toStringAsFixed(2)}%',
              ]),
            ],
          ),
        ],
      ),
    );

    // Print or save PDF
    await Printing.sharePdf(bytes: await pdf.save(), filename: 'cost_report.pdf');
  }
}

// Detailed cost report entry
class CostReportEntry {
  final String materialName;
  final double totalQuantityUsed;
  final UnitType unitType;
  final double unitCost;
  final double totalMaterialCost;
  final double suggestedSellingPrice;
  final double profitMargin;

  CostReportEntry({
    required this.materialName,
    required this.totalQuantityUsed,
    required this.unitType,
    required this.unitCost,
    required this.totalMaterialCost,
    required this.suggestedSellingPrice,
    required this.profitMargin,
  });
}
