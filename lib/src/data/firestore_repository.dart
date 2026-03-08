import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:test_app/src/common/domain/app_user.dart';
import 'package:test_app/src/common/domain/item.dart';
import 'package:test_app/src/data/databaserepository.dart';


class FirestoreRepository implements DataBaseRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  FirestoreRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  User? get _firebaseUser => _auth.currentUser;

  User _requireFirebaseUser() {
    final user = _firebaseUser;
    if (user == null) {
      throw StateError('Not signed in');
    }
    return user;
  }

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) {
    return _firestore.collection('users').doc(uid);
  }

  CollectionReference<Map<String, dynamic>> _itemsCol(String uid) {
    return _userDoc(uid).collection('items');
  }

  Item _itemFromFirestore(Map<String, dynamic> data) {
    final createdAtRaw = data['createdAt'];
    final DateTime createdAt;
    if (createdAtRaw is Timestamp) {
      createdAt = createdAtRaw.toDate();
    } else if (createdAtRaw is String) {
      createdAt =
          DateTime.tryParse(createdAtRaw) ??
          DateTime.fromMillisecondsSinceEpoch(0);
    } else {
      createdAt = DateTime.fromMillisecondsSinceEpoch(0);
    }

    final itemIdRaw = data['itemId'];
    final int itemId;
    if (itemIdRaw is int) {
      itemId = itemIdRaw;
    } else if (itemIdRaw is num) {
      itemId = itemIdRaw.toInt();
    } else if (itemIdRaw is String) {
      itemId = int.tryParse(itemIdRaw) ?? 0;
    } else {
      itemId = 0;
    }

    return Item(
      itemId: itemId,
      itemType: (data['itemType'] as String?) ?? '',
      itemTitle: (data['itemTitle'] as String?) ?? '',
      itemDescription: (data['itemDescription'] as String?) ?? '',
      photoUrl: data['photoUrl'] as String?,
      createdAt: createdAt,
      isDone: (data['isDone'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> _itemToFirestore(Item item) {
    return {
      'itemId': item.itemId,
      'itemType': item.itemType,
      'itemTitle': item.itemTitle,
      'itemDescription': item.itemDescription,
      'photoUrl': item.photoUrl,
      'createdAt': Timestamp.fromDate(item.createdAt),
      'isDone': item.isDone,
    };
  }

  AppUser _userFromFirestore({
    required int userId,
    required String email,
    required String displayName,
  }) {
    return AppUser(
      userId: userId,
      email: email,
      password: '',
      displayName: displayName,
    );
  }

  @override
  Future<void> createItem(
    String title,
    String type, {
    String? dataItemId,
  }) async {
    final uid = _requireFirebaseUser().uid;

    final int itemId;
    if (dataItemId != null) {
      itemId =
          int.tryParse(dataItemId) ?? DateTime.now().millisecondsSinceEpoch;
    } else {
      itemId = DateTime.now().microsecondsSinceEpoch;
    }

    final item = Item(
      itemId: itemId,
      itemType: type,
      itemTitle: title,
      itemDescription: '',
      photoUrl: null,
      createdAt: DateTime.now(),
      isDone: false,
    );

    final col = _itemsCol(uid);
    final docId = dataItemId ?? itemId.toString();
    final docRef = col.doc(docId);
    await docRef.set(_itemToFirestore(item));
  }

  @override
  Future<List<Item>> readItems() async {
    final uid = _requireFirebaseUser().uid;
    final snapshot = await _itemsCol(uid).get();
    return snapshot.docs.map((d) => _itemFromFirestore(d.data())).toList();
  }

  @override
  Future<void> updateItem(
    String dataItemId,
    String title,
    String description,
    String? photoUrl,
  ) async {
    final uid = _requireFirebaseUser().uid;
    await _itemsCol(uid).doc(dataItemId).update({
      'itemTitle': title,
      'itemDescription': description,
      'photoUrl': photoUrl,
    });
  }

  @override
  Future<void> deleteItem(String dataItemId) async {
    final uid = _requireFirebaseUser().uid;
    await _itemsCol(uid).doc(dataItemId).delete();
  }

  @override
  Future<void> toggleItem(String dataItemId) async {
    final uid = _requireFirebaseUser().uid;
    final docRef = _itemsCol(uid).doc(dataItemId);
    final snap = await docRef.get();
    if (!snap.exists) throw Exception('Item not found: $dataItemId');

    final data = snap.data();
    if (data == null) throw Exception('Item not found: $dataItemId');

    final current = (data['isDone'] as bool?) ?? false;
    await docRef.update({'isDone': !current});
  }

  @override
  Future<void> createUser(
    int userId,
    String email,
    String password,
    String displayName,
  ) async {
    final uid = _requireFirebaseUser().uid;
    await _userDoc(uid).set({
      'userId': userId,
      'email': email,
      'displayName': displayName,
      'photoUrl': null,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<List<AppUser>> readAllUsers() async {
    final user = _firebaseUser;
    if (user == null) return <AppUser>[];

    final snap = await _userDoc(user.uid).get();
    final data = snap.data();
    if (data == null) return <AppUser>[];

    final userIdRaw = data['userId'];
    final userId =
        userIdRaw is int
            ? userIdRaw
            : (userIdRaw is num ? userIdRaw.toInt() : 0);
    return <AppUser>[
      _userFromFirestore(
        userId: userId,
        email: (data['email'] as String?) ?? user.email ?? '',
        displayName: (data['displayName'] as String?) ?? user.displayName ?? '',
      ),
    ];
  }

  @override
  Future<void> updateUser(
    int userId,
    String email,
    String password,
    String displayName,
  ) async {
    final uid = _requireFirebaseUser().uid;
    await _userDoc(uid).set({
      'userId': userId,
      'email': email,
      'displayName': displayName,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> deleteUser(int userId) async {
    final uid = _requireFirebaseUser().uid;
    await _userDoc(uid).delete();
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    final user = _firebaseUser;
    if (user == null) return null;

    final docRef = _userDoc(user.uid);
    final snap = await docRef.get();
    final data = snap.data();
    if (data == null) {
      final generatedId = DateTime.now().millisecondsSinceEpoch;
      await docRef.set({
        'userId': generatedId,
        'email': user.email ?? '',
        'displayName': user.displayName ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return _userFromFirestore(
        userId: generatedId,
        email: user.email ?? '',
        displayName: user.displayName ?? '',
      );
    }

    final userIdRaw = data['userId'];
    final userId =
        userIdRaw is int
            ? userIdRaw
            : (userIdRaw is num ? userIdRaw.toInt() : 0);

    return _userFromFirestore(
      userId: userId,
      email: (data['email'] as String?) ?? user.email ?? '',
      displayName: (data['displayName'] as String?) ?? user.displayName ?? '',
    );
  }

  @override
  Future<AppUser> signIn(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
    final current = await getCurrentUser();
    if (current == null) {
      throw Exception('Sign-in succeeded but no user profile');
    }
    return current;
  }

  @override
  Future<AppUser> register(
    String email,
    String password,
    String displayName,
  ) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await credential.user?.updateDisplayName(displayName);

    final generatedId = DateTime.now().millisecondsSinceEpoch;
    await createUser(generatedId, email, password, displayName);

    final current = await getCurrentUser();
    if (current == null) {
      throw Exception('Registration succeeded but no user profile');
    }
    return current;
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
