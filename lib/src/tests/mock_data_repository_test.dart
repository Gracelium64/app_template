import 'package:flutter_test/flutter_test.dart';
import 'package:test_app/src/data/mockdatabaserepository.dart';

void main() {
  group('MockDataRepository', () {
    test('item CRUD + toggle works', () async {
      final repo = MockDataRepository();

      // `MockDataRepository.readItems()` returns the internal mutable list.
      // Snapshot the length to avoid the reference mutating under us.
      final initialLen = (await repo.readItems()).length;
      expect(initialLen, greaterThan(0));

      await repo.createItem('new title', 'typeB');
      final afterCreate = await repo.readItems();
      expect(afterCreate.length, initialLen + 1);

      final created = afterCreate.last;
      expect(created.itemTitle, 'new title');
      expect(created.itemType, 'typeB');
      expect(created.isDone, isFalse);

      await repo.updateItem(
        created.itemId.toString(),
        'updated',
        'updated desc',
        'https://example.com/p.png',
      );

      final afterUpdate = await repo.readItems();
      final updated = afterUpdate.firstWhere((i) => i.itemId == created.itemId);
      expect(updated.itemTitle, 'updated');
      expect(updated.itemDescription, 'updated desc');
      expect(updated.photoUrl, 'https://example.com/p.png');

      await repo.toggleItem(created.itemId.toString());
      final afterToggle = await repo.readItems();
      final toggled = afterToggle.firstWhere((i) => i.itemId == created.itemId);
      expect(toggled.isDone, isTrue);

      await repo.deleteItem(created.itemId.toString());
      final afterDelete = await repo.readItems();
      expect(afterDelete.any((i) => i.itemId == created.itemId), isFalse);
    });

    test('auth flow: register -> getCurrentUser -> signOut', () async {
      final repo = MockDataRepository();

      final user = await repo.register('unique@test.com', 'pw', 'Unique');
      expect(user.email, 'unique@test.com');
      expect(user.displayName, 'Unique');

      final current = await repo.getCurrentUser();
      expect(current, isNotNull);
      expect(current!.email, 'unique@test.com');

      await repo.signOut();
      final after = await repo.getCurrentUser();
      expect(after, isNull);
    });

    test('signIn fails with wrong password', () async {
      final repo = MockDataRepository();

      expect(
        () => repo.signIn('test@test.com', 'wrong'),
        throwsA(isA<Exception>()),
      );
    });

    test('register fails when user already exists', () async {
      final repo = MockDataRepository();

      expect(
        () => repo.register('test@test.com', '123', 'Dup'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
