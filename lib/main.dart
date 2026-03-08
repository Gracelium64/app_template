import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:test_app/src/app.dart';
import 'package:test_app/src/data/databaserepository.dart';
import 'package:test_app/src/data/firestore_repository.dart';
import 'package:test_app/src/data/mockdatabaserepository.dart';
import 'package:test_app/src/data/syncrepository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final DataBaseRepository db = SyncRepository(
    local: MockDataRepository(),
    remote: FirestoreRepository(),
    secureStorage: FlutterSecureStorage(),
    syncOn: false,
  );
  runApp(App(db));
}
