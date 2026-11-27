import 'package:flutter/foundation.dart';

import '../data/api_client.dart';
import '../data/drafts_storage.dart';
import '../data/models.dart';
import 'chat_store.dart';

class HomeStore extends ChangeNotifier {
  final ApiClient _api;
  final DraftsStorage _drafts;
  final Session session;

  List<String> _channels = [];
  bool _loading = false;
  bool _loadedOnce = false;
  ApiException? _error;
  String? _selected;
  String? _openImage;
  final Map<String, ChatStore> _chats = {};
  bool _disposed = false;

  HomeStore({required this._api, required this._drafts, required this.session});

  List<String> get channels => List.unmodifiable(_channels);
  bool get loading => _loading;
  bool get loadedOnce => _loadedOnce;
  ApiException? get error => _error;
  String? get selected => _selected;
  String? get openImage => _openImage;

  String thumbUrl(String link) => _api.thumbUrl(link);
  String imageUrl(String link) => _api.imageUrl(link);

  Future<void> loadChannels({bool force = false}) async {
    if (_loading || (_loadedOnce && !force)) return;
    _loading = true;
    _error = null;
    _notify();
    try {
      final result = await _api.channels();
      if (_disposed) return;
      _channels = result;
      _loadedOnce = true;
    } on ApiException catch (error) {
      if (_disposed) return;
      _error = error;
    }
    _loading = false;
    _notify();
  }

  ChatStore chatFor(String channel) => _chats.putIfAbsent(
    channel,
    () => ChatStore(
      api: _api,
      drafts: _drafts,
      user: session.name,
      channel: channel,
    ),
  );

  void select(String channel) {
    _selected = channel;
    _notify();
  }

  void closeChat() {
    _selected = null;
    _notify();
  }

  void showImage(String link) {
    _openImage = link;
    _notify();
  }

  void closeImage() {
    _openImage = null;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    for (final chat in _chats.values) {
      chat.dispose();
    }
    super.dispose();
  }
}
