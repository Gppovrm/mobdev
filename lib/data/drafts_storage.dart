import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class PendingText {
  final String localId;
  final String text;

  const PendingText({required this.localId, required this.text});

  Map<String, String> toJson() => {'localId': localId, 'text': text};

  static PendingText? fromJson(Object? json) {
    if (json case {'localId': String localId, 'text': String text}) {
      return PendingText(localId: localId, text: text);
    }
    return null;
  }
}

abstract interface class DraftsStorage {
  Future<String> readDraft(String user, String channel);
  Future<void> saveDraft(String user, String channel, String text);
  Future<List<PendingText>> readPending(String user, String channel);
  Future<void> savePending(
    String user,
    String channel,
    List<PendingText> items,
  );
  Future<void> clearUser(String user);
}

class PrefsDraftsStorage implements DraftsStorage {
  final SharedPreferencesAsync _prefs;

  PrefsDraftsStorage([SharedPreferencesAsync? prefs])
    : _prefs = prefs ?? SharedPreferencesAsync();

  String _draftKey(String user, String channel) => 'draft|$user|$channel';

  String _pendingKey(String user, String channel) => 'pending|$user|$channel';

  @override
  Future<String> readDraft(String user, String channel) async =>
      await _prefs.getString(_draftKey(user, channel)) ?? '';

  @override
  Future<void> saveDraft(String user, String channel, String text) async {
    final key = _draftKey(user, channel);
    if (text.isEmpty) {
      await _prefs.remove(key);
    } else {
      await _prefs.setString(key, text);
    }
  }

  @override
  Future<List<PendingText>> readPending(String user, String channel) async {
    final raw = await _prefs.getString(_pendingKey(user, channel));
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .map(PendingText.fromJson)
          .whereType<PendingText>()
          .toList();
    } on FormatException {
      return [];
    }
  }

  @override
  Future<void> savePending(
    String user,
    String channel,
    List<PendingText> items,
  ) async {
    final key = _pendingKey(user, channel);
    if (items.isEmpty) {
      await _prefs.remove(key);
    } else {
      await _prefs.setString(
        key,
        jsonEncode([for (final item in items) item.toJson()]),
      );
    }
  }

  @override
  Future<void> clearUser(String user) async {
    final keys = await _prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith('draft|$user|') || key.startsWith('pending|$user|')) {
        await _prefs.remove(key);
      }
    }
  }
}
