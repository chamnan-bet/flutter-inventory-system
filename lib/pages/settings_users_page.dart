import 'package:flutter/material.dart';
import '../services/settings_store.dart';

class SettingsUsersPage extends StatefulWidget {
  const SettingsUsersPage({super.key});
  @override
  State<SettingsUsersPage> createState() => _SettingsUsersPageState();
}

class _SettingsUsersPageState extends State<SettingsUsersPage> {
  bool _loading = true;
  List<UserModel> _users = [];
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
    _users = await SettingsStore.loadUsers();
    setState(() => _loading = false);
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _add() async {
    final u = await _form();
    if (u != null) {
      setState(() => _users.insert(0, u));
      await SettingsStore.saveUsers(_users);
      _snack('User added');
    }
  }

  Future<void> _edit(int i) async {
    final u = await _form(existing: _users[i]);
    if (u != null) {
      setState(() => _users[i] = u.copyWith(lastUpdated: DateTime.now()));
      await SettingsStore.saveUsers(_users);
      _snack('User updated');
    }
  }

  Future<void> _toggle(int i) async {
    final u = _users[i];
    setState(
      () => _users[i] = u.copyWith(
        active: !u.active,
        lastUpdated: DateTime.now(),
      ),
    );
    await SettingsStore.saveUsers(_users);
  }

  Future<void> _delete(int i) async {
    final u = _users[i];
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Delete "${u.fullName}"?'),
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
      setState(() => _users.removeAt(i));
      await SettingsStore.saveUsers(_users);
      _snack('User deleted');
    }
  }

  @override
  Widget build(BuildContext context) {
    final textGrey = const Color(0xFF7A7A7A);
    final q = _search.text.trim().toLowerCase();
    final list = _users
        .where(
          (u) =>
              q.isEmpty ||
              u.fullName.toLowerCase().contains(q) ||
              u.email.toLowerCase().contains(q) ||
              u.role.toLowerCase().contains(q),
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

                const _Tabs(selected: 1),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${_users.length} total users',
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
                        'Add User',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  decoration: _searchDeco('Search users...'),
                ),
                const SizedBox(height: 10),

                ...list.map((u) {
                  final idx = _users.indexOf(u);
                  final badgeBg = u.active
                      ? const Color(0xFFE8F5E9)
                      : const Color(0xFFFFEBEE);
                  final badgeFg = u.active
                      ? const Color(0xFF2E7D32)
                      : const Color(0xFFC62828);
                  final badgeTx = u.active ? 'active' : 'inactive';
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
                                    u.fullName,
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
                                      color: badgeBg,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Text(
                                      badgeTx,
                                      style: TextStyle(
                                        color: badgeFg,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => _toggle(idx),
                              visualDensity: VisualDensity.compact,
                              icon: Icon(
                                u.active ? Icons.toggle_on : Icons.toggle_off,
                                color: const Color(0xFF3B47FF),
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
                          u.email,
                          style: const TextStyle(color: Color(0xFF7A7A7A)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          u.role,
                          style: const TextStyle(
                            color: Color(0xFF7A7A7A),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'Updated: ${u.lastUpdated.year}-${_two(u.lastUpdated.month)}-${_two(u.lastUpdated.day)}',
                            style: const TextStyle(
                              color: Color(0xFF9CA3AF),
                              fontSize: 12,
                            ),
                          ),
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
  Future<UserModel?> _form({UserModel? existing}) async {
    final formKey = GlobalKey<FormState>();
    final name = TextEditingController(text: existing?.fullName ?? '');
    final email = TextEditingController(text: existing?.email ?? '');
    final role = TextEditingController(text: existing?.role ?? 'Staff');
    bool active = existing?.active ?? true;

    UserModel? result;
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
            child: StatefulBuilder(
              builder: (ctx, setLocal) {
                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _handle(),
                      Text(
                        existing == null ? 'Add User' : 'Edit User',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _Labeled(
                        'Full Name *',
                        TextFormField(
                          controller: name,
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Required' : null,
                          decoration: _input('e.g., Chhen Vichheka'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _Labeled(
                        'Email *',
                        TextFormField(
                          controller: email,
                          validator: (v) => v == null || !v.contains('@')
                              ? 'Valid email required'
                              : null,
                          decoration: _input('user@example.com'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _Labeled(
                        'Role',
                        TextFormField(
                          controller: role,
                          decoration: _input('Staff / Manager / Admin'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Text('Active'),
                          const SizedBox(width: 8),
                          Switch(
                            value: active,
                            onChanged: (v) => setLocal(() => active = v),
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
                              onPressed: () {
                                if (!formKey.currentState!.validate()) return;
                                result = UserModel(
                                  id:
                                      existing?.id ??
                                      DateTime.now().millisecondsSinceEpoch
                                          .toString(),
                                  fullName: name.text.trim(),
                                  email: email.text.trim(),
                                  role: role.text.trim().isEmpty
                                      ? 'Staff'
                                      : role.text.trim(),
                                  active: active,
                                  lastUpdated: DateTime.now(),
                                );
                                Navigator.pop(ctx);
                              },
                              child: Text(
                                existing == null ? 'Add User' : 'Save Changes',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
    return result;
  }
}

/* tiny UI helpers */
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
            chip(Icons.group_outlined, 'Users', selected == 1, () => {}),
            const SizedBox(width: 8),
            chip(
              Icons.category_outlined,
              'Categories',
              selected == 2,
              () => Navigator.pushReplacementNamed(
                context,
                '/settings/categories',
              ),
            ),
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

String _two(int n) => n.toString().padLeft(2, '0');
