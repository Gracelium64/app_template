import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:test_app/src/common/domain/app_user.dart';
import 'package:test_app/src/common/domain/item.dart';
import 'package:test_app/src/data/databaserepository.dart';
import 'package:test_app/src/data/sharedpreferencesrepository.dart';

class SyncRepository implements DataBaseRepository {
  static const _queueKey = 'sync_queue_v1';

  final DataBaseRepository _local;
  final DataBaseRepository? _remote;
  final FlutterSecureStorage _secureStorage;

  bool? syncOn;

  final int maxRemoteOpsPerMinute;
  final List<int> _remoteOpTimestampsMs = <int>[];

  SyncRepository({
    DataBaseRepository? local,
    DataBaseRepository? remote,
    FlutterSecureStorage? secureStorage,
    this.syncOn,
    this.maxRemoteOpsPerMinute = 30,
  }) : _local = local ?? SharedPreferencesRepository(),
       _remote = remote,
       _secureStorage =
           secureStorage ??
           const FlutterSecureStorage(
             aOptions: AndroidOptions(encryptedSharedPreferences: true),
           );

  bool get _syncEnabled => (syncOn ?? true) && _remote != null;

  int _nowMs() => DateTime.now().millisecondsSinceEpoch;

  bool _consumeRemoteOpToken() {
    final now = _nowMs();
    _remoteOpTimestampsMs.removeWhere((t) => now - t > 60 * 1000);
    if (_remoteOpTimestampsMs.length >= maxRemoteOpsPerMinute) return false;
    _remoteOpTimestampsMs.add(now);
    return true;
  }

  Future<List<_QueuedOp>> _loadQueue() async {
    final raw = await _secureStorage.read(key: _queueKey);
    if (raw == null || raw.isEmpty) return <_QueuedOp>[];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return <_QueuedOp>[];
    return decoded
        .whereType<Map>()
        .map((m) => _QueuedOp.fromJson(m.cast<String, dynamic>()))
        .toList();
  }

  Future<void> _saveQueue(List<_QueuedOp> queue) async {
    final raw = jsonEncode(queue.map((e) => e.toJson()).toList());
    await _secureStorage.write(key: _queueKey, value: raw);
  }

  Future<void> _enqueue(_QueuedOp op) async {
    final queue = await _loadQueue();
    queue.add(op);
    if (queue.length > 200) {
      queue.removeRange(0, queue.length - 200);
    }
    await _saveQueue(queue);
  }

  Future<void> _flushQueue({int maxOps = 20}) async {
    if (!_syncEnabled) return;

    final queue = await _loadQueue();
    if (queue.isEmpty) return;

    final now = _nowMs();
    var opsDone = 0;
    final remaining = <_QueuedOp>[];

    for (final op in queue) {
      if (opsDone >= maxOps) {
        remaining.add(op);
        continue;
      }

      if (op.nextRetryAtMs != null && now < op.nextRetryAtMs!) {
        remaining.add(op);
        continue;
      }

      if (!_consumeRemoteOpToken()) {
        remaining.add(op.copyWith(nextRetryAtMs: now + 15 * 1000));
        continue;
      }

      try {
        await _runRemoteOp(op);
        opsDone += 1;
      } catch (e) {
        final attempts = op.attempts + 1;
        final backoffSeconds = min(pow(2, attempts).toInt(), 300);
        remaining.add(
          op.copyWith(
            attempts: attempts,
            nextRetryAtMs: now + backoffSeconds * 1000,
            lastError: e.toString(),
          ),
        );
      }
    }

    await _saveQueue(remaining);
  }

  Future<void> _runRemoteOp(_QueuedOp op) async {
    final remote = _remote;
    if (remote == null) {
      throw StateError('Remote repository not configured');
    }
    switch (op.op) {
      case 'createItem':
        await remote.createItem(
          op.args['title'] as String,
          op.args['type'] as String,
          dataItemId: op.args['dataItemId'] as String?,
        );
        return;
      case 'updateItem':
        await remote.updateItem(
          op.args['dataItemId'] as String,
          op.args['title'] as String,
          op.args['description'] as String,
          op.args['photoUrl'] as String?,
        );
        return;
      case 'deleteItem':
        await remote.deleteItem(op.args['dataItemId'] as String);
        return;
      case 'toggleItem':
        await remote.toggleItem(op.args['dataItemId'] as String);
        return;
      case 'createUser':
        await remote.createUser(
          op.args['userId'] as int,
          op.args['email'] as String,
          op.args['password'] as String,
          op.args['displayName'] as String,
        );
        return;
      case 'updateUser':
        await remote.updateUser(
          op.args['userId'] as int,
          op.args['email'] as String,
          op.args['password'] as String,
          op.args['displayName'] as String,
        );
        return;
      case 'deleteUser':
        await remote.deleteUser(op.args['userId'] as int);
        return;
      default:
        throw UnsupportedError('Unknown queued op: ${op.op}');
    }
  }

  @override
  Future<void> createItem(
    String title,
    String type, {
    String? dataItemId,
  }) async {
    final resolvedId =
        dataItemId ?? DateTime.now().microsecondsSinceEpoch.toString();
    await _local.createItem(title, type, dataItemId: resolvedId);

    if (!_syncEnabled) return;
    try {
      if (!_consumeRemoteOpToken()) {
        throw StateError('Throttled');
      }
      await _remote!.createItem(title, type, dataItemId: resolvedId);
      await _flushQueue();
    } catch (e) {
      await _enqueue(
        _QueuedOp(
          op: 'createItem',
          args: {'title': title, 'type': type, 'dataItemId': resolvedId},
          createdAtMs: _nowMs(),
          attempts: 0,
          lastError: e.toString(),
        ),
      );
    }
  }

  @override
  Future<List<Item>> readItems() async {
    return _local.readItems();
  }

  @override
  Future<void> updateItem(
    String dataItemId,
    String title,
    String description,
    String? photoUrl,
  ) async {
    await _local.updateItem(dataItemId, title, description, photoUrl);
    if (!_syncEnabled) return;

    try {
      if (!_consumeRemoteOpToken()) throw StateError('Throttled');
      await _remote!.updateItem(dataItemId, title, description, photoUrl);
      await _flushQueue();
    } catch (e) {
      await _enqueue(
        _QueuedOp(
          op: 'updateItem',
          args: {
            'dataItemId': dataItemId,
            'title': title,
            'description': description,
            'photoUrl': photoUrl,
          },
          createdAtMs: _nowMs(),
          attempts: 0,
          lastError: e.toString(),
        ),
      );
    }
  }

  @override
  Future<void> deleteItem(String dataItemId) async {
    await _local.deleteItem(dataItemId);
    if (!_syncEnabled) return;

    try {
      if (!_consumeRemoteOpToken()) throw StateError('Throttled');
      await _remote!.deleteItem(dataItemId);
      await _flushQueue();
    } catch (e) {
      await _enqueue(
        _QueuedOp(
          op: 'deleteItem',
          args: {'dataItemId': dataItemId},
          createdAtMs: _nowMs(),
          attempts: 0,
          lastError: e.toString(),
        ),
      );
    }
  }

  @override
  Future<void> toggleItem(String dataItemId) async {
    await _local.toggleItem(dataItemId);
    if (!_syncEnabled) return;

    try {
      if (!_consumeRemoteOpToken()) throw StateError('Throttled');
      await _remote!.toggleItem(dataItemId);
      await _flushQueue();
    } catch (e) {
      await _enqueue(
        _QueuedOp(
          op: 'toggleItem',
          args: {'dataItemId': dataItemId},
          createdAtMs: _nowMs(),
          attempts: 0,
          lastError: e.toString(),
        ),
      );
    }
  }

  @override
  Future<void> createUser(
    int userId,
    String email,
    String password,
    String displayName,
  ) async {
    await _local.createUser(userId, email, password, displayName);
    if (!_syncEnabled) return;

    try {
      if (!_consumeRemoteOpToken()) throw StateError('Throttled');
      await _remote!.createUser(userId, email, password, displayName);
      await _flushQueue();
    } catch (e) {
      await _enqueue(
        _QueuedOp(
          op: 'createUser',
          args: {
            'userId': userId,
            'email': email,
            'password': password,
            'displayName': displayName,
          },
          createdAtMs: _nowMs(),
          attempts: 0,
          lastError: e.toString(),
        ),
      );
    }
  }

  @override
  Future<List<AppUser>> readAllUsers() async {
    return _local.readAllUsers();
  }

  @override
  Future<void> updateUser(
    int userId,
    String email,
    String password,
    String displayName,
  ) async {
    await _local.updateUser(userId, email, password, displayName);
    if (!_syncEnabled) return;

    try {
      if (!_consumeRemoteOpToken()) throw StateError('Throttled');
      await _remote!.updateUser(userId, email, password, displayName);
      await _flushQueue();
    } catch (e) {
      await _enqueue(
        _QueuedOp(
          op: 'updateUser',
          args: {
            'userId': userId,
            'email': email,
            'password': password,
            'displayName': displayName,
          },
          createdAtMs: _nowMs(),
          attempts: 0,
          lastError: e.toString(),
        ),
      );
    }
  }

  @override
  Future<void> deleteUser(int userId) async {
    await _local.deleteUser(userId);
    if (!_syncEnabled) return;

    try {
      if (!_consumeRemoteOpToken()) throw StateError('Throttled');
      await _remote!.deleteUser(userId);
      await _flushQueue();
    } catch (e) {
      await _enqueue(
        _QueuedOp(
          op: 'deleteUser',
          args: {'userId': userId},
          createdAtMs: _nowMs(),
          attempts: 0,
          lastError: e.toString(),
        ),
      );
    }
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    return _local.getCurrentUser();
  }

  @override
  Future<AppUser> signIn(String email, String password) async {
    if (!_syncEnabled) {
      return _local.signIn(email, password);
    }

    final remoteUser = await _remote!.signIn(email, password);
    final localUsers = await _local.readAllUsers();
    final exists = localUsers.any((u) => u.userId == remoteUser.userId);
    if (exists) {
      await _local.updateUser(
        remoteUser.userId,
        email,
        password,
        remoteUser.displayName,
      );
    } else {
      await _local.createUser(
        remoteUser.userId,
        email,
        password,
        remoteUser.displayName,
      );
    }
    final localUser = await _local.signIn(email, password);
    await _flushQueue();
    return localUser;
  }

  @override
  Future<AppUser> register(
    String email,
    String password,
    String displayName,
  ) async {
    if (!_syncEnabled) {
      return _local.register(email, password, displayName);
    }

    final remoteUser = await _remote!.register(email, password, displayName);
    final localUsers = await _local.readAllUsers();
    final exists = localUsers.any((u) => u.userId == remoteUser.userId);
    if (exists) {
      await _local.updateUser(
        remoteUser.userId,
        email,
        password,
        remoteUser.displayName,
      );
    } else {
      await _local.createUser(
        remoteUser.userId,
        email,
        password,
        remoteUser.displayName,
      );
    }
    final localUser = await _local.signIn(email, password);
    await _flushQueue();
    return localUser;
  }

  @override
  Future<void> signOut() async {
    await _local.signOut();
    if (!_syncEnabled) return;
    try {
      await _remote!.signOut();
    } finally {
      // no-op
    }
  }
}

class _QueuedOp {
  final String op;
  final Map<String, dynamic> args;
  final int createdAtMs;
  final int attempts;
  final int? nextRetryAtMs;
  final String? lastError;

  const _QueuedOp({
    required this.op,
    required this.args,
    required this.createdAtMs,
    required this.attempts,
    this.nextRetryAtMs,
    this.lastError,
  });

  _QueuedOp copyWith({int? attempts, int? nextRetryAtMs, String? lastError}) {
    return _QueuedOp(
      op: op,
      args: args,
      createdAtMs: createdAtMs,
      attempts: attempts ?? this.attempts,
      nextRetryAtMs: nextRetryAtMs ?? this.nextRetryAtMs,
      lastError: lastError ?? this.lastError,
    );
  }

  factory _QueuedOp.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.parse(value.toString());
    }

    return _QueuedOp(
      op: json['op'] as String,
      args: (json['args'] as Map).cast<String, dynamic>(),
      createdAtMs: asInt(json['createdAtMs']),
      attempts: asInt(json['attempts']),
      nextRetryAtMs: json['nextRetryAtMs'] == null
          ? null
          : asInt(json['nextRetryAtMs']),
      lastError: json['lastError'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'op': op,
      'args': args,
      'createdAtMs': createdAtMs,
      'attempts': attempts,
      'nextRetryAtMs': nextRetryAtMs,
      'lastError': lastError,
    };
  }
}
