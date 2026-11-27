sealed class MessageContent {
  const MessageContent();
}

final class TextContent extends MessageContent {
  final String text;
  const TextContent(this.text);
}

final class ImageContent extends MessageContent {
  final String link;
  const ImageContent(this.link);
}

class Message {
  final int id;
  final String from;
  final String to;
  final MessageContent content;
  final DateTime time;

  const Message({
    required this.id,
    required this.from,
    required this.to,
    required this.content,
    required this.time,
  });

  factory Message.fromJson(Object? json) {
    if (json case {
      'id': int id,
      'from': String from,
      'data': Map<String, Object?> data,
    }) {
      final to = json['to'];
      final time = json['time'];
      return Message(
        id: id,
        from: from,
        to: to is String ? to : '',
        content: _parseContent(data),
        time: DateTime.fromMillisecondsSinceEpoch(time is int ? time : 0),
      );
    }
    throw const FormatException('Invalid message');
  }

  static MessageContent _parseContent(Map<String, Object?> data) {
    if (data case {'Text': {'text': String text}}) {
      return TextContent(text);
    }
    if (data case {'Image': {'link': String link}}) {
      return ImageContent(link);
    }
    throw const FormatException('Unknown message data');
  }

  static List<Message> listFromJson(Object? json) {
    if (json is! List) throw const FormatException('Expected list');
    final result = <Message>[];
    for (final item in json) {
      try {
        result.add(Message.fromJson(item));
      } on FormatException {
        continue;
      }
    }
    return result;
  }
}

class Session {
  final String name;
  final String token;
  const Session({required this.name, required this.token});
}
