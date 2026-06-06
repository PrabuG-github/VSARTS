/// Represents a single item inside an invoice.
class InvoiceItem {
  String description;
  int quantity;
  double length;
  double breadth;
  double rate;

  InvoiceItem({
    required this.description,
    required this.quantity,
    required this.length,
    required this.breadth,
    required this.rate,
  });

  /// Computes Area in Sq.Ft = Length * Breadth.
  double get area => length * breadth;

  /// Computes Total Price = Quantity * Area * Rate.
  double get price => quantity * area * rate;

  /// Creates a copy of the item.
  InvoiceItem copyWith({
    String? description,
    int? quantity,
    double? length,
    double? breadth,
    double? rate,
  }) {
    return InvoiceItem(
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      length: length ?? this.length,
      breadth: breadth ?? this.breadth,
      rate: rate ?? this.rate,
    );
  }
}

/// Represents the global invoice data model.
class InvoiceData {
  final String billNo;
  final DateTime date;
  final String clientName;
  final String phoneNumber;
  final String address;
  final List<InvoiceItem> items;
  final bool locationOutsideParrys;
  final double extraCharges;
  final DateTime submittedAt;

  InvoiceData({
    required this.billNo,
    required this.date,
    required this.clientName,
    required this.phoneNumber,
    required this.address,
    required this.items,
    required this.locationOutsideParrys,
    required this.extraCharges,
    required this.submittedAt,
  });

  /// Calculates the Sub Total = Sum of all item prices.
  double get subTotal => items.fold(0.0, (sum, item) => sum + item.price);

  /// Calculates the Grand Total = Sub Total + Extra Charges.
  double get grandTotal => subTotal + (locationOutsideParrys ? extraCharges : 0.0);
}
