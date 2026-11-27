import 'package:flutter/foundation.dart';

import '../data/api_client.dart';
import '../data/drafts_storage.dart';
import '../data/models.dart';

enum SendStatus { sending, sent, failed }

class OutgoingMessage {
  final String localId;
  final String text;
  final SendStatus status;
  final int? serverId;

  const OutgoingMessage({
    required this.localId,
    required this.text,
    required this.status,
    this.serverId,
  });

  OutgoingMessage copyWith({SendStatus? status, int? serverId}) =>
      OutgoingMessage(
        localId: localId,
        text: text,
        status: status ?? this.status,
        serverId: serverId ?? this.serverId,
      );
}

class ChatStore extends ChangeNotifier {
  static const _newestId = 9007199254740991;

  final ApiClient _api;
  final DraftsStorage _drafts;
  final String user;
  final String channel;

  final Map<int, Message> _messages = {};
  List<OutgoingMessage> _outgoing = [];
  bool _started = false;
  bool _ready = false;
  bool _loadedOnce = false;
  bool _loadingInitial = false;
  bool _loadingOlder = false;
  bool _refreshing = false;
  bool _hasMore = true;
  ApiException? _initialError;
  ApiException? _olderError;
  ApiException? _refreshError;
  String _draft = '';
  int _localCounter = 0;
  bool _disposed = false;

  double scrollOffset = 0;

  ChatStore({
    required this._api,
    required this._drafts,
    required this.user,
    required this.channel,
  });

  bool get ready => _ready;
  bool get loadedOnce => _loadedOnce;
  bool get loadingInitial => _loadingInitial;
  bool get loadingOlder => _loadingOlder;
  bool get refreshing => _refreshing;
  bool get hasMore => _hasMore;
  ApiException? get initialError => _initialError;
  ApiException? get olderError => _olderError;
  ApiException? get refreshError => _refreshError;
  String get draft => _draft;
  List<OutgoingMessage> get outgoing => List.unmodifiable(_outgoing);

  List<Message> get messages =>
      _messages.values.toList()..sort((a, b) => b.id.compareTo(a.id));

  Future<void> start() async {
    if (_started) return;
    _started = true;
    final draft = await _drafts.readDraft(user, channel);
    final pending = await _drafts.readPending(user, channel);
    if (_disposed) return;
    _draft = draft;
    _outgoing = [
      for (final item in pending)
        OutgoingMessage(
          localId: item.localId,
          text: item.text,
          status: SendStatus.failed,
        ),
    ];
    _ready = true;
    _notify();
    await loadInitial();
  }

  Future<void> loadInitial() async {
    if (_loadingInitial) return;
    _loadingInitial = true;
    _initialError = null;
    _notify();
    try {
      final page = await _api.messages(
        channel,
        lastKnownId: _newestId,
        reverse: true,
      );
      if (_disposed) return;
      _addPage(page);
      _hasMore = page.length >= ApiClient.pageSize;
      _loadedOnce = true;
    } on ApiException catch (error) {
      if (_disposed) return;
      _initialError = error;
    }
    _loadingInitial = false;
    _notify();
  }

  Future<void> loadOlder() async {
    if (_loadingOlder || _loadingInitial || !_hasMore || _messages.isEmpty) {
      return;
    }
    _loadingOlder = true;
    _olderError = null;
    _notify();
    try {
      final oldest = _messages.keys.reduce((a, b) => a < b ? a : b);
      final page = await _api.messages(
        channel,
        lastKnownId: oldest,
        reverse: true,
      );
      if (_disposed) return;
      _addPage(page);
      _hasMore = page.length >= ApiClient.pageSize;
    } on ApiException catch (error) {
      if (_disposed) return;
      _olderError = error;
    }
    _loadingOlder = false;
    _notify();
  }

  Future<void> refresh() async {
    if (_messages.isEmpty) {
      await loadInitial();
      return;
    }
    if (_refreshing) return;
    _refreshing = true;
    _refreshError = null;
    _notify();
    try {
      for (var i = 0; i < 5; i++) {
        final newest = _messages.keys.reduce((a, b) => a > b ? a : b);
        final page = await _api.messages(
          channel,
          lastKnownId: newest,
          reverse: false,
        );
        if (_disposed) return;
        _addPage(page);
        if (page.length < ApiClient.pageSize) break;
      }
    } on ApiException catch (error) {
      if (_disposed) return;
      _refreshError = error;
    }
    _refreshing = false;
    _notify();
  }

  void dismissRefreshError() {
    _refreshError = null;
    _notify();
  }

  void updateDraft(String text) {
    if (text == _draft) return;
    _draft = text;
    _drafts.saveDraft(user, channel, text);
  }

  Future<void> send(String text) async {
    if (text.trim().isEmpty) return;
    final item = OutgoingMessage(
      localId: '${DateTime.now().microsecondsSinceEpoch}-${_localCounter++}',
      text: text,
      status: SendStatus.sending,
    );
    _outgoing = [..._outgoing, item];
    _notify();
    await _savePending();
    await _deliver(item.localId);
  }

  Future<void> retry(String localId) async {
    final item = _find(localId);
    if (item == null || item.status != SendStatus.failed) return;
    _replace(item.copyWith(status: SendStatus.sending));
    _notify();
    await _deliver(localId);
  }

  String? takeBack(String localId) {
    final item = _find(localId);
    if (item == null || item.status == SendStatus.sending) return null;
    _outgoing = [
      for (final other in _outgoing)
        if (other.localId != localId) other,
    ];
    _notify();
    _savePending();
    return item.text;
  }

  Future<void> _deliver(String localId) async {
    final item = _find(localId);
    if (item == null) return;
    try {
      final id = await _api.sendText(
        from: user,
        channel: channel,
        text: item.text,
      );
      if (_disposed) return;
      _replace(item.copyWith(status: SendStatus.sent, serverId: id));
      _dropDelivered();
      _notify();
      await _savePending();
      await refresh();
    } on ApiException {
      if (_disposed) return;
      _replace(item.copyWith(status: SendStatus.failed));
      _notify();
      await _savePending();
    }
  }

  void _addPage(List<Message> page) {
    for (final message in page) {
      if (message.to == channel || message.to.isEmpty) {
        _messages[message.id] = message;
      }
    }
    _dropDelivered();
  }

  void _dropDelivered() {
    _outgoing = [
      for (final item in _outgoing)
        if (item.status != SendStatus.sent ||
            !_messages.containsKey(item.serverId))
          item,
    ];
  }

  OutgoingMessage? _find(String localId) {
    for (final item in _outgoing) {
      if (item.localId == localId) return item;
    }
    return null;
  }

  void _replace(OutgoingMessage updated) {
    _outgoing = [
      for (final item in _outgoing)
        if (item.localId == updated.localId) updated else item,
    ];
  }

  Future<void> _savePending() => _drafts.savePending(user, channel, [
    for (final item in _outgoing)
      if (item.status != SendStatus.sent)
        PendingText(localId: item.localId, text: item.text),
  ]);

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
