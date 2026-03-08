

import 'package:test_app/src/common/domain/app_user.dart';
import 'package:test_app/src/common/domain/item.dart';

abstract class DataBaseRepository {
  // general Item operations
  Future<void> createItem(String title, String type, {String? dataItemId});
  Future<List<Item>> readItems();
  Future<void> updateItem(
    String dataItemId,
    String title,
    String description,
    String? photoUrl,
  );
  Future<void> deleteItem(String dataItemId);
  Future<void> toggleItem(String dataItemId);

  //general AppUser operations
  Future<void> createUser(
    int userId,
    String email,
    String password,
    String displayName,
  );
  Future<List<AppUser>> readAllUsers();
  Future<void> updateUser(
    int userId,
    String email,
    String password,
    String displayName,
  );
  Future<void> deleteUser(int userId);

  // Auth / session operations
  Future<AppUser?> getCurrentUser();
  Future<AppUser> signIn(String email, String password);
  Future<AppUser> register(String email, String password, String displayName);
  Future<void> signOut();
}
