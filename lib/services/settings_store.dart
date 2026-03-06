import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

const _kProfile = 'settings_profile_v1';
const _kUsers = 'settings_users_v1';
const _kCategories = 'settings_categories_v1';

/* ======================= MODELS ======================= */

class Profile {
  final String name, email, phone, role;
  const Profile({
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
  });

  Profile copyWith({
    String? name,
    String? email,
    String? phone,
    String? role,
  }) => Profile(
    name: name ?? this.name,
    email: email ?? this.email,
    phone: phone ?? this.phone,
    role: role ?? this.role,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    'phone': phone,
    'role': role,
  };
  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
    name: (j['name'] ?? '') as String,
    email: (j['email'] ?? '') as String,
    phone: (j['phone'] ?? '') as String,
    role: (j['role'] ?? '') as String,
  );
}

class UserModel {
  final String id, fullName, email, role;
  final bool active;
  final DateTime lastUpdated;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.active,
    required this.lastUpdated,
  });

  UserModel copyWith({
    String? fullName,
    String? email,
    String? role,
    bool? active,
    DateTime? lastUpdated,
  }) => UserModel(
    id: id,
    fullName: fullName ?? this.fullName,
    email: email ?? this.email,
    role: role ?? this.role,
    active: active ?? this.active,
    lastUpdated: lastUpdated ?? this.lastUpdated,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'fullName': fullName,
    'email': email,
    'role': role,
    'active': active,
    'lastUpdated': lastUpdated.toIso8601String(),
  };
  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
    id: (j['id'] ?? '') as String,
    fullName: (j['fullName'] ?? '') as String,
    email: (j['email'] ?? '') as String,
    role: (j['role'] ?? 'Staff') as String,
    active: (j['active'] ?? true) as bool,
    lastUpdated: DateTime.parse(
      (j['lastUpdated'] ?? DateTime.now().toIso8601String()) as String,
    ),
  );
}

class CategoryModel {
  final String id, name, description;
  final int productCount;
  final DateTime lastUpdated;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.description,
    required this.productCount,
    required this.lastUpdated,
  });

  CategoryModel copyWith({
    String? name,
    String? description,
    int? productCount,
    DateTime? lastUpdated,
  }) => CategoryModel(
    id: id,
    name: name ?? this.name,
    description: description ?? this.description,
    productCount: productCount ?? this.productCount,
    lastUpdated: lastUpdated ?? this.lastUpdated,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'productCount': productCount,
    'lastUpdated': lastUpdated.toIso8601String(),
  };
  factory CategoryModel.fromJson(Map<String, dynamic> j) => CategoryModel(
    id: (j['id'] ?? '') as String,
    name: (j['name'] ?? '') as String,
    description: (j['description'] ?? '') as String,
    productCount: (j['productCount'] as num?)?.toInt() ?? 0,
    lastUpdated: DateTime.parse(
      (j['lastUpdated'] ?? DateTime.now().toIso8601String()) as String,
    ),
  );
}

/* ======================= STORE ======================= */

class SettingsStore {
  // Profile
  static Future<Profile> loadProfile() async {
    final sp = await SharedPreferences.getInstance();
    final s = sp.getString(_kProfile);
    if (s == null || s.isEmpty) {
      final def = defaultProfile();
      await sp.setString(_kProfile, jsonEncode(def.toJson()));
      return def;
    }
    try {
      return Profile.fromJson(jsonDecode(s) as Map<String, dynamic>);
    } catch (_) {
      final def = defaultProfile();
      await sp.setString(_kProfile, jsonEncode(def.toJson()));
      return def;
    }
  }

  static Future<void> saveProfile(Profile p) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kProfile, jsonEncode(p.toJson()));
  }

  // Users
  static Future<List<UserModel>> loadUsers() async {
    final sp = await SharedPreferences.getInstance();
    final s = sp.getString(_kUsers);
    if (s == null || s.isEmpty) {
      final def = defaultUsers();
      await saveUsers(def);
      return def;
    }
    try {
      final raw = jsonDecode(s);
      if (raw is List) {
        return raw
            .map((e) => UserModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
    } catch (_) {}
    final def = defaultUsers();
    await saveUsers(def);
    return def;
  }

  static Future<void> saveUsers(List<UserModel> list) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(
      _kUsers,
      jsonEncode(list.map((e) => e.toJson()).toList()),
    );
  }

  // Categories
  static Future<List<CategoryModel>> loadCategories() async {
    final sp = await SharedPreferences.getInstance();
    final s = sp.getString(_kCategories);
    if (s == null || s.isEmpty) {
      final def = defaultCategories();
      await saveCategories(def);
      return def;
    }
    try {
      final raw = jsonDecode(s);
      if (raw is List) {
        return raw
            .map(
              (e) =>
                  CategoryModel.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .toList();
      }
    } catch (_) {}
    final def = defaultCategories();
    await saveCategories(def);
    return def;
  }

  static Future<void> saveCategories(List<CategoryModel> list) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(
      _kCategories,
      jsonEncode(list.map((e) => e.toJson()).toList()),
    );
  }

  // Defaults
  static Profile defaultProfile() => const Profile(
    name: 'Admin User',
    email: 'admin@inventorypro.app',
    phone: '+855-000-000',
    role: 'Administrator',
  );
  static List<UserModel> defaultUsers() => [
    UserModel(
      id: 'u1',
      fullName: 'Admin User',
      email: 'admin@inventorypro.app',
      role: 'Administrator',
      active: true,
      lastUpdated: DateTime(2026, 2, 18),
    ),
    UserModel(
      id: 'u2',
      fullName: 'Store Manager',
      email: 'manager@inventorypro.app',
      role: 'Manager',
      active: true,
      lastUpdated: DateTime(2026, 2, 17),
    ),
    UserModel(
      id: 'u3',
      fullName: 'Counter Staff',
      email: 'staff@inventorypro.app',
      role: 'Staff',
      active: false,
      lastUpdated: DateTime(2026, 2, 16),
    ),
  ];
  static List<CategoryModel> defaultCategories() => [
    CategoryModel(
      id: 'c1',
      name: 'Beverages',
      description: 'Coffee, tea, and drinks',
      productCount: 5,
      lastUpdated: DateTime(2026, 2, 18),
    ),
    CategoryModel(
      id: 'c2',
      name: 'Snacks',
      description: 'Chips, cookies, and snacks',
      productCount: 3,
      lastUpdated: DateTime(2026, 2, 18),
    ),
    CategoryModel(
      id: 'c3',
      name: 'Dairy',
      description: 'Milk, cheese, and dairy products',
      productCount: 2,
      lastUpdated: DateTime(2026, 2, 18),
    ),
    CategoryModel(
      id: 'c4',
      name: 'Food',
      description: 'General food items',
      productCount: 4,
      lastUpdated: DateTime(2026, 2, 18),
    ),
  ];
}
