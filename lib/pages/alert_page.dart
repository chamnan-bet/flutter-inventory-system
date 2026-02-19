import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AlertsPage extends StatefulWidget {
  const AlertsPage({super.key});

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  // Catalog with min stock & expiry dates (static definitions)
  List<ProductInfo> _catalog = _seedCatalog();

  // Current stock overrides loaded from local storage (shared with Stock page)
  Map<String, int> _stockMap = {};

  // Derived lists for UI
  List<ProductInfo> _lowStock = [];
  List<ProductInfo> _expiringSoon = [];

  static const _kStockMap = 'product_stock_map';

  @override
  void initState() {
    super.initState();
    _loadAndCompute();
  }

  Future<void> _loadAndCompute() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final stockStr = sp.getString(_kStockMap);

      if (stockStr != null && stockStr.isNotEmpty) {
        final raw = jsonDecode(stockStr);
        if (raw is Map) {
          final m = Map<String, dynamic>.from(raw);
          _stockMap = m.map((k, v) => MapEntry(k, (v as num).toInt()));
        }
      }

      // Overlay current stock from storage onto catalog
      _catalog = _catalog
          .map(
            (p) => p.copyWith(currentStock: _stockMap[p.sku] ?? p.currentStock),
          )
          .toList();

      _recalculate();
      setState(() {});
    } catch (e) {
      // If anything goes wrong, just compute using defaults
      _recalculate();
      setState(() {});
    }
  }

  void _recalculate() {
    final now = DateTime.now();
    _lowStock = _catalog
        .where((p) => p.currentStock > 0 && p.currentStock < p.minStock)
        .toList();

    _expiringSoon = _catalog.where((p) {
      final days = p.daysToExpiry(now);
      return days >= 0 && days <= 60; // within 2 months
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final outOfStock = _catalog.where((p) => p.currentStock <= 0).length;
    final lowStock = _lowStock.length;
    final expSoon = _expiringSoon.length;

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
            'Alerts',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          const Text(
            'Monitor critical inventory issues',
            style: TextStyle(color: Color(0xFF7A7A7A), fontSize: 13),
          ),
          const SizedBox(height: 12),

          // Top metric chips
          Row(
            children: [
              Expanded(
                child: _MetricChip(
                  icon: Icons.indeterminate_check_box_outlined,
                  iconBg: const Color(0xFFFFEBEE),
                  title: 'Out of Stock',
                  value: '$outOfStock',
                  borderColor: const Color(0xFFFFCDD2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricChip(
                  icon: Icons.warning_amber_rounded,
                  iconBg: const Color(0xFFFFF7E6),
                  title: 'Low Stock',
                  value: '$lowStock',
                  borderColor: const Color(0xFFFFE0B2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricChip(
                  icon: Icons.access_time_rounded,
                  iconBg: const Color(0xFFFFF8E1),
                  title: 'Expiring Soon',
                  value: '$expSoon',
                  borderColor: const Color(0xFFFFECB3),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Low Stock section
          _SectionPanel(
            icon: Icons.warning_amber_rounded,
            iconColor: const Color(0xFFFF6D00),
            title: 'Low Stock Alert (${_lowStock.length})',
            tintBg: const Color(0xFFFFF7E6),
            tintBorder: const Color(0xFFFFE0B2),
            child: _lowStock.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'No low stock items.',
                      style: TextStyle(color: Color(0xFF7A7A7A)),
                    ),
                  )
                : Column(
                    children: _lowStock
                        .map((p) => _LowStockTile(product: p))
                        .toList(),
                  ),
          ),

          const SizedBox(height: 12),

          // Expiring soon section
          _SectionPanel(
            icon: Icons.schedule_outlined,
            iconColor: const Color(0xFFF59E0B),
            title: 'Expiring Within 2 Months (${_expiringSoon.length})',
            tintBg: const Color(0xFFFFF8E1),
            tintBorder: const Color(0xFFFFECB3),
            child: _expiringSoon.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'No items expiring soon.',
                      style: TextStyle(color: Color(0xFF7A7A7A)),
                    ),
                  )
                : Column(
                    children: _expiringSoon
                        .map((p) => _ExpiringTile(product: p, now: now))
                        .toList(),
                  ),
          ),

          const SizedBox(height: 20),
        ],
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: 3, // Alerts tab
        onDestinationSelected: (i) {
          switch (i) {
            case 0:
              Navigator.pushReplacementNamed(context, '/dashboard');
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/products');
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/stock');
              break;
            case 4:
              Navigator.pushReplacementNamed(context, '/adminMenu');
              break;
            default:
              _snack('More coming soon…');
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            label: 'Products',
          ),
          NavigationDestination(
            icon: Icon(Icons.warehouse_outlined),
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

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

/* ---------------------------- UI widgets ---------------------------- */

class _MetricChip extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final String title;
  final String value;
  final Color borderColor;

  const _MetricChip({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.value,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 66,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.black87),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF7A7A7A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionPanel extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Color tintBg;
  final Color tintBorder;
  final Widget child;

  const _SectionPanel({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.tintBg,
    required this.tintBorder,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tintBg,
        border: Border.all(color: tintBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black12),
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x11000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _LowStockTile extends StatelessWidget {
  final ProductInfo product;
  const _LowStockTile({required this.product});

  @override
  Widget build(BuildContext context) {
    final deficit = (product.minStock - product.currentStock).clamp(0, 1 << 31);
    final ratio = product.minStock == 0
        ? 0.0
        : (product.currentStock / product.minStock).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          // Header row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'SKU: ${product.sku}',
                      style: const TextStyle(
                        color: Color(0xFF7A7A7A),
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      product.category,
                      style: const TextStyle(
                        color: Color(0xFF7A7A7A),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${product.currentStock}',
                    style: const TextStyle(
                      color: Color(0xFFD32F2F),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Min: ${product.minStock}',
                    style: const TextStyle(
                      color: Color(0xFF7A7A7A),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Thin progress bar (orange)
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE0B2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: ratio,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9800),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Tip row
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7E6),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFFE0B2)),
            ),
            child: Text(
              'Need to restock $deficit more units to reach minimum level',
              style: const TextStyle(color: Color(0xFFF57C00), fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpiringTile extends StatelessWidget {
  final ProductInfo product;
  final DateTime now;
  const _ExpiringTile({required this.product, required this.now});

  @override
  Widget build(BuildContext context) {
    final days = product.daysToExpiry(now);
    final dateStr =
        '${product.expiresOn.year}-${_two(product.expiresOn.month)}-${_two(product.expiresOn.day)}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  'SKU: ${product.sku}',
                  style: const TextStyle(
                    color: Color(0xFF7A7A7A),
                    fontSize: 12,
                  ),
                ),
                Text(
                  'Stock: ${product.currentStock} units',
                  style: const TextStyle(
                    color: Color(0xFF7A7A7A),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Right badge + date
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '$days days',
                  style: const TextStyle(
                    color: Color(0xFFF57C00),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                dateStr,
                style: const TextStyle(color: Color(0xFF7A7A7A), fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/* ---------------------------- Models & seed ---------------------------- */

class ProductInfo {
  final String name;
  final String sku;
  final String category;
  final int minStock;
  final DateTime expiresOn;
  final int currentStock; // overlay from local storage

  const ProductInfo({
    required this.name,
    required this.sku,
    required this.category,
    required this.minStock,
    required this.expiresOn,
    required this.currentStock,
  });

  int daysToExpiry(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    return expiresOn.difference(today).inDays;
  }

  ProductInfo copyWith({int? currentStock}) => ProductInfo(
    name: name,
    sku: sku,
    category: category,
    minStock: minStock,
    expiresOn: expiresOn,
    currentStock: currentStock ?? this.currentStock,
  );
}

List<ProductInfo> _seedCatalog() => [
  ProductInfo(
    name: 'Organic Green Tea',
    sku: 'TEA-002',
    category: 'Beverages',
    minStock: 15,
    expiresOn: DateTime(2026, 3, 20),
    currentStock: 8, // will be overridden by SharedPreferences if present
  ),
  ProductInfo(
    name: 'Milk Powder',
    sku: 'MLK-004',
    category: 'Dairy',
    minStock: 10,
    expiresOn: DateTime(2026, 4, 10),
    currentStock: 5,
  ),
  ProductInfo(
    name: 'Premium Coffee Beans',
    sku: 'CFE-001',
    category: 'Beverages',
    minStock: 20,
    expiresOn: DateTime(2026, 4, 15),
    currentStock: 45,
  ),
];

String _two(int n) => n.toString().padLeft(2, '0');
