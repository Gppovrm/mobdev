import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'models.dart';

abstract interface class SessionStorage {
  Future<Session?> read();
  Future<void> save(Session session);
  Future<void> clear();
}

class SecureSessionStorage implements SessionStorage {
  static const _nameKey = 'session_name';
  static const _tokenKey = 'session_token';

  final FlutterSecureStorage _storage;

  const SecureSessionStorage([this._storage = const FlutterSecureStorage()]);

  @override
  Future<Session?> read() async {
    final name = await _storage.read(key: _nameKey);
    final token = await _storage.read(key: _tokenKey);
    if (name == null || token == null) return null;
    return Session(name: name, token: token);
  }

  @override
  Future<void> save(Session session) async {
    await _storage.write(key: _nameKey, value: session.name);
    await _storage.write(key: _tokenKey, value: session.token);
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: _nameKey);
    await _storage.delete(key: _tokenKey);
  }
}
