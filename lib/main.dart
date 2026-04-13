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
  var firebaseAvailable = true;
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Firebase not configured for this platform/environment. Continue without it.
    firebaseAvailable = false;
  }

  final DataBaseRepository? remoteRepo = firebaseAvailable
      ? FirestoreRepository()
      : null;

  final DataBaseRepository db = SyncRepository(
    local: MockDataRepository(),
    remote: remoteRepo,
    secureStorage: FlutterSecureStorage(),
    syncOn: false,
  );

  runApp(App(db));
}
