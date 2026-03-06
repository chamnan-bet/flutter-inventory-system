import 'package:flutter/material.dart';
import '../services/settings_store.dart';

class SettingsCategoriesPage extends StatefulWidget {
  const SettingsCategoriesPage({super.key});
  @override
  State<SettingsCategoriesPage> createState() => _SettingsCategoriesPageState();
}

class _SettingsCategoriesPageState extends State<SettingsCategoriesPage> {
  bool _loading = true;
  List<CategoryModel> _cats = [];
  final _search = TextEditingController();
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    _cats = await SettingsStore.loadCategories();
    setState(() => _loading = false);
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _add() async {
    final c = await _form();
    if (c != null) {
      setState(() => _cats.insert(0, c));
      await SettingsStore.saveCategories(_cats);
      _snack('Category added');
    }
  }

  Future<void> _edit(int i) async {
    final c = await _form(existing: _cats[i]);
    if (c != null) {
      setState(() => _cats[i] = c.copyWith(lastUpdated: DateTime.now()));
      await SettingsStore.saveCategories(_cats);
      _snack('Category updated');
    }
  }

  Future<void> _delete(int i) async {
    final c = _cats[i];
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Delete "${c.name}"?'),
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
      setState(() => _cats.removeAt(i));
      await SettingsStore.saveCategories(_cats);
      _snack('Category deleted');
    }
  }

  @override
  Widget build(BuildContext context) {
    final textGrey = const Color(0xFF7A7A7A);
    final q = _search.text.trim().toLowerCase();
    final list = _cats
        .where(
          (c) =>
              q.isEmpty ||
              c.name.toLowerCase().contains(q) ||
              c.description.toLowerCase().contains(q),
        )
        .toList();

    return Scaffold(
      appBar: _appBar(context),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                const Text(
                  'Settings',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  'Manage system configuration',
                  style: TextStyle(color: textGrey, fontSize: 13),
                ),
                const SizedBox(height: 12),

                const _Tabs(selected: 2),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${_cats.length} total categories',
                        style: const TextStyle(color: Color(0xFF7A7A7A)),
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: _add,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF3B47FF),
                      ),
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text(
                        'Add Category',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  decoration: _searchDeco('Search categories...'),
                ),
                const SizedBox(height: 10),

                ...list.map((c) {
                  final idx = _cats.indexOf(c);
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(14),
                    decoration: _panel(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Wrap(
                                spacing: 8,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    c.name,
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
                                      color: const Color(0xFFEAF0FF),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Text(
                                      '${c.productCount} products',
                                      style: const TextStyle(
                                        color: Color(0xFF3B47FF),
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => _edit(idx),
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(
                                Icons.edit,
                                color: Color(0xFF3B47FF),
                              ),
                            ),
                            IconButton(
                              onPressed: () => _delete(idx),
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Color(0xFFD32F2F),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          c.description.isEmpty ? '—' : c.description,
                          style: const TextStyle(color: Color(0xFF7A7A7A)),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
      bottomNavigationBar: _bottomNav(context),
    );
  }

  // bottom sheet form
  Future<CategoryModel?> _form({CategoryModel? existing}) async {
    final formKey = GlobalKey<FormState>();
    final name = TextEditingController(text: existing?.name ?? '');
    final desc = TextEditingController(text: existing?.description ?? '');
    final prod = TextEditingController(
      text: (existing?.productCount ?? 0).toString(),
    );

    CategoryModel? result;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
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
                  _handle(),
                  Text(
                    existing == null ? 'Add Category' : 'Edit Category',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _Labeled(
                    'Name *',
                    TextFormField(
                      controller: name,
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                      decoration: _input('e.g., Beverages'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _Labeled(
                    'Description',
                    TextFormField(
                      controller: desc,
                      minLines: 1,
                      maxLines: 2,
                      decoration: _input('Coffee, tea, and drinks'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _Labeled(
                    'Products Count',
                    TextFormField(
                      controller: prod,
                      keyboardType: TextInputType.number,
                      decoration: _input('e.g., 5'),
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
                          onPressed: () {
                            if (!formKey.currentState!.validate()) return;
                            final pc = int.tryParse(prod.text.trim()) ?? 0;
                            result = CategoryModel(
                              id:
                                  existing?.id ??
                                  DateTime.now().millisecondsSinceEpoch
                                      .toString(),
                              name: name.text.trim(),
                              description: desc.text.trim(),
                              productCount: pc,
                              lastUpdated: DateTime.now(),
                            );
                            Navigator.pop(ctx);
                          },
                          child: Text(
                            existing == null ? 'Add Category' : 'Save Changes',
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
}

/* tiny UI helpers same style */
PreferredSizeWidget _appBar(BuildContext context) => AppBar(
  backgroundColor: Colors.white,
  elevation: .6,
  surfaceTintColor: Colors.white,
  titleSpacing: 16,
  leading: IconButton(
    icon: const Icon(Icons.menu),
    onPressed: () => ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Drawer coming soon…'))),
  ),
  title: const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'InventoryPro',
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w700,
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
    SizedBox(width: 8),
  ],
);
NavigationBar _bottomNav(BuildContext context) => NavigationBar(
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
    NavigationDestination(icon: Icon(Icons.swap_vert_rounded), label: 'Stock'),
    NavigationDestination(
      icon: Icon(Icons.notifications_none),
      label: 'Alerts',
    ),
    NavigationDestination(icon: Icon(Icons.menu), label: 'More'),
  ],
);

class _Tabs extends StatelessWidget {
  final int selected;
  const _Tabs({required this.selected});
  @override
  Widget build(BuildContext context) {
    Widget chip(IconData ic, String t, bool sel, VoidCallback onTap) {
      final bg = sel ? const Color(0xFF3B47FF) : const Color(0xFFF3F4F6);
      final fg = sel ? Colors.white : Colors.black87;
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Icon(ic, size: 18, color: fg),
              const SizedBox(width: 6),
              Text(
                t,
                style: TextStyle(color: fg, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            chip(
              Icons.settings_outlined,
              'General',
              selected == 0,
              () =>
                  Navigator.pushReplacementNamed(context, '/settings/general'),
            ),
            const SizedBox(width: 8),
            chip(
              Icons.group_outlined,
              'Users',
              selected == 1,
              () => Navigator.pushReplacementNamed(context, '/settings/users'),
            ),
            const SizedBox(width: 8),
            chip(
              Icons.category_outlined,
              'Categories',
              selected == 2,
              () => {},
            ), // here
          ],
        ),
      ),
    );
  }
}

BoxDecoration _panel() => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(12),
  border: Border.all(color: Colors.black12),
  boxShadow: const [
    BoxShadow(color: Color(0x11000000), blurRadius: 8, offset: Offset(0, 2)),
  ],
);
InputDecoration _searchDeco(String hint) => InputDecoration(
  hintText: hint,
  prefixIcon: const Icon(Icons.search),
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
Widget _handle() => Center(
  child: Container(
    width: 40,
    height: 4,
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: Colors.black26,
      borderRadius: BorderRadius.circular(2),
    ),
  ),
);
InputDecoration _input(String hint) => InputDecoration(
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
  Widget build(BuildContext c) => Column(
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
