import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_app/src/data/sharedpreferencesrepository.dart';

import 'test_secure_storage_mock.dart';

void main() {
  group('SharedPreferencesRepository', () {
    late SecureStorageMock secureStorageMock;

    setUp(() {
      // SharedPreferences mock is global/static.
      SharedPreferences.setMockInitialValues(<String, Object>{});
      secureStorageMock = SecureStorageMock()..install();
    });

    tearDown(() {
      secureStorageMock.uninstall();
    });

    test('item CRUD persists via SharedPreferences', () async {
      final repo = SharedPreferencesRepository();

      final initial = await repo.readItems();
      expect(initial, isEmpty);

      await repo.createItem('a', 'typeA');
      await repo.createItem('b', 'typeB');

      final afterCreate = await repo.readItems();
      expect(afterCreate.length, 2);

      final first = afterCreate.first;

      await repo.updateItem(first.itemId.toString(), 'a2', 'desc', null);
      final afterUpdate = await repo.readItems();
      final updated = afterUpdate.firstWhere((i) => i.itemId == first.itemId);
      expect(updated.itemTitle, 'a2');
      expect(updated.itemDescription, 'desc');

      await repo.toggleItem(first.itemId.toString());
      final afterToggle = await repo.readItems();
      final toggled = afterToggle.firstWhere((i) => i.itemId == first.itemId);
      expect(toggled.isDone, isTrue);

      // New instance should see persisted items.
      final repo2 = SharedPreferencesRepository();
      final persisted = await repo2.readItems();
      expect(persisted.length, 2);

      await repo.deleteItem(first.itemId.toString());
      final afterDelete = await repo.readItems();
      expect(afterDelete.length, 1);
      expect(afterDelete.any((i) => i.itemId == first.itemId), isFalse);
    });

    test('user CRUD + auth persists current user id', () async {
      final repo = SharedPreferencesRepository();

      await repo.createUser(10, 'u@test.com', 'pw', 'User');
      final all = await repo.readAllUsers();
      expect(all.length, 1);
      expect(all.single.userId, 10);

      final signedIn = await repo.signIn('u@test.com', 'pw');
      expect(signedIn.userId, 10);

      final current = await repo.getCurrentUser();
      expect(current, isNotNull);
      expect(current!.email, 'u@test.com');

      await repo.signOut();
      final after = await repo.getCurrentUser();
      expect(after, isNull);
    });

    test('register fails on duplicate email', () async {
      final repo = SharedPreferencesRepository();

      await repo.register('dup@test.com', 'pw', 'Dup');
      expect(
        () => repo.register('dup@test.com', 'pw2', 'Dup2'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
