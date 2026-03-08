import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_app/src/data/mockdatabaserepository.dart';
import 'package:test_app/src/data/sharedpreferencesrepository.dart';
import 'package:test_app/src/data/syncrepository.dart';

import 'repository_contract.dart';
import 'test_secure_storage_mock.dart';

void main() {
  group('Repository contract suites', () {
    late SecureStorageMock secureStorageMock;

    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      secureStorageMock = SecureStorageMock()..install();
    });

    tearDown(() {
      secureStorageMock.uninstall();
    });

    runDataBaseRepositoryContractTests(
      name: 'MockDataRepository',
      build: () async => MockDataRepository(),
      explicitItemIdMustBeNumeric: true,
      supportsPersistenceAcrossInstances: false,
    );

    runDataBaseRepositoryContractTests(
      name: 'SharedPreferencesRepository',
      build: () async => SharedPreferencesRepository(),
      rebuild: () async => SharedPreferencesRepository(),
      explicitItemIdMustBeNumeric: true,
      supportsPersistenceAcrossInstances: true,
    );

    runDataBaseRepositoryContractTests(
      name: 'SyncRepository (local-first, no remote)',
      build: () async => SyncRepository(
        local: SharedPreferencesRepository(),
        remote: null,
        syncOn: true,
      ),
      rebuild: () async => SyncRepository(
        local: SharedPreferencesRepository(),
        remote: null,
        syncOn: true,
      ),
      explicitItemIdMustBeNumeric: true,
      supportsPersistenceAcrossInstances: true,
    );

    test('secure storage mock sanity check', () {
      // Prevents accidental removal of mock wiring.
      expect(secureStorageMock.readRaw('any'), isNull);
    });
  });
}
