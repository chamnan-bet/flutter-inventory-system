import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SuppliersPage extends StatefulWidget {
  const SuppliersPage({super.key});

  @override
  State<SuppliersPage> createState() => _SuppliersPageState();
}

class _SuppliersPageState extends State<SuppliersPage> {
  static const _kStorageKey = 'suppliers_list_v1';

  final _searchCtrl = TextEditingController();
  List<Supplier> _suppliers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // --------------------- Storage ---------------------
  Future<void> _loadSuppliers() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final raw = sp.getString(_kStorageKey);
      if (raw == null || raw.isEmpty) {
        _suppliers = _seedSuppliers(); // seed demo data on first run
        await _save();
      } else {
        final list = jsonDecode(raw);
        _suppliers = (list as List)
            .map((e) => Supplier.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
    } catch (_) {
      _suppliers = _seedSuppliers();
    }
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(
      _kStorageKey,
      jsonEncode(_suppliers.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> _resetDemo() async {
    _suppliers = _seedSuppliers();
    await _save();
    setState(() {});
  }

  // --------------------- Metrics ---------------------
  int get totalSuppliers => _suppliers.length;
  int get activeSuppliers => _suppliers.where((s) => s.active).length;
  String get avgRating {
    if (_suppliers.isEmpty) return '0.0';
    final sum = _suppliers.fold<double>(0.0, (a, b) => a + b.rating);
    return (sum / _suppliers.length).toStringAsFixed(1);
  }

  // --------------------- Actions ---------------------
  Future<void> _addSupplier() async {
    final s = await _openForm();
    if (s != null) {
      setState(() => _suppliers.insert(0, s));
      await _save();
      _toast('Supplier added');
    }
  }

  Future<void> _editSupplier(int index) async {
    final s = _suppliers[index];
    final updated = await _openForm(existing: s);
    if (updated != null) {
      setState(
        () => _suppliers[index] = updated.copyWith(lastUpdated: DateTime.now()),
      );
      await _save();
      _toast('Supplier updated');
    }
  }

  Future<void> _deleteSupplier(int index) async {
    final s = _suppliers[index];
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Supplier'),
        content: Text('Are you sure you want to delete "${s.name}"?'),
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
    if (ok == true) {
      setState(() => _suppliers.removeAt(index));
      await _save();
      _toast('Supplier deleted');
    }
  }

  // --------------------- UI ---------------------
  @override
  Widget build(BuildContext context) {
    final textGrey = const Color(0xFF7A7A7A);

    // Filtered list based on search
    final q = _searchCtrl.text.trim().toLowerCase();
    final filtered = q.isEmpty
        ? _suppliers
        : _suppliers.where((s) {
            return s.name.toLowerCase().contains(q) ||
                s.contactName.toLowerCase().contains(q) ||
                s.category.toLowerCase().contains(q) ||
                s.email.toLowerCase().contains(q);
          }).toList();

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

      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                // Header + Add
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Supplier Management',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Manage your suppliers and vendors',
                            style: TextStyle(color: textGrey, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF3B47FF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _addSupplier,
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text(
                        'Add',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Metrics
                Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        icon: Icons.business_rounded,
                        iconBg: const Color(0xFFE3F2FD),
                        label: 'Total Suppliers',
                        value: '$totalSuppliers',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _MetricCard(
                        icon: Icons.check_circle_outline,
                        iconBg: const Color(0xFFE8F5E9),
                        label: 'Active',
                        value: '$activeSuppliers',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _MetricCard(
                        icon: Icons.star_rate_rounded,
                        iconBg: const Color(0xFFFFF3E0),
                        label: 'Avg Rating',
                        value: avgRating,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Search
                TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search suppliers...',
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

                // List
                ...List.generate(filtered.length, (i) {
                  final idx = _suppliers.indexOf(
                    filtered[i],
                  ); // keep original index for actions
                  return SupplierCard(
                    supplier: filtered[i],
                    onEdit: () => _editSupplier(idx),
                    onDelete: () => _deleteSupplier(idx),
                  );
                }),

                const SizedBox(height: 12),

                // Footer actions (clear storage)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _resetDemo,
                    icon: const Icon(Icons.restore, size: 18),
                    label: const Text('Reset demo data'),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: 4, // More/Admin tab
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
            case 3:
              Navigator.pushReplacementNamed(context, '/alerts');
              break;
            case 4:
              Navigator.pushReplacementNamed(context, '/adminMenu');
              break;
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

  // --------------------- Bottom-sheet Form ---------------------
  Future<Supplier?> _openForm({Supplier? existing}) async {
    final formKey = GlobalKey<FormState>();

    final name = TextEditingController(text: existing?.name ?? '');
    final contactName = TextEditingController(
      text: existing?.contactName ?? '',
    );
    final category = ValueNotifier<String>(
      existing?.category ?? 'Food & Beverages',
    );
    final phone = TextEditingController(text: existing?.phone ?? '');
    final email = TextEditingController(text: existing?.email ?? '');
    final address = TextEditingController(text: existing?.address ?? '');
    final rating = ValueNotifier<double>(existing?.rating ?? 4.0);
    final active = ValueNotifier<bool>(existing?.active ?? true);
    final orderCount = TextEditingController(
      text: (existing?.ordersCount ?? 0).toString(),
    );
    DateTime lastUpdated = existing?.lastUpdated ?? DateTime.now();

    Supplier? result;

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
                    existing == null ? 'Add Supplier' : 'Edit Supplier',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),

                  _Labeled(
                    'Company Name *',
                    TextFormField(
                      controller: name,
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                      textInputAction: TextInputAction.next,
                      decoration: _inputDeco('e.g., Global Food Distributors'),
                    ),
                  ),
                  const SizedBox(height: 10),

                  _Labeled(
                    'Contact Person *',
                    TextFormField(
                      controller: contactName,
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                      textInputAction: TextInputAction.next,
                      decoration: _inputDeco('e.g., John Smith'),
                    ),
                  ),
                  const SizedBox(height: 10),

                  _Labeled(
                    'Category',
                    ValueListenableBuilder<String>(
                      valueListenable: category,
                      // ignore: unnecessary_underscores
                      builder: (_, value, __) {
                        return DropdownButtonFormField<String>(
                          // ignore: deprecated_member_use
                          value: value,
                          items:
                              const [
                                    'Food & Beverages',
                                    'Dairy products',
                                    'Organic Products',
                                    'Snacks',
                                    'Other',
                                  ]
                                  .map(
                                    (c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(c),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (v) => category.value = v ?? value,
                          decoration: _inputDeco('Select category'),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: _Labeled(
                          'Phone',
                          TextFormField(
                            controller: phone,
                            textInputAction: TextInputAction.next,
                            decoration: _inputDeco('+1-555-0101'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _Labeled(
                          'Email',
                          TextFormField(
                            controller: email,
                            textInputAction: TextInputAction.next,
                            decoration: _inputDeco('john@example.com'),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  _Labeled(
                    'Address',
                    TextFormField(
                      controller: address,
                      minLines: 1,
                      maxLines: 2,
                      decoration: _inputDeco(
                        '123 Commerce St, New York, NY 10001',
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: _Labeled(
                          'Rating: ${rating.value.toStringAsFixed(1)}',
                          ValueListenableBuilder<double>(
                            valueListenable: rating,
                            // ignore: unnecessary_underscores
                            builder: (_, value, __) {
                              return Slider(
                                value: value,
                                min: 0,
                                max: 5,
                                divisions: 50,
                                label: value.toStringAsFixed(1),
                                onChanged: (v) => rating.value = v,
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _Labeled(
                          'Orders Count',
                          TextFormField(
                            controller: orderCount,
                            keyboardType: TextInputType.number,
                            decoration: _inputDeco('e.g., 27'),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  _Labeled(
                    'Status',
                    ValueListenableBuilder<bool>(
                      valueListenable: active,
                      // ignore: unnecessary_underscores
                      builder: (_, on, __) {
                        return Row(
                          children: [
                            ChoiceChip(
                              label: const Text('Active'),
                              selected: on,
                              onSelected: (_) => active.value = true,
                              selectedColor: const Color(0xFFE8F5E9),
                              labelStyle: TextStyle(
                                color: on
                                    ? const Color(0xFF2E7D32)
                                    : Colors.black87,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: const Text('Inactive'),
                              selected: !on,
                              onSelected: (_) => active.value = false,
                              selectedColor: const Color(0xFFFFEBEE),
                              labelStyle: TextStyle(
                                color: !on
                                    ? const Color(0xFFC62828)
                                    : Colors.black87,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),

                  _Labeled(
                    'Last Updated',
                    InkWell(
                      onTap: () async {
                        final now = DateTime.now();
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: lastUpdated,
                          firstDate: DateTime(now.year - 5),
                          lastDate: DateTime(now.year + 5),
                        );
                        if (picked != null) {
                          lastUpdated = picked;
                          (ctx as Element).markNeedsBuild();
                        }
                      },
                      child: InputDecorator(
                        decoration: _inputDeco('Pick a date'),
                        child: Text(
                          '${lastUpdated.year}-${_two(lastUpdated.month)}-${_two(lastUpdated.day)}',
                        ),
                      ),
                    ),
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

                            final orders =
                                int.tryParse(orderCount.text.trim()) ?? 0;

                            result = Supplier(
                              id:
                                  existing?.id ??
                                  DateTime.now().millisecondsSinceEpoch
                                      .toString(),
                              name: name.text.trim(),
                              contactName: contactName.text.trim(),
                              category: category.value,
                              phone: phone.text.trim(),
                              email: email.text.trim(),
                              address: address.text.trim(),
                              rating: double.parse(
                                rating.value.toStringAsFixed(1),
                              ),
                              active: active.value,
                              ordersCount: orders,
                              lastUpdated: lastUpdated,
                            );
                            Navigator.pop(ctx);
                          },
                          child: Text(
                            existing == null ? 'Add Supplier' : 'Save Changes',
                          ),
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

  // --------------------- Utils ---------------------
  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

// ==================== Widgets ====================

class SupplierCard extends StatelessWidget {
  final Supplier supplier;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const SupplierCard({
    super.key,
    required this.supplier,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final badgeColor = supplier.active
        ? const Color(0xFFE8F5E9)
        : const Color(0xFFFFEBEE);
    final badgeText = supplier.active ? 'active' : 'inactive';
    final badgeFg = supplier.active
        ? const Color(0xFF2E7D32)
        : const Color(0xFFC62828);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: name + status + actions
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  children: [
                    Text(
                      supplier.name,
                      style: const TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(color: badgeFg, fontSize: 12.5),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Edit',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.edit, color: Color(0xFF3B47FF)),
                onPressed: onEdit,
              ),
              IconButton(
                tooltip: 'Delete',
                visualDensity: VisualDensity.compact,
                icon: const Icon(
                  Icons.delete_outline,
                  color: Color(0xFFD32F2F),
                ),
                onPressed: onDelete,
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Contact person + category
          Row(
            children: [
              Expanded(
                child: Text(
                  supplier.contactName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              _StarRating(rating: supplier.rating),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            supplier.category,
            style: const TextStyle(color: Color(0xFF7A7A7A), fontSize: 12.5),
          ),
          const SizedBox(height: 8),

          // Contact details
          _KV(icon: Icons.phone, text: supplier.phone),
          _KV(icon: Icons.email_outlined, text: supplier.email),
          _KV(icon: Icons.location_on_outlined, text: supplier.address),
          const SizedBox(height: 8),

          // Bottom row: orders + last updated
          Row(
            children: [
              Expanded(
                child: Text(
                  '${supplier.ordersCount} order${supplier.ordersCount == 1 ? '' : 's'}',
                  style: const TextStyle(color: Color(0xFF7A7A7A)),
                ),
              ),
              Text(
                'Last: ${supplier.lastUpdated.year}-${_two(supplier.lastUpdated.month)}-${_two(supplier.lastUpdated.day)}',
                style: const TextStyle(color: Color(0xFF7A7A7A)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final String label;
  final String value;

  const _MetricCard({
    required this.icon,
    required this.iconBg,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 66,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
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
                  label,
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

class _StarRating extends StatelessWidget {
  final double rating; // 0..5
  const _StarRating({required this.rating});

  @override
  Widget build(BuildContext context) {
    final full = rating.floor();
    final hasHalf = (rating - full) >= 0.5;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        if (i < full) {
          return const Icon(Icons.star, size: 16, color: Color(0xFFFFC107));
        } else if (i == full && hasHalf) {
          return const Icon(
            Icons.star_half,
            size: 16,
            color: Color(0xFFFFC107),
          );
        } else {
          return const Icon(
            Icons.star_border,
            size: 16,
            color: Color(0xFFFFC107),
          );
        }
      }),
    );
  }
}

class _KV extends StatelessWidget {
  final IconData icon;
  final String text;
  const _KV({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    if (text.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [Icon(icon, size: 16, color: const Color(0xFF6B7280))],
      ).buildWithExpanded(Text(text)),
    );
  }
}

extension on Row {
  Widget buildWithExpanded(Widget right) {
    return Row(
      children: [
        ...children,
        const SizedBox(width: 8),
        Expanded(child: right),
      ],
    );
  }
}

// ==================== Model ====================

class Supplier {
  final String id;
  final String name;
  final String contactName;
  final String category;
  final String phone;
  final String email;
  final String address;
  final double rating;
  final bool active;
  final int ordersCount;
  final DateTime lastUpdated;

  const Supplier({
    required this.id,
    required this.name,
    required this.contactName,
    required this.category,
    required this.phone,
    required this.email,
    required this.address,
    required this.rating,
    required this.active,
    required this.ordersCount,
    required this.lastUpdated,
  });

  Supplier copyWith({
    String? id,
    String? name,
    String? contactName,
    String? category,
    String? phone,
    String? email,
    String? address,
    double? rating,
    bool? active,
    int? ordersCount,
    DateTime? lastUpdated,
  }) {
    return Supplier(
      id: id ?? this.id,
      name: name ?? this.name,
      contactName: contactName ?? this.contactName,
      category: category ?? this.category,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      rating: rating ?? this.rating,
      active: active ?? this.active,
      ordersCount: ordersCount ?? this.ordersCount,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'contactName': contactName,
    'category': category,
    'phone': phone,
    'email': email,
    'address': address,
    'rating': rating,
    'active': active,
    'ordersCount': ordersCount,
    'lastUpdated': lastUpdated.toIso8601String(),
  };

  factory Supplier.fromJson(Map<String, dynamic> json) => Supplier(
    id: json['id'] as String,
    name: (json['name'] ?? '') as String,
    contactName: (json['contactName'] ?? '') as String,
    category: (json['category'] ?? '') as String,
    phone: (json['phone'] ?? '') as String,
    email: (json['email'] ?? '') as String,
    address: (json['address'] ?? '') as String,
    rating: (json['rating'] is int)
        ? (json['rating'] as int).toDouble()
        : (json['rating'] as num).toDouble(),
    active: json['active'] as bool,
    ordersCount: (json['ordersCount'] as num).toInt(),
    lastUpdated: DateTime.parse(json['lastUpdated'] as String),
  );
}

// ==================== Helpers ====================

InputDecoration _inputDeco(String hint) => InputDecoration(
  hintText: hint,
  filled: true,
  fillColor: Colors.white,
  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: Colors.grey.shade300),
  ),
  focusedBorder: const OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(12)),
    borderSide: BorderSide(color: Color(0xFF3B47FF), width: 1.2),
  ),
);

class _Labeled extends StatelessWidget {
  final String label;
  final Widget child;
  const _Labeled(this.label, this.child);

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

String _two(int n) => n.toString().padLeft(2, '0');

// Seed demo records (matching your screenshot)
List<Supplier> _seedSuppliers() => [
  Supplier(
    id: '1',
    name: 'Global Food Distributors',
    contactName: 'John Smith',
    category: 'Food & Beverages',
    phone: '+1-555-0101',
    email: 'john@globalfood.com',
    address: '123 Commerce St, New York, NY 10001',
    rating: 4.6,
    active: true,
    ordersCount: 102,
    lastUpdated: DateTime(2026, 2, 19),
  ),
  Supplier(
    id: '2',
    name: 'Fresh Dairy Supplies',
    contactName: 'Sarah Johnson',
    category: 'Dairy products',
    phone: '+1-555-0102',
    email: 'sarah@freshdairy.com',
    address: '456 Milk Road, Boston, MA 02108',
    rating: 4.8,
    active: true,
    ordersCount: 67,
    lastUpdated: DateTime(2026, 2, 18),
  ),
  Supplier(
    id: '3',
    name: 'Organic Farms Co',
    contactName: 'Michael Brown',
    category: 'Organic Products',
    phone: '+1-555-0103',
    email: 'michael@organicfarms.co',
    address: '789 Green Valley, Portland, OR 97201',
    rating: 4.2,
    active: true,
    ordersCount: 87,
    lastUpdated: DateTime(2026, 2, 16),
  ),
  Supplier(
    id: '4',
    name: 'Premium Snacks Inc',
    contactName: 'Emily Davis',
    category: 'Snacks',
    phone: '+1-555-0104',
    email: 'emily@premiumsnacks.com',
    address: '321 Snack Ave, Chicago, IL 60601',
    rating: 3.9,
    active: false,
    ordersCount: 12,
    lastUpdated: DateTime(2026, 2, 12),
  ),
];
