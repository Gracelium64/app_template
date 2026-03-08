import 'package:flutter_test/flutter_test.dart';
import 'package:test_app/src/data/databaserepository.dart';

/// Reusable contract tests for any [DataBaseRepository] implementation.
///
/// These tests assert *baseline* behaviors that should remain true regardless
/// of what backend you swap in (local-only, Firebase, REST, etc.).
///
/// Notes:
/// - Some behaviors are app-specific (e.g. explicit item IDs must be numeric).
///   Toggle them via parameters.
void runDataBaseRepositoryContractTests({
  required String name,
  required Future<DataBaseRepository> Function() build,
  bool explicitItemIdMustBeNumeric = false,
  bool supportsPersistenceAcrossInstances = false,
  Future<DataBaseRepository> Function()? rebuild,
}) {
  group('DataBaseRepository contract: $name', () {
    test('item CRUD supports unicode/emoji input', () async {
      final repo = await build();

      final initialLen = (await repo.readItems()).length;

      await repo.createItem('Buy 🥑 groceries', 'todo✅');
      final afterCreate = await repo.readItems();
      expect(afterCreate.length, initialLen + 1);

      // Find the newly created item by title (ID generation differs per repo).
      final created = afterCreate.firstWhere(
        (i) => i.itemTitle == 'Buy 🥑 groceries',
      );

      await repo.updateItem(
        created.itemId.toString(),
        'Buy 🥑 groceries (updated)',
        'desc with emoji 🙂 and accents é',
        null,
      );

      final afterUpdate = await repo.readItems();
      final updated = afterUpdate.firstWhere((i) => i.itemId == created.itemId);
      expect(updated.itemTitle, 'Buy 🥑 groceries (updated)');
      expect(updated.itemDescription, 'desc with emoji 🙂 and accents é');

      await repo.toggleItem(created.itemId.toString());
      final afterToggle = await repo.readItems();
      final toggled = afterToggle.firstWhere((i) => i.itemId == created.itemId);
      expect(toggled.isDone, isTrue);

      await repo.deleteItem(created.itemId.toString());
      final afterDelete = await repo.readItems();
      expect(afterDelete.any((i) => i.itemId == created.itemId), isFalse);
    });

    test('auth: register/signIn supports unicode/emoji password', () async {
      final repo = await build();

      const email = 'emoji.user@test.com';
      const password = 'p🔐🙂w';
      const displayName = 'Emoji 🙂 User';

      final registered = await repo.register(email, password, displayName);
      expect(registered.email, email);

      final current = await repo.getCurrentUser();
      expect(current, isNotNull);
      expect(current!.email, email);

      await repo.signOut();
      expect(await repo.getCurrentUser(), isNull);

      final signedIn = await repo.signIn(email, password);
      expect(signedIn.email, email);
    });

    if (explicitItemIdMustBeNumeric) {
      test(
        'createItem throws when explicit dataItemId is non-numeric',
        () async {
          final repo = await build();

          expect(
            () => repo.createItem('x', 'y', dataItemId: 'not-a-number'),
            throwsA(isA<ArgumentError>()),
          );
        },
      );
    }

    if (supportsPersistenceAcrossInstances) {
      test('persists items across new repository instances', () async {
        final createAgain = rebuild ?? build;

        final repo1 = await build();
        await repo1.createItem('persist me', 'typeP');

        final repo2 = await createAgain();
        final items = await repo2.readItems();
        expect(items.any((i) => i.itemTitle == 'persist me'), isTrue);
      });

      test(
        'persists current user session across new instances (if supported)',
        () async {
          final createAgain = rebuild ?? build;

          const email = 'persist.user@test.com';
          const password = 'pw';
          const displayName = 'Persist';

          final repo1 = await build();
          await repo1.register(email, password, displayName);

          final repo2 = await createAgain();
          final current = await repo2.getCurrentUser();
          expect(current, isNotNull);
          expect(current!.email, email);
        },
      );
    }
  });
}
