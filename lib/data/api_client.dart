import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'models.dart';

sealed class ApiException implements Exception {
  const ApiException();
}

final class NetworkException extends ApiException {
  const NetworkException();
}

final class UnauthorizedException extends ApiException {
  const UnauthorizedException();
}

final class ServerException extends ApiException {
  const ServerException();
}

final class RequestException extends ApiException {
  final int statusCode;
  const RequestException(this.statusCode);
}

class ApiClient {
  static const baseUrl = 'https://faerytea.name';
  static const pageSize = 20;
  static const _timeout = Duration(seconds: 15);

  final http.Client _client;
  String? token;
  void Function()? onUnauthorized;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  String thumbUrl(String link) => '$baseUrl/thumb/$link';

  String imageUrl(String link) => '$baseUrl/img/$link';

  Future<String> login(String name, String password) async {
    final response = await _send(
      () => _client.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'pwd': password}),
      ),
      authorized: false,
    );
    final value = response.body.trim();
    if (value.isEmpty) throw const ServerException();
    return value;
  }

  Future<void> logout(String sessionToken) async {
    await _send(
      () => _client.post(
        Uri.parse('$baseUrl/logout'),
        headers: {'X-Auth-Token': sessionToken},
      ),
      authorized: false,
    );
  }

  Future<List<String>> channels() async {
    final response = await _send(
      () => _client.get(Uri.parse('$baseUrl/channels')),
      authorized: false,
    );
    final decoded = _decode(response);
    if (decoded is! List) throw const ServerException();
    return decoded.whereType<String>().toList();
  }

  Future<List<Message>> messages(
    String channel, {
    required int lastKnownId,
    required bool reverse,
  }) async {
    final uri = Uri.parse('$baseUrl/channel/${Uri.encodeComponent(channel)}')
        .replace(
          queryParameters: {
            'limit': '$pageSize',
            'lastKnownId': '$lastKnownId',
            'reverse': '$reverse',
          },
        );
    final response = await _send(() => _client.get(uri), authorized: false);
    try {
      return Message.listFromJson(_decode(response));
    } on FormatException {
      throw const ServerException();
    }
  }

  Future<int> sendText({
    required String from,
    required String channel,
    required String text,
  }) async {
    final currentToken = token;
    if (currentToken == null) throw const UnauthorizedException();
    final response = await _send(
      () => _client.post(
        Uri.parse('$baseUrl/messages'),
        headers: {
          'Content-Type': 'application/json',
          'X-Auth-Token': currentToken,
        },
        body: jsonEncode({
          'from': from,
          'to': channel,
          'data': {
            'Text': {'text': text},
          },
        }),
      ),
      authorized: true,
    );
    final id = int.tryParse(response.body.trim());
    if (id == null) throw const ServerException();
    return id;
  }

  Object? _decode(http.Response response) {
    try {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      throw const ServerException();
    }
  }

  Future<http.Response> _send(
    Future<http.Response> Function() request, {
    required bool authorized,
  }) async {
    final http.Response response;
    try {
      response = await request().timeout(_timeout);
    } on SocketException {
      throw const NetworkException();
    } on TimeoutException {
      throw const NetworkException();
    } on http.ClientException {
      throw const NetworkException();
    }
    final code = response.statusCode;
    if (code == 401 || code == 403) {
      if (authorized) onUnauthorized?.call();
      throw const UnauthorizedException();
    }
    if (code >= 500) throw const ServerException();
    if (code >= 400) throw RequestException(code);
    return response;
  }
}
