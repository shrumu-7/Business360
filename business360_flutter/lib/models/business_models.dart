class Product {
  Product({required this.id, required this.name, this.category = '', this.price = 0, this.cost = 0, this.stock = 0, this.unit = 'pcs'});
  final String id;
  String name;
  String category;
  double price;
  double cost;
  double stock;
  String unit;

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'category': category, 'price': price,
    'cost': cost, 'stock': stock, 'unit': unit,
  };

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: '${json['id'] ?? DateTime.now().microsecondsSinceEpoch}',
    name: '${json['name'] ?? ''}', category: '${json['category'] ?? ''}',
    price: (json['price'] as num?)?.toDouble() ?? 0,
    cost: (json['cost'] as num?)?.toDouble() ?? 0,
    stock: (json['stock'] as num?)?.toDouble() ?? 0,
    unit: '${json['unit'] ?? 'pcs'}',
  );
}

class Customer {
  Customer({required this.id, required this.name, this.phone = '', this.address = '', this.due = 0});
  final String id;
  String name;
  String phone;
  String address;
  double due;

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'phone': phone, 'address': address, 'due': due};
  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
    id: '${json['id'] ?? DateTime.now().microsecondsSinceEpoch}', name: '${json['name'] ?? ''}',
    phone: '${json['phone'] ?? ''}', address: '${json['address'] ?? ''}',
    due: (json['due'] as num?)?.toDouble() ?? 0,
  );
}

class Sale {
  Sale({required this.id, required this.date, required this.total, this.paid = 0, this.customerId = ''});
  final String id;
  final DateTime date;
  final double total;
  final double paid;
  final String customerId;
  double get due => total - paid;
  Map<String, dynamic> toJson() => {'id': id, 'date': date.toIso8601String(), 'total': total, 'paid': paid, 'customerId': customerId};
  factory Sale.fromJson(Map<String, dynamic> json) => Sale(
    id: '${json['id'] ?? ''}', date: DateTime.tryParse('${json['date'] ?? ''}') ?? DateTime.now(),
    total: (json['total'] as num?)?.toDouble() ?? 0, paid: (json['paid'] as num?)?.toDouble() ?? 0,
    customerId: '${json['customerId'] ?? ''}',
  );
}
