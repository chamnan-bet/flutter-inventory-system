import 'package:flutter/material.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _chipScrollCtrl = ScrollController();

  final List<String> _categories = [
    'All',
    'Beverages',
    'Snacks',
    'Dairy',
    'Food',
  ];
  String _selectedCat = 'All';

  // ====== Demo Data (now with MORE Food items) ======
  final List<Product> _items = [
    // Beverages
    Product(
      name: 'Premium Coffee Beans',
      sku: 'CFE-001',
      category: 'Beverages',
      currentStock: 45,
      minStock: 20,
      unitPrice: 15.99,
      updated: DateTime(2026, 2, 15),
      expiresOn: DateTime(2026, 4, 15),
      trendUp: true,
    ),
    Product(
      name: 'Organic Green Tea',
      sku: 'TEA-002',
      category: 'Beverages',
      currentStock: 8,
      minStock: 15,
      unitPrice: 12.50,
      updated: DateTime(2026, 2, 10),
      expiresOn: DateTime(2026, 3, 20),
      trendUp: true,
    ),

    // Snacks
    Product(
      name: 'Chocolate Bars',
      sku: 'CHC-003',
      category: 'Snacks',
      currentStock: 55,
      minStock: 25,
      unitPrice: 1.25,
      updated: DateTime(2026, 2, 11),
      expiresOn: DateTime(2026, 8, 1),
    ),

    // Dairy
    Product(
      name: 'Whole Milk 1L',
      sku: 'DRY-001',
      category: 'Dairy',
      currentStock: 18,
      minStock: 12,
      unitPrice: 1.50,
      updated: DateTime(2026, 2, 12),
      expiresOn: DateTime(2026, 3, 5),
    ),

    // Food (ADDED more cards)
    Product(
      name: 'Rice Bag 5kg',
      sku: 'FD-001',
      category: 'Food',
      currentStock: 60,
      minStock: 30,
      unitPrice: 6.20,
      updated: DateTime(2026, 2, 9),
      expiresOn: DateTime(2027, 2, 1),
      trendUp: true,
    ),
    Product(
      name: 'Canned Tuna',
      sku: 'FD-002',
      category: 'Food',
      currentStock: 22,
      minStock: 20,
      unitPrice: 2.40,
      updated: DateTime(2026, 2, 14),
      expiresOn: DateTime(2027, 6, 30),
    ),
    Product(
      name: 'Pasta Spaghetti 1kg',
      sku: 'FD-003',
      category: 'Food',
      currentStock: 12,
      minStock: 20,
      unitPrice: 2.10,
      updated: DateTime(2026, 2, 13),
      expiresOn: DateTime(2027, 1, 10),
      trendUp: false,
    ),
    Product(
      name: 'Olive Oil 1L',
      sku: 'FD-004',
      category: 'Food',
      currentStock: 9,
      minStock: 10,
      unitPrice: 7.90,
      updated: DateTime(2026, 2, 8),
      expiresOn: DateTime(2027, 5, 15),
    ),
    Product(
      name: 'Tomato Sauce 500ml',
      sku: 'FD-005',
      category: 'Food',
      currentStock: 33,
      minStock: 15,
      unitPrice: 1.80,
      updated: DateTime(2026, 2, 7),
      expiresOn: DateTime(2026, 11, 30),
    ),
  ];

  // ====== Actions ======
  void _logout() => Navigator.pushReplacementNamed(context, '/login');

  Future<void> _addProduct() async {
    final result = await _openProductForm();
    if (result != null) {
      setState(() => _items.add(result));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Added: ${result.name}')));
    }
  }

  Future<void> _editProduct(int index) async {
    final existing = _items[index];
    final result = await _openProductForm(existing: existing);
    if (result != null) {
      setState(() => _items[index] = result.copyWith(updated: DateTime.now()));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Updated: ${result.name}')));
    }
  }

  Future<void> _deleteProduct(int index) async {
    final p = _items[index];
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${p.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      setState(() => _items.removeAt(index));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Deleted: ${p.name}')));
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _chipScrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Build filtered view but keep original indices for actions
    final List<int> filteredIndexes = _items
        .asMap()
        .entries
        .where((e) {
          final p = e.value;
          final byCat = _selectedCat == 'All' || p.category == _selectedCat;
          final q = _searchCtrl.text.trim().toLowerCase();
          final byQuery =
              q.isEmpty ||
              p.name.toLowerCase().contains(q) ||
              p.sku.toLowerCase().contains(q);
          return byCat && byQuery;
        })
        .map((e) => e.key)
        .toList();

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
            onPressed: _logout,
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
          const SizedBox(width: 8),
        ],
      ),

      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Title + Add
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Products',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF3B47FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _addProduct,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('Add', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${filteredIndexes.length} item${filteredIndexes.length == 1 ? '' : 's'}',
            style: const TextStyle(color: Color(0xFF7A7A7A), fontSize: 13),
          ),
          const SizedBox(height: 12),

          // Search
          TextField(
            controller: _searchCtrl,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search products...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF3B47FF),
                  width: 1.2,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Categories chips
          SizedBox(
            height: 40,
            child: ListView.separated(
              controller: _chipScrollCtrl,
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              // ignore: unnecessary_underscores
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final cat = _categories[i];
                final selected = cat == _selectedCat;
                return ChoiceChip(
                  label: Text(cat),
                  selected: selected,
                  onSelected: (_) => setState(() => _selectedCat = cat),
                  selectedColor: const Color(0xFF3B47FF),
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : Colors.black87,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                  backgroundColor: const Color(0xFFF3F4F6),
                  side: BorderSide(
                    color: selected
                        ? const Color(0xFF3B47FF)
                        : Colors.transparent,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          // Tiny progress bar indicator (visual cue like your mock)
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Align(
              alignment: Alignment.lerp(
                Alignment.centerLeft,
                Alignment.centerRight,
                (_selectedCatIndex() + 1) / _categories.length,
              )!,
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Product Cards
          ...filteredIndexes.map((idx) {
            final p = _items[idx];
            return ProductCard(
              product: p,
              onEdit: () => _editProduct(idx),
              onDelete: () => _deleteProduct(idx),
            );
          }),

          const SizedBox(height: 24),
        ],
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: 1, // Products active
        onDestinationSelected: (i) {
          switch (i) {
            case 0:
              Navigator.pushReplacementNamed(context, '/dashboard');
              break;
            case 1:
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/stock');
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
              ).showSnackBar(const SnackBar(content: Text('Tab coming soon…')));
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_rounded),
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

  int _selectedCatIndex() =>
      _categories.indexOf(_selectedCat).clamp(0, _categories.length - 1);

  // ====== Bottom Sheet Form ======
  Future<Product?> _openProductForm({Product? existing}) async {
    final formKey = GlobalKey<FormState>();

    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final skuCtrl = TextEditingController(text: existing?.sku ?? '');
    String category = existing?.category ?? 'Food';
    final currentCtrl = TextEditingController(
      text: existing?.currentStock.toString() ?? '',
    );
    final minCtrl = TextEditingController(
      text: existing?.minStock.toString() ?? '',
    );
    final priceCtrl = TextEditingController(
      text: existing?.unitPrice.toString() ?? '',
    );
    DateTime? expires = existing?.expiresOn;
    bool trendUp = existing?.trendUp ?? true;

    Product? result;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    existing == null ? 'Add Product' : 'Edit Product',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),

                  _LabeledField(
                    label: 'Name',
                    child: TextFormField(
                      controller: nameCtrl,
                      textInputAction: TextInputAction.next,
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                      decoration: _inputDeco('Enter product name'),
                    ),
                  ),
                  const SizedBox(height: 10),

                  _LabeledField(
                    label: 'SKU',
                    child: TextFormField(
                      controller: skuCtrl,
                      textInputAction: TextInputAction.next,
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                      decoration: _inputDeco('e.g., FD-005'),
                    ),
                  ),
                  const SizedBox(height: 10),

                  _LabeledField(
                    label: 'Category',
                    child: DropdownButtonFormField<String>(
                      value: category,
                      items: _categories
                          .where((c) => c != 'All')
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                      onChanged: (v) => category = v ?? 'Food',
                      decoration: _inputDeco('Select category'),
                    ),
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: _LabeledField(
                          label: 'Current Stock',
                          child: TextFormField(
                            controller: currentCtrl,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            validator: (v) => (int.tryParse(v ?? '') == null)
                                ? 'Enter a number'
                                : null,
                            decoration: _inputDeco('e.g., 20'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _LabeledField(
                          label: 'Min Stock',
                          child: TextFormField(
                            controller: minCtrl,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            validator: (v) => (int.tryParse(v ?? '') == null)
                                ? 'Enter a number'
                                : null,
                            decoration: _inputDeco('e.g., 10'),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  _LabeledField(
                    label: 'Unit Price',
                    child: TextFormField(
                      controller: priceCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textInputAction: TextInputAction.next,
                      validator: (v) => (double.tryParse(v ?? '') == null)
                          ? 'Enter a number'
                          : null,
                      decoration: _inputDeco('e.g., 12.50'),
                    ),
                  ),
                  const SizedBox(height: 10),

                  _LabeledField(
                    label: 'Expires On',
                    child: InkWell(
                      onTap: () async {
                        final now = DateTime.now();
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate:
                              expires ?? now.add(const Duration(days: 30)),
                          firstDate: now.subtract(const Duration(days: 1)),
                          lastDate: DateTime(now.year + 5),
                        );
                        if (picked != null) {
                          setState(() {}); // rebuild outer state if needed
                          expires = picked;
                        }
                      },
                      child: InputDecorator(
                        decoration: _inputDeco('Pick a date'),
                        child: Text(
                          expires == null
                              ? 'Tap to select date'
                              : '${expires!.year}-${_two(expires!.month)}-${_two(expires!.day)}',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      const Text('Trend Up'),
                      const SizedBox(width: 8),
                      Switch(
                        value: trendUp,
                        onChanged: (v) {
                          trendUp = v;
                          (ctx as Element).markNeedsBuild();
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF3B47FF),
                          ),
                          onPressed: () {
                            if (!formKey.currentState!.validate()) return;
                            if (expires == null) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(
                                  content: Text('Please select Expiry date'),
                                ),
                              );
                              return;
                            }
                            final p = Product(
                              name: nameCtrl.text.trim(),
                              sku: skuCtrl.text.trim(),
                              category: category,
                              currentStock: int.parse(currentCtrl.text),
                              minStock: int.parse(minCtrl.text),
                              unitPrice: double.parse(priceCtrl.text),
                              updated: DateTime.now(),
                              expiresOn: expires!,
                              trendUp: trendUp,
                            );
                            result = p;
                            Navigator.pop(ctx);
                          },
                          child: Text(existing == null ? 'Add' : 'Save'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    return result;
  }
}

// ====== Model ======
class Product {
  final String name;
  final String sku;
  final String category;
  final int currentStock;
  final int minStock;
  final double unitPrice;
  final DateTime updated;
  final DateTime expiresOn;
  final bool trendUp;

  const Product({
    required this.name,
    required this.sku,
    required this.category,
    required this.currentStock,
    required this.minStock,
    required this.unitPrice,
    required this.updated,
    required this.expiresOn,
    this.trendUp = true,
  });

  bool get isLowStock => currentStock < minStock;

  int get daysToExpiry {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return expiresOn.difference(today).inDays;
  }

  Product copyWith({
    String? name,
    String? sku,
    String? category,
    int? currentStock,
    int? minStock,
    double? unitPrice,
    DateTime? updated,
    DateTime? expiresOn,
    bool? trendUp,
  }) {
    return Product(
      name: name ?? this.name,
      sku: sku ?? this.sku,
      category: category ?? this.category,
      currentStock: currentStock ?? this.currentStock,
      minStock: minStock ?? this.minStock,
      unitPrice: unitPrice ?? this.unitPrice,
      updated: updated ?? this.updated,
      expiresOn: expiresOn ?? this.expiresOn,
      trendUp: trendUp ?? this.trendUp,
    );
  }
}

// ====== Widgets ======
class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ProductCard({
    super.key,
    required this.product,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final low = product.isLowStock;
    final days = product.daysToExpiry;
    final expiringSoon = days >= 0 && days <= 60;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top: name + trend + edit/delete
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(
                product.trendUp ? Icons.trending_up : Icons.trending_down,
                size: 18,
                color: product.trendUp
                    ? Colors.green.shade700
                    : Colors.red.shade700,
              ),
              const SizedBox(width: 8),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Edit',
                icon: const Icon(Icons.edit, color: Color(0xFF3B47FF)),
                onPressed: onEdit,
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Delete',
                icon: const Icon(
                  Icons.delete_outline,
                  color: Color(0xFFD32F2F),
                ),
                onPressed: onDelete,
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'SKU: ${product.sku}',
            style: const TextStyle(color: Color(0xFF7A7A7A)),
          ),
          const SizedBox(height: 6),

          // Category chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              product.category,
              style: const TextStyle(fontSize: 12.5),
            ),
          ),
          const SizedBox(height: 12),

          // Metrics row
          Row(
            children: [
              Expanded(
                child: _kv(
                  'Current Stock',
                  '${product.currentStock}',
                  valueColor: low ? const Color(0xFFD32F2F) : Colors.black,
                ),
              ),
              Expanded(child: _kv('Min Stock', '${product.minStock}')),
              Expanded(
                child: _kv(
                  'Unit Price',
                  '\$${product.unitPrice.toStringAsFixed(2)}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Expiry + updated
          Row(
            children: [
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.black87),
                    children: [
                      const TextSpan(
                        text: 'Expires: ',
                        style: TextStyle(color: Color(0xFF7A7A7A)),
                      ),
                      TextSpan(
                        text:
                            '${product.expiresOn.year}-${_two(product.expiresOn.month)}-${_two(product.expiresOn.day)}',
                        style: const TextStyle(
                          color: Color(0xFFD32F2F),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Text(
                'Updated: ${product.updated.year}-${_two(product.updated.month)}-${_two(product.updated.day)}',
                style: const TextStyle(color: Color(0xFF7A7A7A)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Status chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (low)
                _statusChip(
                  'Low Stock',
                  bg: const Color(0xFFFFF3E6),
                  fg: const Color(0xFFFF6D00),
                ),
              if (expiringSoon)
                _statusChip(
                  'Expiring in $days days',
                  bg: const Color(0xFFFFEBEE),
                  fg: const Color(0xFFD32F2F),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v, {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          k,
          style: const TextStyle(color: Color(0xFF7A7A7A), fontSize: 12.5),
        ),
        const SizedBox(height: 6),
        Text(
          v,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: valueColor ?? Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _statusChip(String text, {required Color bg, required Color fg}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w600,
          fontSize: 12.5,
        ),
      ),
    );
  }
}

// ====== Shared small UI helpers ======
class _LabeledField extends StatelessWidget {
  final String label;
  final Widget child;
  const _LabeledField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade700, fontSize: 12.5),
        ),
        const SizedBox(height: 6),
        child,
      ],
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

String _two(int n) => n.toString().padLeft(2, '0');
