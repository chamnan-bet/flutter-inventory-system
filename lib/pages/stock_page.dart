// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:shared_preferences/shared_preferences.dart';

class StockPage extends StatefulWidget {
  const StockPage({super.key});

  @override
  State<StockPage> createState() => _StockPageState();
}

class _StockPageState extends State<StockPage> {
  // --- UI State ---
  bool isStockIn = true;
  String? _selectedSku;
  final _qtyCtrl = TextEditingController(text: '1');
  final _noteCtrl = TextEditingController();

  // --- Data State ---
  late List<Product> _products; // catalog (static, but stock will update)
  Map<String, int> _stockMap = {}; // sku -> current stock (persisted)
  List<StockTxn> _txns = []; // persisted transactions (latest first)

  // --- Storage Keys ---
  static const _kTxns = 'stock_transactions';
  static const _kStockMap = 'product_stock_map';

  @override
  void initState() {
    super.initState();
    _products = _initialProducts(); // seed catalog
    _loadAll();
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  // ====== Storage ======
  Future<void> _loadAll() async {
    final sp = await SharedPreferences.getInstance();

    // Load stock map (or seed with initial product stock)
    final stockStr = sp.getString(_kStockMap);
    if (stockStr != null && stockStr.isNotEmpty) {
      final decoded = jsonDecode(stockStr) as Map<String, dynamic>;
      _stockMap = decoded.map((k, v) => MapEntry(k, (v as num).toInt()));
    } else {
      _stockMap = {for (final p in _products) p.sku: p.currentStock};
      await sp.setString(_kStockMap, jsonEncode(_stockMap));
    }

    // Load transactions
    final txStr = sp.getString(_kTxns);
    if (txStr != null && txStr.isNotEmpty) {
      final list = (jsonDecode(txStr) as List)
          .map((e) => StockTxn.fromJson(e as Map<String, dynamic>))
          .toList();
      _txns = list..sort((a, b) => b.date.compareTo(a.date));
    }

    setState(() {
      // apply stockMap onto catalog so UI shows current stock
      _products = _products
          .map(
            (p) => p.copyWith(currentStock: _stockMap[p.sku] ?? p.currentStock),
          )
          .toList();
    });
  }

  Future<void> _persist() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(
      _kTxns,
      jsonEncode(_txns.map((e) => e.toJson()).toList()),
    );
    await sp.setString(_kStockMap, jsonEncode(_stockMap));
  }

  Future<void> _record() async {
    // validate product
    final p = _products.firstWhere(
      (e) => e.sku == _selectedSku,
      orElse: () => const Product.empty(),
    );
    if (p.isEmpty) {
      _snack('Please select a product');
      return;
    }
    // validate quantity
    final qty = int.tryParse(_qtyCtrl.text.trim());
    if (qty == null || qty <= 0) {
      _snack('Quantity must be a positive number');
      return;
    }

    // stock check for Stock Out
    final current = _stockMap[p.sku] ?? p.currentStock;
    if (!isStockIn && qty > current) {
      _snack('Not enough stock. Available: $current');
      return;
    }

    // Mutate stock
    final newStock = isStockIn ? current + qty : current - qty;
    _stockMap[p.sku] = newStock;

    // Create transaction (store date/time)
    final txn = StockTxn(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sku: p.sku,
      productName: p.name,
      qty: qty,
      isIn: isStockIn,
      note: _noteCtrl.text.trim(),
      date: DateTime.now(),
    );

    // Update memory lists
    _txns.insert(0, txn); // latest first
    _products = _products
        .map((it) => it.sku == p.sku ? it.copyWith(currentStock: newStock) : it)
        .toList();

    // Persist to local storage
    await _persist();

    // Reset form
    setState(() {
      _qtyCtrl.text = '1';
      _noteCtrl.clear();
    });
    _snack('${isStockIn ? "Stock In" : "Stock Out"} recorded for ${p.name}');
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ====== UI ======
  @override
  Widget build(BuildContext context) {
    // const primary = Color(0xFF3B47FF);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.6,
        surfaceTintColor: Colors.white,
        titleSpacing: 16,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/adminMenu');
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'InventoryPro',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Admin User',
              style: TextStyle(color: Color(0xFF7A7A7A), fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
          const SizedBox(width: 8),
        ],
      ),

      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          const Text(
            'Stock Management',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          const Text(
            'Record stock in/out transactions',
            style: TextStyle(color: Color(0xFF7A7A7A), fontSize: 13),
          ),
          const SizedBox(height: 12),

          // --- New Transaction Card ---
          Container(
            padding: const EdgeInsets.all(14),
            decoration: _panelDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Toggle In/Out
                Row(
                  children: [
                    Expanded(
                      child: _toggleButton(
                        selected: isStockIn,
                        color: const Color(0xFF10B981), // green
                        icon: Icons.login_rounded,
                        text: 'Stock In',
                        onTap: () => setState(() => isStockIn = true),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _toggleButton(
                        selected: !isStockIn,
                        color: const Color.fromARGB(255, 226, 32, 6),
                        icon: Icons.logout_rounded,
                        text: 'Stock Out',
                        onTap: () => setState(() => isStockIn = false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Product
                const _Label('Select Product *'),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _selectedSku,
                  items: _products
                      .map(
                        (p) => DropdownMenuItem(
                          value: p.sku,
                          child: Text(
                            '${p.name}  (In stock: ${_stockMap[p.sku] ?? p.currentStock})',
                          ),
                        ),
                      )
                      .toList(),
                  decoration: _inputDeco('Choose product'),
                  onChanged: (v) => setState(() => _selectedSku = v),
                ),
                const SizedBox(height: 12),

                // Quantity
                const _Label('Quantity *'),
                const SizedBox(height: 6),
                TextField(
                  controller: _qtyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: _inputDeco('1'),
                ),
                const SizedBox(height: 12),

                // Notes
                const _Label('Notes'),
                const SizedBox(height: 6),
                TextField(
                  controller: _noteCtrl,
                  decoration: _inputDeco('Optional transaction notes...'),
                ),

                const SizedBox(height: 14),

                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isStockIn
                          ? const Color(0xFF10B981)
                          : const Color.fromARGB(255, 226, 32, 6),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _record,
                    child: Text(
                      isStockIn ? 'Record Stock In' : 'Record Stock Out',
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // --- Transaction History ---
          Container(
            padding: const EdgeInsets.all(14),
            decoration: _panelDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Expanded(
                      child: Text(
                        'Transaction History',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 18,
                      color: Color(0xFF6B7280),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (_txns.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'No transactions yet.',
                      style: TextStyle(color: Color(0xFF7A7A7A)),
                    ),
                  )
                else
                  // ignore: unnecessary_to_list_in_spreads
                  ..._txns.map((t) => _TxnTile(txn: t)).toList(),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),

      // Bottom nav
      bottomNavigationBar: NavigationBar(
        selectedIndex: 2, // Stock tab
        onDestinationSelected: (i) {
          switch (i) {
            case 0:
              Navigator.pushReplacementNamed(context, '/dashboard');
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/products');
              break;
            case 2:
              break;
            case 3:
              Navigator.pushReplacementNamed(context, '/alerts');
              break;
               case 4:
              Navigator.pushReplacementNamed(context, '/adminMenu');
              break;
            default:
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Coming soon…')));
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            label: 'Products',
          ),
          NavigationDestination(
            icon: Icon(Icons.swap_vert_rounded),
            label: 'Stock',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_none),
            label: 'Alerts',
          ),
          NavigationDestination(icon: Icon(Icons.menu), label: 'More'),
        ],
      ),
    );
  }

  // --- Helpers & styles ---
  BoxDecoration _panelDecoration() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: Colors.black12),
    boxShadow: const [
      BoxShadow(color: Color(0x11000000), blurRadius: 8, offset: Offset(0, 2)),
    ],
  );

  Widget _toggleButton({
    required bool selected,
    required Color color,
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: selected ? color : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? color : Colors.black12),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: selected ? Colors.white : const Color(0xFF6B7280),
              ),
              const SizedBox(width: 8),
              Text(
                text,
                style: TextStyle(
                  color: selected ? Colors.white : const Color(0xFF374151),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ====== Small widgets ======
class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(color: Colors.grey.shade700, fontSize: 12.5),
    );
  }
}

InputDecoration _inputDeco(String hint) => InputDecoration(
  hintText: hint,
  filled: true,
  fillColor: Colors.white,
  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: Colors.grey.shade300),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: Color(0xFF3B47FF), width: 1.2),
  ),
);

// ====== Models ======
class Product {
  final String name;
  final String sku;
  final String category;
  final int currentStock;

  const Product({
    required this.name,
    required this.sku,
    required this.category,
    required this.currentStock,
  });

  const Product.empty() : name = '', sku = '', category = '', currentStock = 0;

  bool get isEmpty => sku.isEmpty;

  Product copyWith({int? currentStock}) => Product(
    name: name,
    sku: sku,
    category: category,
    currentStock: currentStock ?? this.currentStock,
  );
}

class StockTxn {
  final String id;
  final String sku;
  final String productName;
  final int qty;
  final bool isIn; // true = In, false = Out
  final String note;
  final DateTime date;

  const StockTxn({
    required this.id,
    required this.sku,
    required this.productName,
    required this.qty,
    required this.isIn,
    required this.note,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'sku': sku,
    'productName': productName,
    'qty': qty,
    'isIn': isIn,
    'note': note,
    'date': date.toIso8601String(), // <-- store DATE in local storage
  };

  factory StockTxn.fromJson(Map<String, dynamic> json) => StockTxn(
    id: json['id'] as String,
    sku: json['sku'] as String,
    productName: json['productName'] as String,
    qty: (json['qty'] as num).toInt(),
    isIn: json['isIn'] as bool,
    note: (json['note'] ?? '') as String,
    date: DateTime.parse(json['date'] as String),
  );
}

// ====== History tile ======
class _TxnTile extends StatelessWidget {
  final StockTxn txn;
  const _TxnTile({required this.txn});

  @override
  Widget build(BuildContext context) {
    final isIn = txn.isIn;
    final badgeBg = isIn ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE);
    final badgeFg = isIn ? const Color(0xFF2E7D32) : const Color(0xFFC62828);
    final sign = isIn ? '+' : '-';
    final sideLabel = isIn ? 'In' : 'Out';
    final sideColor = isIn ? const Color(0xFF10B981) : const Color(0xFF6B7280);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  txn.productName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  txn.note.isEmpty ? '—' : txn.note,
                  style: const TextStyle(color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 6),
                Text(
                  '${txn.date.year}-${_two(txn.date.month)}-${_two(txn.date.day)}',
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Right badges
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '$sign${txn.qty}',
                  style: TextStyle(
                    color: badgeFg,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(sideLabel, style: TextStyle(color: sideColor)),
            ],
          ),
        ],
      ),
    );
  }
}

// ====== Seed data ======
List<Product> _initialProducts() => const [
  Product(
    name: 'Premium Coffee Beans',
    sku: 'CFE-001',
    category: 'Beverages',
    currentStock: 45,
  ),
  Product(
    name: 'Organic Green Tea',
    sku: 'TEA-002',
    category: 'Beverages',
    currentStock: 8,
  ),
  Product(
    name: 'Chocolate Bars',
    sku: 'CHC-003',
    category: 'Snacks',
    currentStock: 55,
  ),
  Product(
    name: 'Rice Bag 5kg',
    sku: 'FD-001',
    category: 'Food',
    currentStock: 60,
  ),
  Product(
    name: 'Olive Oil 1L',
    sku: 'FD-004',
    category: 'Food',
    currentStock: 9,
  ),
];

String _two(int n) => n.toString().padLeft(2, '0');
