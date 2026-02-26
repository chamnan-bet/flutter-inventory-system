import 'package:flutter/material.dart';
import '../services/settings_store.dart';

class SettingsGeneralPage extends StatefulWidget {
  const SettingsGeneralPage({super.key});
  @override
  State<SettingsGeneralPage> createState() => _SettingsGeneralPageState();
}

class _SettingsGeneralPageState extends State<SettingsGeneralPage> {
  Profile? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _profile = await SettingsStore.loadProfile();
    setState(() => _loading = false);
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    final textGrey = const Color(0xFF7A7A7A);

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

                const _Tabs(selected: 0),

                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: _panel(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Profile',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 10),
                      _kv(Icons.person_outline, 'Name', _profile!.name),
                      _kv(Icons.email_outlined, 'Email', _profile!.email),
                      _kv(Icons.phone_outlined, 'Phone', _profile!.phone),
                      _kv(
                        Icons.admin_panel_settings_outlined,
                        'Role',
                        _profile!.role,
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.icon(
                          onPressed: _editProfile,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF3B47FF),
                          ),
                          icon: const Icon(Icons.edit, color: Colors.white),
                          label: const Text(
                            'Edit Profile',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
      bottomNavigationBar: _bottomNav(context),
    );
  }

  Future<void> _editProfile() async {
    final p = _profile!;
    final formKey = GlobalKey<FormState>();
    final name = TextEditingController(text: p.name);
    final email = TextEditingController(text: p.email);
    final phone = TextEditingController(text: p.phone);
    final role = TextEditingController(text: p.role);

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
                  const Text(
                    'Edit Profile',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  _Labeled(
                    'Name *',
                    TextFormField(
                      controller: name,
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                      decoration: _input('Admin User'),
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
                      decoration: _input('admin@inventorypro.app'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _Labeled(
                    'Phone',
                    TextFormField(
                      controller: phone,
                      decoration: _input('+855-000-000'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _Labeled(
                    'Role',
                    TextFormField(
                      controller: role,
                      decoration: _input('Administrator'),
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
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;
                            final updated = p.copyWith(
                              name: name.text.trim(),
                              email: email.text.trim(),
                              phone: phone.text.trim(),
                              role: role.text.trim().isEmpty
                                  ? 'Administrator'
                                  : role.text.trim(),
                            );
                            await SettingsStore.saveProfile(updated);
                            if (!mounted) return;
                            setState(() => _profile = updated);
                            Navigator.pop(ctx);
                            _snack('Profile updated');
                          },
                          child: const Text('Save'),
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
  }
}

/* ----------- tiny helpers (local) ----------- */
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
              () => {},
            ), // here
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
Widget _kv(IconData ic, String k, String v) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 6),
  child: Row(
    children: [
      Icon(ic, color: const Color(0xFF6B7280)),
      const SizedBox(width: 10),
      Expanded(
        child: Text(k, style: const TextStyle(color: Color(0xFF6B7280))),
      ),
      Text(v, style: const TextStyle(fontWeight: FontWeight.w700)),
    ],
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
