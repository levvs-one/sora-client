import 'dart:convert';

class AppNotification {
  const AppNotification({
    required this.time,
    required this.title,
    required this.body,
    this.action = '',
    this.argument = '',
    this.read = false,
  });

  final DateTime time;
  final String title;
  final String body;
  final String action;
  final String argument;
  final bool read;

  AppNotification markRead() =>
      AppNotification(time: time, title: title, body: body, action: action, argument: argument, read: true);

  String get stored => jsonEncode({
    'time': time.toIso8601String(),
    'title': title,
    'body': body,
    'action': action,
    'argument': argument,
    'read': read,
  });

  static AppNotification? parse(String value) {
    try {
      final json = jsonDecode(value) as Map<String, dynamic>;
      return AppNotification(
        time: DateTime.parse(json['time'] as String),
        title: json['title'] as String,
        body: json['body'] as String,
        action: json['action'] as String? ?? '',
        argument: json['argument'] as String? ?? '',
        read: json['read'] as bool? ?? false,
      );
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }
}
