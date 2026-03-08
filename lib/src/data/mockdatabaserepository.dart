import 'package:test_app/src/common/domain/app_user.dart';
import 'package:test_app/src/common/domain/item.dart';
import 'package:test_app/src/data/databaserepository.dart';

class MockDataRepository implements DataBaseRepository {
  int? _currentUserId;

  List<Item> items = [
    Item(
      itemId: 0,
      itemType: 'typeA',
      itemTitle: 'itemTitle',
      itemDescription: 'itemDescription',
      createdAt: DateTime.now(),
      isDone: false,
    ),
    Item(
      itemId: 1,
      itemType: 'typeA',
      itemTitle: 'itemTitle1',
      itemDescription: 'itemDescription1',
      createdAt: DateTime.now(),
      isDone: false,
    ),
    Item(
      itemId: 2,
      itemType: 'typeA',
      itemTitle: 'itemTitle2',
      itemDescription: 'itemDescription2',
      createdAt: DateTime.now(),
      isDone: false,
    ),
  ];

  List<AppUser> users = [
    AppUser(
      userId: 1,
      email: 'test@test.com',
      password: '123',
      displayName: 'Test',
    ),
    AppUser(
      userId: 2,
      email: 'test@test.com',
      password: '123',
      displayName: 'Test2',
    ),

    AppUser(
      userId: 3,
      email: 'test@test.com',
      password: '123',
      displayName: 'Test3',
    ),
  ];

  @override
  Future<void> createItem(
    String title,
    String type, {
    String? dataItemId,
  }) async {
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
              : items.map((e) => e.itemId).reduce((a, b) {
                    return a > b ? a : b;
                  }) +
                  1;
    }

    final item = Item(
      itemId: nextId, // app-generated
      itemType: type, // user input
      itemTitle: title, // user input
      itemDescription: '', // default/app value
      photoUrl: null, // default/app value
      createdAt: DateTime.now(), // app-generated
      isDone: false, // default
    );

    items.add(item);
  }

  @override
  Future<void> createUser(
    int userId,
    String email,
    String password,
    String displayName,
  ) async {
    final existingIds = users.map((e) => e.userId).toSet();
    final int nextId;

    if (userId >= 0 && !existingIds.contains(userId)) {
      nextId = userId;
    } else {
      nextId =
          users.isEmpty
              ? 0
              : users.map((e) => e.userId).reduce((a, b) {
                    return a > b ? a : b;
                  }) +
                  1;
    }

    final user = AppUser(
      userId: nextId,
      email: email,
      password: password,
      displayName: displayName,
    );
    users.add(user);
  }

  @override
  Future<void> updateItem(
    String dataItemId,
    String title,
    String description,
    String? photoUrl,
  ) async {
    late final Item oldItem;

    try {
      oldItem = items.firstWhere(
        (item) => item.itemId.toString() == dataItemId,
      );
    } catch (e) {
      throw Exception('Item not found: $dataItemId');
    }

    final updatedItem = Item(
      itemId: oldItem.itemId,
      itemType: oldItem.itemType,
      itemTitle: title,
      itemDescription: description,
      photoUrl: photoUrl,
      createdAt: oldItem.createdAt,
      isDone: oldItem.isDone,
    );
    items.removeWhere((item) => item.itemId.toString() == dataItemId);
    items.add(updatedItem);
  }

  @override
  Future<void> updateUser(
    int userId,
    String email,
    String password,
    String displayName,
  ) async {
    late final AppUser oldUser;

    try {
      oldUser = users.firstWhere(
        (user) => user.userId == userId,
      );
    } catch (e) {
      throw Exception('User not found: $userId');
    }

    final updatedUser = AppUser(
      userId: oldUser.userId,
      email: email,
      password: password,
      displayName: displayName,
    );
    users.removeWhere((user) => user.userId == userId);
    users.add(updatedUser);
  }

  @override
  Future<void> toggleItem(String dataItemId) async {
    late final Item oldItem;

    try {
      oldItem = items.firstWhere(
        (item) => item.itemId.toString() == dataItemId,
      );
    } catch (e) {
      throw Exception('Item not found: $dataItemId');
    }

    final updatedItem = Item(
      itemId: oldItem.itemId,
      itemType: oldItem.itemType,
      itemTitle: oldItem.itemTitle,
      itemDescription: oldItem.itemDescription,
      photoUrl: oldItem.photoUrl,
      createdAt: oldItem.createdAt,
      isDone: !oldItem.isDone,
    );
    items.removeWhere((item) => item.itemId.toString() == dataItemId);
    items.add(updatedItem);
  }

  @override
  Future<void> deleteUser(int userId) async {
    try {
      users.removeWhere((user) => user.userId == userId);
    } catch (e) {
      throw Exception('User not found: $userId');
    }

    if (_currentUserId == userId) {
      _currentUserId = null;
    }
  }

  @override
  Future<void> deleteItem(String dataItemId) async {
    try {
      items.removeWhere((item) => item.itemId.toString() == dataItemId);
    } catch (e) {
      throw Exception('Item not found: $dataItemId');
    }
  }

  @override
  Future<List<AppUser>> readAllUsers() async {
    return users;
  }

  @override
  Future<List<Item>> readItems() async {
    return items;
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    final id = _currentUserId;
    if (id == null) return null;
    try {
      return users.firstWhere((u) => u.userId == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<AppUser> signIn(String email, String password) async {
    final user = users.firstWhere(
      (u) => u.email == email,
      orElse: () => throw Exception('User not found'),
    );
    if (user.password != password) throw Exception('Invalid credentials');
    _currentUserId = user.userId;
    return user;
  }

  @override
  Future<AppUser> register(
    String email,
    String password,
    String displayName,
  ) async {
    final exists = users.any((u) => u.email == email);
    if (exists) throw Exception('User already exists');

    await createUser(-1, email, password, displayName);
    return signIn(email, password);
  }

  @override
  Future<void> signOut() async {
    _currentUserId = null;
  }
}
