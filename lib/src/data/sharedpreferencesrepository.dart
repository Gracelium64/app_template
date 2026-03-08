import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_app/src/common/domain/app_user.dart';
import 'package:test_app/src/common/domain/item.dart';
import 'package:test_app/src/data/databaserepository.dart';

class SharedPreferencesRepository implements DataBaseRepository {
  static const _itemsKey = 'items_v1';
  static const _userIdsKey = 'user_ids_v1';
  static const _currentUserIdKey = 'current_user_id_v1';

  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  final FlutterSecureStorage _secureStorage;

  SharedPreferencesRepository({FlutterSecureStorage? secureStorage})
    : _secureStorage =
          secureStorage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(encryptedSharedPreferences: true),
          );

  String _userStorageKey(int userId) => 'user_v1_$userId';

  Future<List<Item>> _loadItems() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_itemsKey);
    if (raw == null || raw.isEmpty) return <Item>[];

    final decoded = jsonDecode(raw);
    if (decoded is! List) return <Item>[];

    return decoded
        .whereType<Map>()
        .map((e) => Item.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  Future<void> _saveItems(List<Item> items) async {
    final prefs = await _prefs;
    final encoded = jsonEncode(items.map((e) => e.toJson()).toList());
    await prefs.setString(_itemsKey, encoded);
  }

  Future<List<int>> _loadUserIds() async {
    final prefs = await _prefs;
    final ids = prefs.getStringList(_userIdsKey) ?? const <String>[];
    return ids
        .map((e) => int.tryParse(e))
        .whereType<int>()
        .toList(growable: false);
  }

  Future<void> _saveUserIds(List<int> userIds) async {
    final prefs = await _prefs;
    await prefs.setStringList(
      _userIdsKey,
      userIds.map((e) => e.toString()).toList(growable: false),
    );
  }

  Future<AppUser?> _loadUserById(int userId) async {
    final raw = await _secureStorage.read(key: _userStorageKey(userId));
    if (raw == null || raw.isEmpty) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return null;
    return AppUser.fromJson(decoded.cast<String, dynamic>());
  }

  Future<void> _saveUser(AppUser user) async {
    await _secureStorage.write(
      key: _userStorageKey(user.userId),
      value: jsonEncode(user.toJson()),
    );
  }

  Future<void> _deleteUser(int userId) async {
    await _secureStorage.delete(key: _userStorageKey(userId));
  }

  Future<int?> _getCurrentUserId() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_currentUserIdKey);
    return raw == null ? null : int.tryParse(raw);
  }

  Future<void> _setCurrentUserId(int? userId) async {
    final prefs = await _prefs;
    if (userId == null) {
      await prefs.remove(_currentUserIdKey);
    } else {
      await prefs.setString(_currentUserIdKey, userId.toString());
    }
  }

  @override
  Future<void> createItem(
    String title,
    String type, {
    String? dataItemId,
  }) async {
    final items = await _loadItems();

    final int nextId;
    if (dataItemId != null) {
      final parsed = int.tryParse(dataItemId);
      if (parsed == null) {
        throw ArgumentError.value(
          dataItemId,
          'dataItemId',
          'Must be a numeric string for this app',
        );
      }
      nextId = parsed;
    } else {
      nextId =
          items.isEmpty
              ? 0
              : items.map((e) => e.itemId).reduce((a, b) => a > b ? a : b) + 1;
    }

    final item = Item(
      itemId: nextId,
      itemType: type,
      itemTitle: title,
      itemDescription: '',
      photoUrl: null,
      createdAt: DateTime.now(),
      isDone: false,
    );

    items.removeWhere((e) => e.itemId == nextId);
    items.add(item);
    await _saveItems(items);
  }

  @override
  Future<List<Item>> readItems() async {
    return _loadItems();
  }

  @override
  Future<void> updateItem(
    String dataItemId,
    String title,
    String description,
    String? photoUrl,
  ) async {
    final items = await _loadItems();

    final oldItem = items.firstWhere(
      (item) => item.itemId.toString() == dataItemId,
      orElse: () => throw Exception('Item not found: $dataItemId'),
    );

    final updated = Item(
      itemId: oldItem.itemId,
      itemType: oldItem.itemType,
      itemTitle: title,
      itemDescription: description,
      photoUrl: photoUrl,
      createdAt: oldItem.createdAt,
      isDone: oldItem.isDone,
    );

    items.removeWhere((e) => e.itemId == oldItem.itemId);
    items.add(updated);
    await _saveItems(items);
  }

  @override
  Future<void> deleteItem(String dataItemId) async {
    final items = await _loadItems();
    items.removeWhere((e) => e.itemId.toString() == dataItemId);
    await _saveItems(items);
  }

  @override
  Future<void> toggleItem(String dataItemId) async {
    final items = await _loadItems();

    final oldItem = items.firstWhere(
      (item) => item.itemId.toString() == dataItemId,
      orElse: () => throw Exception('Item not found: $dataItemId'),
    );

    final updated = Item(
      itemId: oldItem.itemId,
      itemType: oldItem.itemType,
      itemTitle: oldItem.itemTitle,
      itemDescription: oldItem.itemDescription,
      photoUrl: oldItem.photoUrl,
      createdAt: oldItem.createdAt,
      isDone: !oldItem.isDone,
    );

    items.removeWhere((e) => e.itemId == oldItem.itemId);
    items.add(updated);
    await _saveItems(items);
  }

  @override
  Future<void> createUser(
    int userId,
    String email,
    String password,
    String displayName,
  ) async {
    final userIds = (await _loadUserIds()).toList();
    final users = await readAllUsers();

    final existingIds = users.map((e) => e.userId).toSet();
    final int resolvedId;

    if (userId >= 0 && !existingIds.contains(userId)) {
      resolvedId = userId;
    } else {
      resolvedId =
          existingIds.isEmpty
              ? 0
              : existingIds.reduce((a, b) => a > b ? a : b) + 1;
    }

    final user = AppUser(
      userId: resolvedId,
      email: email,
      password: password,
      displayName: displayName,
    );

    await _saveUser(user);
    if (!userIds.contains(resolvedId)) {
      userIds.add(resolvedId);
      await _saveUserIds(userIds);
    }
  }

  @override
  Future<List<AppUser>> readAllUsers() async {
    final userIds = await _loadUserIds();
    final users = <AppUser>[];
    final idsToKeep = <int>[];

    for (final id in userIds) {
      final user = await _loadUserById(id);
      if (user != null) {
        users.add(user);
        idsToKeep.add(id);
      }
    }

    if (idsToKeep.length != userIds.length) {
      await _saveUserIds(idsToKeep);
    }

    return users;
  }

  @override
  Future<void> updateUser(
    int userId,
    String email,
    String password,
    String displayName,
  ) async {
    final existing = await _loadUserById(userId);
    if (existing == null) throw Exception('User not found: $userId');

    final updated = AppUser(
      userId: existing.userId,
      email: email,
      password: password,
      displayName: displayName,
      firstName: existing.firstName,
      lastName: existing.lastName,
      title: existing.title,
      company: existing.company,
      phoneNumber: existing.phoneNumber,
      photoUrl: existing.photoUrl,
    );

    await _saveUser(updated);
  }

  @override
  Future<void> deleteUser(int userId) async {
    final userIds = (await _loadUserIds()).toList();
    userIds.removeWhere((e) => e == userId);
    await _saveUserIds(userIds);
    await _deleteUser(userId);

    final currentUserId = await _getCurrentUserId();
    if (currentUserId == userId) {
      await _setCurrentUserId(null);
    }
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    final currentUserId = await _getCurrentUserId();
    if (currentUserId == null) return null;
    return _loadUserById(currentUserId);
  }

  @override
  Future<AppUser> signIn(String email, String password) async {
    final users = await readAllUsers();
    final user = users.firstWhere(
      (u) => u.email == email,
      orElse: () => throw Exception('User not found'),
    );

    if (user.password != password) {
      throw Exception('Invalid credentials');
    }

    await _setCurrentUserId(user.userId);
    return user;
  }

  @override
  Future<AppUser> register(
    String email,
    String password,
    String displayName,
  ) async {
    final existing = await readAllUsers();
    final alreadyExists = existing.any((u) => u.email == email);
    if (alreadyExists) {
      throw Exception('User already exists');
    }

    await createUser(-1, email, password, displayName);
    final user = (await readAllUsers()).firstWhere((u) => u.email == email);
    await _setCurrentUserId(user.userId);
    return user;
  }

  @override
  Future<void> signOut() async {
    await _setCurrentUserId(null);
  }
}
