import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Minimal MethodChannel mock for `flutter_secure_storage`.
///
/// This lets unit tests run on the host platform without needing
/// the real iOS/Android implementations.
class SecureStorageMock {
  static const MethodChannel _channel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );

  final Map<String, String> _storage = <String, String>{};

  void install() {
    TestWidgetsFlutterBinding.ensureInitialized();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (MethodCall call) async {
          final args = (call.arguments is Map)
              ? (call.arguments as Map).cast<dynamic, dynamic>()
              : const <dynamic, dynamic>{};

          String? argKey() => args['key']?.toString();

          switch (call.method) {
            case 'write':
              final key = argKey();
              final value = args['value']?.toString();
              if (key != null && value != null) {
                _storage[key] = value;
              }
              return null;
            case 'read':
              final key = argKey();
              if (key == null) return null;
              return _storage[key];
            case 'delete':
              final key = argKey();
              if (key != null) {
                _storage.remove(key);
              }
              return null;
            case 'deleteAll':
              _storage.clear();
              return null;
            case 'readAll':
              return Map<String, String>.from(_storage);
            case 'containsKey':
              final key = argKey();
              if (key == null) return false;
              return _storage.containsKey(key);
            default:
              // Unknown method used by a newer plugin version.
              return null;
          }
        });
  }

  void uninstall() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  }

  String? readRaw(String key) => _storage[key];
}
