import 'package:flutter/foundation.dart';

import '../data/api_client.dart';
import '../data/drafts_storage.dart';
import '../data/models.dart';
import '../data/session_storage.dart';

enum LoginError { wrongCredentials, network, server }

class SessionStore extends ChangeNotifier {
  final ApiClient _api;
  final SessionStorage _storage;
  final DraftsStorage _drafts;

  Session? _session;
  bool _restoring = true;
  bool _loggingIn = false;
  LoginError? _loginError;
  bool _expired = false;

  SessionStore(this._api, this._storage, this._drafts) {
    _api.onUnauthorized = expire;
  }

  Session? get session => _session;
  bool get restoring => _restoring;
  bool get loggingIn => _loggingIn;
  LoginError? get loginError => _loginError;
  bool get expired => _expired;

  Future<void> restore() async {
    try {
      final saved = await _storage.read();
      if (saved != null) {
        _api.token = saved.token;
        _session = saved;
      }
    } catch (_) {
      _session = null;
    }
    _restoring = false;
    notifyListeners();
  }

  Future<void> login(String name, String password) async {
    if (_loggingIn) return;
    _loggingIn = true;
    _loginError = null;
    _expired = false;
    notifyListeners();
    try {
      final token = await _api.login(name.trim(), password);
      final session = Session(name: name.trim(), token: token);
      _api.token = token;
      await _storage.save(session);
      _session = session;
    } on ApiException catch (error) {
      _loginError = switch (error) {
        UnauthorizedException() ||
        RequestException() => LoginError.wrongCredentials,
        NetworkException() => LoginError.network,
        ServerException() => LoginError.server,
      };
    } finally {
      _loggingIn = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    final current = _session;
    if (current == null) return;
    _session = null;
    _expired = false;
    _api.token = null;
    notifyListeners();
    await _storage.clear();
    await _drafts.clearUser(current.name);
    try {
      await _api.logout(current.token);
    } on ApiException {
      return;
    }
  }

  void expire() {
    if (_session == null) return;
    _session = null;
    _api.token = null;
    _expired = true;
    _storage.clear();
    notifyListeners();
  }
}
