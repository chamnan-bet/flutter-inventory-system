import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SalesOrdersPage extends StatefulWidget {
  const SalesOrdersPage({super.key});

  @override
  State<SalesOrdersPage> createState() => _SalesOrdersPageState();
}

class _SalesOrdersPageState extends State<SalesOrdersPage> {
  static const _kStorageKey = 'sales_orders_v2';

  final _searchCtrl = TextEditingController();

  final List<_StatusTab> _tabs = const [
    _StatusTab('All', null),
    _StatusTab('Pending', OrderStatus.pending),
    _StatusTab('Processing', OrderStatus.processing),
    _StatusTab('Completed', OrderStatus.completed),
    _StatusTab('Cancelled', OrderStatus.cancelled),
  ];
  int _activeTabIndex = 0;

  List<SalesOrder> _orders = [];
  bool _loading = true;

  // ====== Derived Metrics ======
  double get totalRevenue => _orders
      .where((o) => o.status == OrderStatus.completed)
      .fold(0.0, (a, b) => a + b.total);

  int get completedCount =>
      _orders.where((o) => o.status == OrderStatus.completed).length;
  int get processingCount =>
      _orders.where((o) => o.status == OrderStatus.processing).length;
  int get pendingCount =>
      _orders.where((o) => o.status == OrderStatus.pending).length;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ====== Storage ======
  Future<void> _loadOrders() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final raw = sp.getString(_kStorageKey);
      if (raw == null || raw.isEmpty) {
        _orders = _seedOrders();
        await _save();
      } else {
        final list = jsonDecode(raw);
        _orders = (list as List)
            .map(
              (e) => SalesOrder.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .toList();
        _orders.sort((a, b) => b.orderDate.compareTo(a.orderDate));
      }
    } catch (_) {
      _orders = _seedOrders();
    }
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(
      _kStorageKey,
      jsonEncode(_orders.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> _resetDemo() async {
    setState(() => _loading = true);
    _orders = _seedOrders();
    await _save();
    setState(() => _loading = false);
  }

  // ====== Actions ======
  Future<void> _newOrder() async {
    final created = await _openOrderForm();
    if (created != null) {
      setState(() => _orders.insert(0, created));
      await _save();
      _toast('New order created: ${created.code}');
    }
  }

  Future<void> _processOrder(int index) async {
    final o = _orders[index];
    if (o.status != OrderStatus.pending) return;
    setState(() => _orders[index] = o.copyWith(status: OrderStatus.processing));
    await _save();
    _toast('${o.code} set to Processing');
  }

  Future<void> _completeOrder(int index) async {
    final o = _orders[index];
    if (o.status != OrderStatus.processing) return;
    setState(() => _orders[index] = o.copyWith(status: OrderStatus.completed));
    await _save();
    _toast('${o.code} marked as Completed');
  }

  Future<void> _cancelOrder(int index) async {
    final o = _orders[index];
    if (o.status == OrderStatus.completed || o.status == OrderStatus.cancelled)
      return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Order'),
        content: Text('Cancel ${o.code}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel Order'),
          ),
        ],
      ),
    );
    if (ok == true) {
      setState(
        () => _orders[index] = o.copyWith(status: OrderStatus.cancelled),
      );
      await _save();
      _toast('${o.code} cancelled');
    }
  }

  // ====== UI ======
  @override
  Widget build(BuildContext context) {
    final textGrey = const Color(0xFF7A7A7A);

    final q = _searchCtrl.text.trim().toLowerCase();
    final filter = _tabs[_activeTabIndex].status;

    final list = _orders.where((o) {
      final byStatus = filter == null || o.status == filter;
      final byQuery =
          q.isEmpty ||
          o.code.toLowerCase().contains(q) ||
          o.customerName.toLowerCase().contains(q);
      return byStatus && byQuery;
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
                // Header + New Order
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Sales Orders',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Manage customer orders',
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
                      onPressed: _newOrder,
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text(
                        'New Order',
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
                      child: _MetricTile(
                        icon: Icons.payments_outlined,
                        title: 'Total Revenue',
                        value: '\$${totalRevenue.toStringAsFixed(2)}',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _MetricTile(
                        icon: Icons.check_circle_outline,
                        title: 'Completed Orders',
                        value: '$completedCount',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _MetricTile(
                        icon: Icons.hourglass_top_outlined,
                        title: 'Processing',
                        value: '$processingCount',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _MetricTile(
                        icon: Icons.pending_actions_outlined,
                        title: 'Pending',
                        value: '$pendingCount',
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
                    hintText: 'Search orders...',
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
                    focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide(
                        color: Color(0xFF3B47FF),
                        width: 1.2,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Status chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(_tabs.length, (i) {
                      final selected = i == _activeTabIndex;
                      return Padding(
                        padding: EdgeInsets.only(
                          right: i == _tabs.length - 1 ? 0 : 8,
                        ),
                        child: ChoiceChip(
                          label: Text(_tabs[i].label),
                          selected: selected,
                          onSelected: (_) =>
                              setState(() => _activeTabIndex = i),
                          selectedColor: const Color(0xFF3B47FF),
                          labelStyle: TextStyle(
                            color: selected ? Colors.white : Colors.black87,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                          backgroundColor: const Color(0xFFF3F4F6),
                          side: BorderSide(
                            color: selected
                                ? const Color(0xFF3B47FF)
                                : Colors.transparent,
                          ),
                        ),
                      );
                    }),
                  ),
                ),

                const SizedBox(height: 12),

                // Orders List (with inline actions)
                if (list.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'No orders found.',
                      style: TextStyle(color: Color(0xFF7A7A7A)),
                    ),
                  )
                else
                  ...list.map((o) {
                    final idx = _orders.indexOf(o);
                    return _OrderCard(
                      order: o,
                      onView: () => _openOrderDetail(idx),
                      onProcess: () => _processOrder(idx),
                      onComplete: () => _completeOrder(idx),
                      onCancel: () => _cancelOrder(idx),
                    );
                  }),

                const SizedBox(height: 12),

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

      // Bottom nav (Admin/More is index 4; go back to Admin menu)
      bottomNavigationBar: NavigationBar(
        selectedIndex: 4,
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

  // ====== Order Detail Bottom Sheet ======
  Future<void> _openOrderDetail(int index) async {
    final o = _orders[index];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final total = o.total;
        // final actions = _actionsFor(o.status);

        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      o.code,
                      style: const TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _StatusBadge(status: o.status),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                o.customerName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              if (o.address.isNotEmpty)
                Text(
                  o.address,
                  style: const TextStyle(color: Color(0xFF7A7A7A)),
                ),
              const SizedBox(height: 10),

              ...o.items.map(
                (it) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(child: Text('${it.qty}x ${it.product}')),
                      Text(
                        '\$${(it.price * it.qty).toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Total',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text(
                    '\$${total.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Order Date: ${o.orderDate.year}-${_two(o.orderDate.month)}-${_two(o.orderDate.day)}',
                style: const TextStyle(color: Color(0xFF7A7A7A)),
              ),
              const SizedBox(height: 12),

              //   if (actions.isNotEmpty)
              //     // Row(
              //       children:
              //           actions
              //               .map((a) {
              //                 switch (a) {
              //                   case _OrderAction.process:
              //                     return Expanded(
              //                       child: OutlinedButton(
              //                         onPressed: () {
              //                           Navigator.pop(ctx);
              //                           _processOrder(index);
              //                         },
              //                         child: const Text('Process Order'),
              //                       ),
              //                     );
              //                   case _OrderAction.complete:
              //                     return Expanded(
              //                       child: ElevatedButton(
              //                         onPressed: () {
              //                           Navigator.pop(ctx);
              //                           _completeOrder(index);
              //                         },
              //                         style: ElevatedButton.styleFrom(
              //                           backgroundColor: const Color(0xFF10B981),
              //                           foregroundColor: Colors.white,
              //                         ),
              //                         child: const Text('Mark as Completed'),
              //                       ),
              //                     );
              //                   case _OrderAction.cancel:
              //                     return Expanded(
              //                       child: OutlinedButton(
              //                         onPressed: () {
              //                           Navigator.pop(ctx);
              //                           _cancelOrder(index);
              //                         },
              //                         style: OutlinedButton.styleFrom(
              //                           side: const BorderSide(
              //                             color: Color(0xFFD32F2F),
              //                           ),
              //                           foregroundColor: const Color(0xFFD32F2F),
              //                         ),
              //                         child: const Text('Cancel'),
              //                       ),
              //                     );
              //                 }
              //               })
              //               .expand((w) sync* {
              //                 yield w;
              //                 yield const SizedBox(width: 10);
              //               })
              //               .toList()
              //             ..removeLast(),
              //     ),
            ],
          ),
        );
      },
    );
  }

  // List<_OrderAction> _actionsFor(OrderStatus s) {
  //   switch (s) {
  //     case OrderStatus.pending:
  //       return const [_OrderAction.process, _OrderAction.cancel];
  //     case OrderStatus.processing:
  //       return const [_OrderAction.complete, _OrderAction.cancel];
  //     case OrderStatus.completed:
  //     case OrderStatus.cancelled:
  //       return const [];
  //   }
  // }

  // ====== New Order Bottom Sheet ======
  Future<SalesOrder?> _openOrderForm() async {
    final formKey = GlobalKey<FormState>();
    final customer = TextEditingController();
    final address = TextEditingController();
    final note = TextEditingController();

    final List<_CatalogItem> catalog = const [
      _CatalogItem('Premium Coffee Beans', 39.90),
      _CatalogItem('Chocolate Bars', 9.90),
      _CatalogItem('Organic Green Tea', 23.50),
      _CatalogItem('Milk Powder', 17.80),
      _CatalogItem('Pasta Spaghetti', 13.50),
    ];

    _CatalogItem? selected;
    final qtyCtrl = TextEditingController(text: '1');
    final List<OrderItem> items = [];
    SalesOrder? result;

    void addLine(StateSetter setLocal) {
      final q = int.tryParse(qtyCtrl.text.trim());
      if (selected == null) {
        _toast('Select a product first');
        return;
      }
      if (q == null || q <= 0) {
        _toast('Quantity must be positive');
        return;
      }
      items.add(
        OrderItem(product: selected!.name, price: selected!.price, qty: q),
      );
      qtyCtrl.text = '1';
      selected = null;
      setLocal(() {});
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            final total = items.fold(0.0, (a, b) => a + b.price * b.qty);

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
                      const Text(
                        'New Order',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),

                      _Labeled(
                        'Customer Name *',
                        TextFormField(
                          controller: customer,
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Required' : null,
                          decoration: _inputDeco('e.g., Carol Martinez'),
                        ),
                      ),
                      const SizedBox(height: 10),

                      _Labeled(
                        'Address',
                        TextFormField(
                          controller: address,
                          decoration: _inputDeco('Optional delivery address'),
                        ),
                      ),
                      const SizedBox(height: 10),

                      _Labeled(
                        'Add Items',
                        Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: DropdownButtonFormField<_CatalogItem>(
                                    value: selected,
                                    items: catalog
                                        .map(
                                          (c) => DropdownMenuItem(
                                            value: c,
                                            child: Text(
                                              '${c.name}  (\$${c.price})',
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (v) =>
                                        setLocal(() => selected = v),
                                    decoration: _inputDeco('Select product'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    controller: qtyCtrl,
                                    keyboardType: TextInputType.number,
                                    decoration: _inputDeco('Qty'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  height: 48,
                                  child: FilledButton(
                                    onPressed: () => addLine(setLocal),
                                    child: const Text('Add'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (items.isEmpty)
                              const Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'No items added yet',
                                  style: TextStyle(color: Color(0xFF7A7A7A)),
                                ),
                              )
                            else
                              Column(
                                children: items
                                    .asMap()
                                    .entries
                                    .map(
                                      (e) => Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 4,
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                '${e.value.qty}x ${e.value.product}',
                                              ),
                                            ),
                                            Text(
                                              '\$${(e.value.price * e.value.qty).toStringAsFixed(2)}',
                                            ),
                                            IconButton(
                                              onPressed: () {
                                                items.removeAt(e.key);
                                                setLocal(() {});
                                              },
                                              icon: const Icon(
                                                Icons.close,
                                                size: 18,
                                                color: Colors.red,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      _Labeled(
                        'Notes',
                        TextFormField(
                          controller: note,
                          minLines: 1,
                          maxLines: 2,
                          decoration: _inputDeco('Optional order notes'),
                        ),
                      ),
                      const SizedBox(height: 10),

                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Total',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                          Text(
                            '\$${total.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
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
                                if (items.isEmpty) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    const SnackBar(
                                      content: Text('Add at least one item'),
                                    ),
                                  );
                                  return;
                                }
                                final order = SalesOrder(
                                  id: DateTime.now().millisecondsSinceEpoch
                                      .toString(),
                                  code: _generateOrderCode(_orders),
                                  customerName: customer.text.trim(),
                                  address: address.text.trim(),
                                  status: OrderStatus.pending,
                                  items: List.of(items),
                                  orderDate: DateTime.now(),
                                  note: note.text.trim(),
                                );
                                result = order;
                                Navigator.pop(ctx);
                              },
                              child: const Text('Create Order'),
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
      },
    );

    return result;
  }

  // ====== Helpers ======
  // List<_OrderAction> _actionsFor(OrderStatus s) {
  //   switch (s) {
  //     case OrderStatus.pending:
  //       return const [_OrderAction.process, _OrderAction.cancel];
  //     case OrderStatus.processing:
  //       return const [_OrderAction.complete, _OrderAction.cancel];
  //     case OrderStatus.completed:
  //     case OrderStatus.cancelled:
  //       return const [];
  //   }
  // }

  String _generateOrderCode(List<SalesOrder> orders) {
    final year = DateTime.now().year;
    final sameYear = orders.where((o) => o.code.startsWith('ORD-$year-'));
    int max = 0;
    for (final o in sameYear) {
      final parts = o.code.split('-');
      if (parts.length == 3) {
        max = mathMax(max, int.tryParse(parts[2]) ?? 0);
      }
    }
    final next = (max + 1).toString().padLeft(3, '0');
    return 'ORD-$year-$next';
  }

  void _toast(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}

// ====== Widgets ======

class _OrderCard extends StatelessWidget {
  final SalesOrder order;
  final VoidCallback onView;
  final VoidCallback onProcess;
  final VoidCallback onComplete;
  final VoidCallback onCancel;

  const _OrderCard({
    required this.order,
    required this.onView,
    required this.onProcess,
    required this.onComplete,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final textGrey = const Color(0xFF7A7A7A);

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
          // Header row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(
                      order.code,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 8),
                    _StatusBadge(status: order.status),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Details',
                visualDensity: VisualDensity.compact,
                onPressed: onView,
                icon: const Icon(Icons.remove_red_eye_outlined, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 2),

          Text(
            order.customerName,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          if (order.address.isNotEmpty)
            Text(
              order.address,
              style: TextStyle(color: textGrey, fontSize: 12),
            ),

          const SizedBox(height: 6),

          // Show up to 2 line-items (name + price) like mock
          ...order.items
              .take(2)
              .map(
                (it) => Row(
                  children: [
                    Expanded(child: Text('${it.qty}x ${it.product}')),
                    Text(
                      '\$${it.price.toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.black87),
                    ),
                  ],
                ),
              ),
          if (order.items.length > 2)
            Text(
              '+ ${order.items.length - 2} more item(s)',
              style: TextStyle(color: textGrey, fontSize: 12),
            ),

          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: Text(
                  'Order Date: ${order.orderDate.year}-${_two(order.orderDate.month)}-${_two(order.orderDate.day)}',
                  style: TextStyle(color: textGrey),
                ),
              ),
              Text(
                '\$${order.total.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Inline actions based on status (as in screenshot)
          Row(
            children: [
              if (order.status == OrderStatus.processing)
                Expanded(
                  child: ElevatedButton(
                    onPressed: onComplete,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Mark as Completed'),
                  ),
                ),
              if (order.status == OrderStatus.processing)
                const SizedBox(width: 8),

              if (order.status == OrderStatus.pending)
                Expanded(
                  child: ElevatedButton(
                    onPressed: onProcess,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B47FF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Process Order'),
                  ),
                ),
              if (order.status == OrderStatus.pending) const SizedBox(width: 8),

              if (order.status == OrderStatus.pending ||
                  order.status == OrderStatus.processing)
                Expanded(
                  child: OutlinedButton(
                    onPressed: onCancel,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFD32F2F)),
                      foregroundColor: const Color(0xFFD32F2F),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _MetricTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 66,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
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

class _StatusBadge extends StatelessWidget {
  final OrderStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final c = status.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: c.fg,
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ====== Models ======

enum OrderStatus { pending, processing, completed, cancelled }

extension on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'pending';
      case OrderStatus.processing:
        return 'processing';
      case OrderStatus.completed:
        return 'completed';
      case OrderStatus.cancelled:
        return 'cancelled';
    }
  }

  _BadgeColors get colors {
    switch (this) {
      case OrderStatus.pending:
        return const _BadgeColors(Color(0xFFE3F2FD), Color(0xFF1E88E5));
      case OrderStatus.processing:
        return const _BadgeColors(Color(0xFFEDE7F6), Color(0xFF7C4DFF));
      case OrderStatus.completed:
        return const _BadgeColors(Color(0xFFE8F5E9), Color(0xFF2E7D32));
      case OrderStatus.cancelled:
        return const _BadgeColors(Color(0xFFFFEBEE), Color(0xFFC62828));
    }
  }
}

class _BadgeColors {
  final Color bg;
  final Color fg;
  const _BadgeColors(this.bg, this.fg);
}

class SalesOrder {
  final String id;
  final String code;
  final String customerName;
  final String address;
  final OrderStatus status;
  final List<OrderItem> items;
  final DateTime orderDate;
  final String note;

  const SalesOrder({
    required this.id,
    required this.code,
    required this.customerName,
    required this.address,
    required this.status,
    required this.items,
    required this.orderDate,
    required this.note,
  });

  double get total => items.fold(0.0, (a, b) => a + b.price * b.qty);

  SalesOrder copyWith({
    String? id,
    String? code,
    String? customerName,
    String? address,
    OrderStatus? status,
    List<OrderItem>? items,
    DateTime? orderDate,
    String? note,
  }) {
    return SalesOrder(
      id: id ?? this.id,
      code: code ?? this.code,
      customerName: customerName ?? this.customerName,
      address: address ?? this.address,
      status: status ?? this.status,
      items: items ?? this.items,
      orderDate: orderDate ?? this.orderDate,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'customerName': customerName,
    'address': address,
    'status': status.label,
    'items': items.map((e) => e.toJson()).toList(),
    'orderDate': orderDate.toIso8601String(),
    'note': note,
  };

  factory SalesOrder.fromJson(Map<String, dynamic> json) {
    final s = (json['status'] ?? 'pending') as String;
    final status = OrderStatus.values.firstWhere(
      (e) => e.label == s,
      orElse: () => OrderStatus.pending,
    );
    final it = (json['items'] as List)
        .map((e) => OrderItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    return SalesOrder(
      id: (json['id'] ?? '') as String,
      code: (json['code'] ?? '') as String,
      customerName: (json['customerName'] ?? '') as String,
      address: (json['address'] ?? '') as String,
      status: status,
      items: it,
      orderDate: DateTime.parse(json['orderDate'] as String),
      note: (json['note'] ?? '') as String,
    );
  }
}

class OrderItem {
  final String product;
  final double price;
  final int qty;

  const OrderItem({
    required this.product,
    required this.price,
    required this.qty,
  });

  Map<String, dynamic> toJson() => {
    'product': product,
    'price': price,
    'qty': qty,
  };

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
    product: (json['product'] ?? '') as String,
    price: (json['price'] as num).toDouble(),
    qty: (json['qty'] as num).toInt(),
  );
}

class _CatalogItem {
  final String name;
  final double price;
  const _CatalogItem(this.name, this.price);
}

class _StatusTab {
  final String label;
  final OrderStatus? status;
  const _StatusTab(this.label, this.status);
}

// ====== Seeds & Utils ======
List<SalesOrder> _seedOrders() => [
  SalesOrder(
    id: 'o1',
    code: 'ORD-2026-001',
    customerName: 'Alice Williams',
    address: '45 Park Ave, NY',
    status: OrderStatus.completed,
    items: const [
      OrderItem(product: 'Premium Coffee Beans', price: 39.90, qty: 2),
      OrderItem(product: 'Chocolate Bars', price: 9.90, qty: 3),
    ],
    orderDate: DateTime(2026, 2, 15),
    note: '',
  ),
  SalesOrder(
    id: 'o2',
    code: 'ORD-2026-002',
    customerName: 'Bob Johnson',
    address: '86 Posta',
    status: OrderStatus.processing,
    items: const [
      OrderItem(product: 'Organic Green Tea', price: 23.50, qty: 3),
      OrderItem(product: 'Milk Powder', price: 17.80, qty: 1),
    ],
    orderDate: DateTime(2026, 2, 18),
    note: '',
  ),
  SalesOrder(
    id: 'o3',
    code: 'ORD-2026-003',
    customerName: 'Carol Martinez',
    address: '86 Posta',
    status: OrderStatus.pending,
    items: const [OrderItem(product: 'Pasta Spaghetti', price: 13.50, qty: 2)],
    orderDate: DateTime(2026, 2, 19),
    note: '',
  ),
  SalesOrder(
    id: 'o4',
    code: 'ORD-2026-004',
    customerName: 'David Lee',
    address: '30 Premium Blvd',
    status: OrderStatus.completed,
    items: const [
      OrderItem(product: 'Premium Coffee Beans', price: 39.90, qty: 10),
      OrderItem(product: 'Chocolate Bars', price: 9.90, qty: 8),
    ],
    orderDate: DateTime(2026, 2, 17),
    note: '',
  ),
  SalesOrder(
    id: 'o5',
    code: 'ORD-2026-005',
    customerName: 'Nina West',
    address: '8 Rose Avenue',
    status: OrderStatus.cancelled,
    items: const [
      OrderItem(product: 'Organic Green Tea', price: 23.50, qty: 3),
    ],
    orderDate: DateTime(2026, 2, 16),
    note: '',
  ),
];

String _two(int n) => n.toString().padLeft(2, '0');

int mathMax(int a, int b) => a > b ? a : b;

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
