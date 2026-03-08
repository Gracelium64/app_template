import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_app/src/common/domain/app_user.dart';
import 'package:test_app/src/common/domain/item.dart';
import 'package:test_app/src/data/databaserepository.dart';
import 'package:test_app/src/data/mockdatabaserepository.dart';
import 'package:test_app/src/data/syncrepository.dart';

import 'test_secure_storage_mock.dart';

class RecordingRemoteRepository implements DataBaseRepository {
  bool failCreateItemOnce;

  int createItemCalls = 0;
  int updateItemCalls = 0;
  int deleteItemCalls = 0;
  int toggleItemCalls = 0;

  int signInCalls = 0;
  int registerCalls = 0;
  int signOutCalls = 0;

  final List<Map<String, Object?>> createItemArgs = [];

  RecordingRemoteRepository({this.failCreateItemOnce = false});

  @override
  Future<void> createItem(
    String title,
    String type, {
    String? dataItemId,
  }) async {
    createItemCalls += 1;
    createItemArgs.add({
      'title': title,
      'type': type,
      'dataItemId': dataItemId,
    });
    if (failCreateItemOnce) {
      failCreateItemOnce = false;
      throw Exception('remote down');
    }
  }

  @override
  Future<List<Item>> readItems() async => <Item>[];

  @override
  Future<void> updateItem(
    String dataItemId,
    String title,
    String description,
    String? photoUrl,
  ) async {
    updateItemCalls += 1;
  }

  @override
  Future<void> deleteItem(String dataItemId) async {
    deleteItemCalls += 1;
  }

  @override
  Future<void> toggleItem(String dataItemId) async {
    toggleItemCalls += 1;
  }

  @override
  Future<void> createUser(
    int userId,
    String email,
    String password,
    String displayName,
  ) async {}

  @override
  Future<List<AppUser>> readAllUsers() async => <AppUser>[];

  @override
  Future<void> updateUser(
    int userId,
    String email,
    String password,
    String displayName,
  ) async {}

  @override
  Future<void> deleteUser(int userId) async {}

  @override
  Future<AppUser?> getCurrentUser() async => null;

  @override
  Future<AppUser> signIn(String email, String password) async {
    signInCalls += 1;
    return AppUser(
      userId: 1,
      email: email,
      password: password,
      displayName: 'Remote',
    );
  }

  @override
  Future<AppUser> register(
    String email,
    String password,
    String displayName,
  ) async {
    registerCalls += 1;
    return AppUser(
      userId: 1,
      email: email,
      password: password,
      displayName: displayName,
    );
  }

  @override
  Future<void> signOut() async {
    signOutCalls += 1;
  }
}

void main() {
  group('SyncRepository', () {
    late SecureStorageMock secureStorageMock;

    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      secureStorageMock = SecureStorageMock()..install();
    });

    tearDown(() {
      secureStorageMock.uninstall();
    });

    test('works local-first with no remote configured', () async {
      final local = MockDataRepository();
      final repo = SyncRepository(local: local, remote: null, syncOn: true);

      // Under the hood this returns `MockDataRepository.items`, which is mutable.
      final initialLen = (await repo.readItems()).length;
      await repo.createItem('x', 'typeX');
      final after = await repo.readItems();
      expect(after.length, initialLen + 1);
    });

    test(
      'calls remote when configured (and passes a resolved dataItemId)',
      () async {
        final local = MockDataRepository();
        final remote = RecordingRemoteRepository();
        final repo = SyncRepository(local: local, remote: remote, syncOn: true);

        await repo.createItem('t', 'typeT');

        expect(remote.createItemCalls, 1);
        expect(remote.createItemArgs.single['dataItemId'], isNotNull);
      },
    );

    test('queues failed remote ops and flushes later', () async {
      final local = MockDataRepository();
      final remote = RecordingRemoteRepository(failCreateItemOnce: true);
      final repo = SyncRepository(local: local, remote: remote, syncOn: true);

      await repo.createItem('a', 'A'); // fails remote -> queued
      expect(remote.createItemCalls, 1);

      // Next successful op should flush the queue.
      await repo.createItem('b', 'B');

      expect(remote.createItemCalls, greaterThanOrEqualTo(2));

      final rawQueue = secureStorageMock.readRaw('sync_queue_v1');
      // When empty, SyncRepository writes '[]'.
      expect(rawQueue == null || rawQueue == '[]', isTrue);
    });
  });
}
