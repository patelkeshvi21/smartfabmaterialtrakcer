class CostCalculationService {
  // Raw Material Cost Calculation
  static double calculateRawMaterialCost(double unitCost, double quantity) {
    return unitCost * quantity;
  }

  // Manufacturing Cost Calculation
  static double calculateManufacturingCost({
    required double rawMaterialCost,
    double laborCost = 0.0,
    double energyCost = 0.0,
    double overheadCost = 0.0,
  }) {
    return rawMaterialCost + laborCost + energyCost + overheadCost;
  }

  // Final Product Price Calculation
  static ProductPriceDetails calculateProductPrice({
    required double manufacturingCost,
    double desiredMarginPercentage = 0.2, // Default 20% margin
  }) {
    // Calculate selling price with desired margin
    final sellingPrice = manufacturingCost * (1 + desiredMarginPercentage);
    
    // Calculate profit
    final profit = sellingPrice - manufacturingCost;
    final profitMargin = (profit / sellingPrice) * 100;

    return ProductPriceDetails(
      manufacturingCost: manufacturingCost,
      sellingPrice: sellingPrice,
      profitMargin: profitMargin,
    );
  }
}

// Detailed breakdown of product pricing
class ProductPriceDetails {
  final double manufacturingCost;
  final double sellingPrice;
  final double profitMargin;

  ProductPriceDetails({
    required this.manufacturingCost,
    required this.sellingPrice,
    required this.profitMargin,
  });

  Map<String, dynamic> toJson() {
    return {
      'manufacturingCost': manufacturingCost,
      'sellingPrice': sellingPrice,
      'profitMargin': profitMargin,
    };
  }
}
