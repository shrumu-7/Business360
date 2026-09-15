class Product {
  Product({required this.id, required this.name, this.category = '', this.price = 0, this.cost = 0, this.stock = 0, this.unit = 'pcs'});
  final String id; String name; String category; double price; double cost; double stock; String unit;
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'category': category, 'price': price, 'cost': cost, 'stock': stock, 'unit': unit};
  factory Product.fromJson(Map<String, dynamic> json) => Product(id: '${json['id'] ?? DateTime.now().microsecondsSinceEpoch}', name: '${json['name'] ?? ''}', category: '${json['category'] ?? ''}', price: (json['price'] as num?)?.toDouble() ?? 0, cost: (json['cost'] as num?)?.toDouble() ?? 0, stock: (json['stock'] as num?)?.toDouble() ?? 0, unit: '${json['unit'] ?? 'pcs'}');
}

class Customer {
  Customer({required this.id, required this.name, this.phone = '', this.address = '', this.due = 0});
  final String id; String name; String phone; String address; double due;
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'phone': phone, 'address': address, 'due': due};
  factory Customer.fromJson(Map<String, dynamic> json) => Customer(id: '${json['id'] ?? DateTime.now().microsecondsSinceEpoch}', name: '${json['name'] ?? ''}', phone: '${json['phone'] ?? ''}', address: '${json['address'] ?? ''}', due: (json['due'] as num?)?.toDouble() ?? 0);
}

class Supplier {
  Supplier({required this.id, required this.name, this.phone = '', this.address = '', this.due = 0});
  final String id; String name; String phone; String address; double due;
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'phone': phone, 'address': address, 'due': due};
  factory Supplier.fromJson(Map<String, dynamic> j) => Supplier(id: '${j['id'] ?? DateTime.now().microsecondsSinceEpoch}', name: '${j['name'] ?? ''}', phone: '${j['phone'] ?? ''}', address: '${j['address'] ?? ''}', due: (j['due'] as num?)?.toDouble() ?? 0);
}

class Payment {
  Payment({required this.id, required this.date, required this.partyId, required this.amount, this.note = '', this.type = 'received'});
  final String id; final DateTime date; final String partyId; final double amount; final String note; final String type;
  Map<String, dynamic> toJson() => {'id': id, 'date': date.toIso8601String(), 'partyId': partyId, 'amount': amount, 'note': note, 'type': type};
  factory Payment.fromJson(Map<String, dynamic> j) => Payment(id: '${j['id'] ?? ''}', date: DateTime.tryParse('${j['date'] ?? ''}') ?? DateTime.now(), partyId: '${j['partyId'] ?? ''}', amount: (j['amount'] as num?)?.toDouble() ?? 0, note: '${j['note'] ?? ''}', type: '${j['type'] ?? 'received'}');
}

class ReturnRecord {
  ReturnRecord({required this.id, required this.date, required this.saleId, required this.productId, required this.quantity, required this.amount, this.note = ''});
  final String id; final DateTime date; final String saleId; final String productId; final double quantity; final double amount; final String note;
  Map<String, dynamic> toJson() => {'id': id, 'date': date.toIso8601String(), 'saleId': saleId, 'productId': productId, 'quantity': quantity, 'amount': amount, 'note': note};
  factory ReturnRecord.fromJson(Map<String, dynamic> j) => ReturnRecord(id: '${j['id'] ?? ''}', date: DateTime.tryParse('${j['date'] ?? ''}') ?? DateTime.now(), saleId: '${j['saleId'] ?? ''}', productId: '${j['productId'] ?? ''}', quantity: (j['quantity'] as num?)?.toDouble() ?? 0, amount: (j['amount'] as num?)?.toDouble() ?? 0, note: '${j['note'] ?? ''}');
}

class StockMove {
  StockMove({required this.id, required this.date, required this.productId, required this.quantity, required this.type, this.note = ''});
  final String id; final DateTime date; final String productId; final double quantity; final String type; final String note;
  Map<String, dynamic> toJson() => {'id': id, 'date': date.toIso8601String(), 'productId': productId, 'quantity': quantity, 'type': type, 'note': note};
  factory StockMove.fromJson(Map<String, dynamic> j) => StockMove(id: '${j['id'] ?? ''}', date: DateTime.tryParse('${j['date'] ?? ''}') ?? DateTime.now(), productId: '${j['productId'] ?? ''}', quantity: (j['quantity'] as num?)?.toDouble() ?? 0, type: '${j['type'] ?? 'adjustment'}', note: '${j['note'] ?? ''}');
}

class SaleItem {
  SaleItem({required this.productId, required this.name, required this.quantity, required this.price, this.cost = 0});
  final String productId; final String name; final double quantity; final double price; final double cost;
  double get subtotal => quantity * price; double get profit => quantity * (price - cost);
  Map<String, dynamic> toJson() => {'productId': productId, 'name': name, 'quantity': quantity, 'price': price, 'cost': cost};
  factory SaleItem.fromJson(Map<String, dynamic> json) => SaleItem(productId: '${json['productId'] ?? ''}', name: '${json['name'] ?? ''}', quantity: (json['quantity'] as num?)?.toDouble() ?? 0, price: (json['price'] as num?)?.toDouble() ?? 0, cost: (json['cost'] as num?)?.toDouble() ?? 0);
}

class Sale {
  Sale({required this.id, required this.date, required this.total, this.paid = 0, this.customerId = '', this.items = const []});
  final String id; final DateTime date; final double total; final double paid; final String customerId; final List<SaleItem> items;
  double get due => total - paid; double get profit => items.fold(0, (sum, item) => sum + item.profit);
  Map<String, dynamic> toJson() => {'id': id, 'date': date.toIso8601String(), 'total': total, 'paid': paid, 'customerId': customerId, 'items': items.map((e) => e.toJson()).toList()};
  factory Sale.fromJson(Map<String, dynamic> json) => Sale(id: '${json['id'] ?? ''}', date: DateTime.tryParse('${json['date'] ?? ''}') ?? DateTime.now(), total: (json['total'] as num?)?.toDouble() ?? 0, paid: (json['paid'] as num?)?.toDouble() ?? 0, customerId: '${json['customerId'] ?? ''}', items: ((json['items'] as List?) ?? []).map((e) => SaleItem.fromJson(Map<String, dynamic>.from(e))).toList());
}

class BusinessExpense {
  BusinessExpense({required this.id, required this.date, required this.title, required this.amount, this.note = ''});
  final String id; final DateTime date; final double amount; final String title; final String note;
  Map<String,dynamic> toJson()=>{'id':id,'date':date.toIso8601String(),'title':title,'amount':amount,'note':note};
  factory BusinessExpense.fromJson(Map<String,dynamic> j)=>BusinessExpense(id:'${j['id']}',date:DateTime.tryParse('${j['date']}')??DateTime.now(),title:'${j['title']??''}',amount:(j['amount'] as num?)?.toDouble()??0,note:'${j['note']??''}');
}

class Purchase {
  Purchase({required this.id, required this.date, required this.supplier, required this.amount, this.paid = 0, this.note = ''});
  final String id; final DateTime date; final double amount; final double paid; final String supplier; final String note;
  double get due=>amount-paid;
  Map<String,dynamic> toJson()=>{'id':id,'date':date.toIso8601String(),'supplier':supplier,'amount':amount,'paid':paid,'note':note};
  factory Purchase.fromJson(Map<String,dynamic> j)=>Purchase(id:'${j['id']}',date:DateTime.tryParse('${j['date']}')??DateTime.now(),supplier:'${j['supplier']??''}',amount:(j['amount'] as num?)?.toDouble()??0,paid:(j['paid'] as num?)?.toDouble()??0,note:'${j['note']??''}');
}
